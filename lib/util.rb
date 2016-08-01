class CloudProxyGenerator
  module Util
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

    ###########################################################################
    private

    def load_config
      @config = YAML::load_file(CONFIG_FILE)
      @c_do = @config['digital_ocean']
    end

    # Tries to load persisted objects from DB_FILE, 
    # otherwise initialize objects we need.
    def load_or_init_database
      @db = YAML::load_file(DB_FILE) if File.exist?(DB_FILE)
      verify_all_droplets_exist_remotely_or_remove
      @db ||= {}
      @db['droplets'] ||= []
    end

    def persist_database
      File.open(DB_FILE, 'w') { |f| f.write(YAML.dump(@db)) }
    end

    def namify(str)
      str.strip.downcase.gsub(/[^a-z0-9]/i, "-")
    end

  end
end