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
  include CloudProxyGenerator::Droplet
  include CloudProxyGenerator::Ssh
  include CloudProxyGenerator::Util

  attr_accessor :config, :d_client, :db

  STARTING_PROXY_PORT = 31337
  CONFIG_FILE = 'config.yml'
  DB_FILE = 'database.yml'

  def initialize
    load_config
    @d_client = DropletKit::Client.new(
      access_token: @c_do['access_token']
    )
    load_or_init_database
    @num_proxies = @config['num_proxies']
  end

  def run_until_killed
    puts "Running until killed (CTRL-C to quit)"
    create_proxies
    sleep
  rescue SystemExit, Interrupt
    puts "Exiting, please wait for cleanup..."
    kill_proxies    
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
    puts "\nPROXY ADDRESSES"
    droplet_records.each do |id, ldr|
      puts "  - socks://localhost:#{ldr.local_port}"
    end
    puts "\n"
  end

end

# For quick irb reference
CPG = CloudProxyGenerator.instance