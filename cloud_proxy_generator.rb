#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "yaml"
require "singleton"
Bundler.require(:default)

Dir.glob("lib/**/*.rb") {|f| require_relative f}

# Generates number of SOCKS proxies by spinning up
# cloud servers and enabling SSH tunnels on localhost.
class CloudProxyGenerator
  include Singleton

  def initialize
  end

  def run
  end
end