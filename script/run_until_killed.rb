#!/usr/bin/env ruby
require_relative '../cloud_proxy_generator'

def run_until_killed
  CPG.create_proxies
rescue SystemExit, Interrupt
  # Ctrl-c support
  puts "QUITTING!"
ensure
  CPG.kill_proxies
end

run_until_killed