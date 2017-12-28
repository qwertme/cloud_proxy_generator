class CloudProxyGenerator
  # Methods that interact with DigitalOcean droplets and our local records.
  module Droplet

    # Local Hash keyed by DigitalOcean remote_id of LocalDropletRecords
    def droplet_records
      @db['droplets']
    end

    def create_droplets
      puts "\nCREATING DROPLETS ON DIGITAL OCEAN"
      (1..@num_proxies).each do |i|
        d_name = "proxy-#{i}"
        d = DropletKit::Droplet.new(
          name:     d_name,
          region:   @c_do['regions'].sample,
          image:    @c_do['image_name'],
          size:     @c_do['size'],
          # Imperative that your local machine pub.key is already
          # uploaded if you'd like this to work...
          ssh_keys: @d_client.ssh_keys.all.collect { |k| k.fingerprint }
        )
        retries = 10
        begin
          puts "  - #{d_name}"
          created = @d_client.droplets.create(d)
          add_droplet_record(created)
        rescue DropletKit::Error => e
          puts e.message
          puts "...sleeping!"
          sleep 5
          if (retries -= 1) > 0
            retry
          end
        end
      end
      return droplet_records
    end

    # Droplet creation isn't instant.
    # Pause until we have all IPs for droplets
    def wait_for_ip_addresses
      puts "Waiting for IP addresses to be assigned..."
      until all_droplets_have_ips?
        sleep 5
        fill_droplet_ips
        i=0
        droplet_records.values.each {|ldr| i+=1 if ldr.ip_address}
        puts "Have #{i}/#{droplet_records.size} IPs..."
      end
    end

    def wait_for_active_droplets
      puts "Waiting for all droplets to turn on..."
      counter = 0
      sleep_time = 5
      until all_droplets_active?
        sleep(sleep_time)
        puts "  - Checking again...#{sleep_time * (counter+=1)}s elapsed"
      end
      puts "Looks like they're all active. Waiting 10s more to be sure!"
      sleep 10
    end

    def kill_droplets
      puts "\nDELETING DROPLETS ON DIGITAL OCEAN"
      droplet_records.each do |remote_id, ldr|
        # wait & retry 25 seconds?
        retries = 5
        begin
          puts "  - #{ldr.name} (remote id: #{remote_id})"
          @d_client.droplets.delete(id: remote_id)
          remove_droplet_record(remote_id)
        rescue DropletKit::Error => e
          puts e.message
          puts "...sleeping!"
          sleep 5
          if (retries -= 1) > 0
            retry
          else
            remove_droplet_record(remote_id)
          end
        end
      end
    end

    ###########################################################################
    private

    def verify_all_droplets_exist_remotely_or_remove
      return unless droplet_records.size > 0
      puts "Verifying all droplets exist..."
      droplet_records.keys.each do |remote_id|
        find_remote_droplet(remote_id)
      end
      puts "You currently have #{droplet_records.size} proxy servers alive."
    end

    # d is a DropletKit::Droplet
    def add_droplet_record(d)
      droplet_records[d.id] = LocalDropletRecord.new(
        remote_id: d.id,
        name: d.name,
        local_port: STARTING_PROXY_PORT + (droplet_records.size)
      )
      persist_database
    end

    def remove_droplet_record(remote_id)
      droplet_records.delete(remote_id) # internal 'db' hash
      persist_database
    end

    def find_remote_droplet(remote_id)
      return @d_client.droplets.find(id: remote_id)
    rescue DropletKit::Error => e
      # don't want to keep trying operations on droplet that don't exist
      remove_droplet_record(remote_id)
      puts e.message
      return nil
    end

    def fill_droplet_ips
      droplet_records.each do |remote_id, ldr|
        ocean_drop = find_remote_droplet(remote_id)
        if ocean_drop && net = ocean_drop.networks.v4.first
          droplet_records[remote_id].ip_address = net.ip_address
        end
      end
      persist_database
    end

    def all_droplets_have_ips?
      droplet_records.values.each do |ldr|
        return false if ldr.ip_address.nil?
      end
      return true
    end

    # Are all the droplets we have "active" - meaning turned on?
    # Ready for SSH?
    def all_droplets_active?
      droplet_records.values.each do |ldr|
        drop = find_remote_droplet(ldr.remote_id)
        return false unless drop && drop.status == 'active'
      end
      return true
    end

  end
end
