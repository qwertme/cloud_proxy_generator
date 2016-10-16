# Cloud Proxy Generator

Cloud Proxy Generator is a Ruby script that generates private SOCKS 5 proxies backed by [Digital Ocean VPS servers](https://m.do.co/c/4fba00a6f1fe). Proxies are spread out across all of their available regions, giving you access to multiple IP addresses — worldwide — that can change as you spin proxies up and down. You can spin up 1-N proxies, only limited by the amount of droplets Digital Ocean will let you create.

Something like this comes in handy when you need to…

- Start a cheap VPN without signing up for yet another online service
- Avoid getting blacklisted from online sites
- Get around rate limits or timeouts of online services
- Mask your real IP address for accessing online services (like watching the Warriors game on NBA League Pass if you live in the Bay Area)
- Quickly crawl the content of a web site or sites without revealing your true IP
- Etc…

I wrote it to help me [avoid timeout errors validating a list of 400k email addresses](https://github.com/subimage/email_list_cleaner), but I'm sure you're already imagining the types of things you could do with such a tool.

## Requirements

- Ruby 2.3.x
- A [Digital Ocean account](https://m.do.co/c/4fba00a6f1fe)
  - (Please use my referral link above so I get credit if you open a new account!)

## How It Works

- Creates N proxy servers using the cheapest Digital Ocean droplet (512mb)
- SSH tunnels into each proxy server
- Prints out list of SOCKS proxies
- Removes droplets on Digital ocean when script is killed

## How To Install

1. `git clone` to your computer
2. `bundle install`

## How To Use

1. Copy config-example.yml to config.yml, read the comments & edit appropriately
2. Run script/run\_until\_killed.rb
3. Press Ctrl-C when you're done
