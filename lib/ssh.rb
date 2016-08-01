class CloudProxyGenerator
  module Ssh

    def create_ssh_tunnels
      wait_for_active_droplets
      
      puts "Starting SSH tunnels..."
      droplet_records.values.each do |ldr|
        puts "  - #{ldr.name}"
        ssh_opts =  "-l root "
        # Suppress "Are you sure you want to connect? (yes/no)"
        ssh_opts << "-o 'StrictHostKeyChecking no' "
        # -D bind address as SOCKS instead of specific port
        ssh_opts << "-D #{ldr.local_port} #{ldr.ip_address} "
        system("ssh #{ssh_opts} -f -N")
      end
      puts "Done tunneling!"
    end

    def kill_ssh_tunnels
      puts "Killing ssh tunnels..."
      `ps auxw|grep ssh|grep StrictHost|awk '{print $2}'|xargs kill -9`
    end

  end
end