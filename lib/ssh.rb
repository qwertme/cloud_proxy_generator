class CloudProxyGenerator
  module Ssh

    def create_ssh_tunnels
      @ssh_pids = []
      puts "Starting SSH tunnels..."
      droplet_records.values.each do |ldr|
        puts "  - #{ldr.name}"
        
        ssh_opts =  "-l root "
        # Suppress "Are you sure you want to connect? (yes/no)"
        ssh_opts << "-o 'StrictHostKeyChecking no' "
        # -D bind address as SOCKS instead of specific port
        ssh_opts << "-D #{ldr.local_port} #{ldr.ip_address} "
        system("ssh #{ssh_opts} -f -N")
        @ssh_pids << $?.pid
      end
      puts "Done tunneling!"
      puts @ssh_pids.inspect
    end

    def kill_ssh_tunnels
      @ssh_pids ||= []
      puts "Killing ssh tunnels..."
      @ssh_pids.each do |p|
        system("kill -9 #{p}")
      end
    end

  end
end