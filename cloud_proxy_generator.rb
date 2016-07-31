#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "yaml"
require "singleton"
Bundler.require(:default)

Dir.glob("lib/**/*.rb") {|f| require_relative f}

# Generates number of SOCKS proxies by spinning up
# Digital Ocean cloud servers and enabling SSH tunnels on localhost.
class CloudProxyGenerator
  include Singleton

  attr_accessor :config, :d_client, :db

  STARTING_PROXY_PORT = 31337
  CONFIG_FILE = 'config.yml'
  DB_FILE = 'database.yml'

  def initialize
    load_config
    load_or_init_database
    @d_client = DropletKit::Client.new(
      access_token: @c_do['access_token']
    )
    @num_proxies = @config['num_proxies']
  end

  def create_proxies
    create_droplets
    wait_for_ip_addresses
    create_ssh_tunnels
    print_proxy_addresses
    persist_database
  end

  def kill_proxies
    kill_ssh_tunnels
    kill_droplets
  end

  def print_proxy_addresses
  end

  # DROPLETS ------------------------------------------------------------------
  def create_droplets
    puts "CREATING DROPLETS"
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
      puts "  - #{d_name}"
      created = @d_client.droplets.create(d)
      add_droplet_to_db(created)
    end
    return droplets
  end

  # Because creation can be slow we have to wait until 
  # they're created to grab the IPs.
  def wait_for_ip_addresses
  end

  def kill_droplets
    puts "DELETING DROPLETS"
    droplets.each do |id, attrs|
      begin
        puts "  - #{id} #{attrs['name']}"
        @d_client.droplets.delete(id: id)
      rescue DropletKit::Error => e
        puts e.message
        puts "...sleeping!"
        sleep 5
        retry
      end
    end
  end

  # SSH TUNNELS ---------------------------------------------------------------
  def create_ssh_tunnels
    droplets.each do |d|
      
    end
  end

  def kill_ssh_tunnels
  end

  # Shortcut so we can query up to date distribution clients.
  # without using CURL examples from the API reference.
  def print_distros
    d_client.images.all(type:'distribution').each do |i| 
      # Not sure of the naming method they're using
      # Looks to be this from the API docs...
      possible_image_name = "#{namify(i.distribution)}-#{namify(i.name)}"

      puts "= #{i.distribution} - #{i.name}"
      puts "  #{possible_image_name}"
    end
    return nil
  end

  private

  def namify(str)
    str.strip.downcase.gsub(/[^a-z0-9]/i, "-")
  end

  def load_config
    @config = YAML::load_file(CONFIG_FILE)
    @c_do = @config['digital_ocean']
  end

  # Tries to load persisted objects from DB_FILE, 
  # otherwise initialize objects we need.
  def load_or_init_database
    @db = YAML::load_file(DB_FILE) if File.exist?(DB_FILE)

    @db ||= {}
    @db['droplets'] ||= {}
  end

  def persist_database
    File.open(DB_FILE, 'w') { |f| f.write(YAML.dump(@db)) }
  end

  # d is a DropletKit::Droplet
  def add_droplet_to_db(d)
    droplets[d.id] = {
      'name' => d.name,
      #'ip_address' => d.networks,
      'local_port' => STARTING_PROXY_PORT + (droplets.size+1)
    }
    persist_database
  end

  def droplets
    @db['droplets']
  end

end

# For quick irb reference
CPG = CloudProxyGenerator.instance