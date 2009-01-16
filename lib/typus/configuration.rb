module Typus

  module Configuration

    module Reloader

      ##
      # Reload configuration files and roles when application is 
      # running on development.
      #
      def reload_config_et_roles
        return unless Rails.env.development?
        logger.info "[typus] Configuration files have been reloaded."
        Typus::Configuration.roles!
        Typus::Configuration.config!
      end

    end

    ##
    # Default application options that can be overwritten from
    # an initializer.
    #
    # Example:
    #
    #   Typus::Configuration.options[:app_name] = "Your App Name"
    #
    @@options = { :app_name => 'Typus', 
                  :per_page => 15, 
                  :form_rows => 10, 
                  :sidebar_selector => 10, 
                  :minute_step => 5, 
                  :toggle => true, 
                  :edit_after_create => true, 
                  :root => 'admin', 
                  :recover_password => true, 
                  :email => 'admin@example.com', 
                  :ssl => false, 
                  :prefix => 'admin', 
                  :icon_on_boolean => true, 
                  :nil => 'nil', 
                  :user_class_name => 'TypusUser', 
                  :user_fk => 'typus_user_id' }

    mattr_accessor :options

    ##
    # Read Typus Configuration file
    #
    #   Typus::Configuration.config! overwrites @@config
    #
    def self.config!

      files = if Rails.env.test?
                ["vendor/plugins/typus/test/config/typus.yml"]
              else
                Dir["config/typus/*"] - Dir["config/typus/*"].grep(/roles.yml/)
              end

      @@config = {}
      files.each do |file|
        data = YAML.load_file("#{Rails.root}/#{file}")
        @@config = @@config.merge(data) if data
      end

      return @@config

    end

    mattr_accessor :config

    ##
    # Read Typus Roles
    #
    #   Typus::Configuration.roles! overwrites @@roles
    #
    def self.roles!

      files = if Rails.env.test?
                ["vendor/plugins/typus/test/config/typus_roles.yml"]
              else
                Dir["config/typus/*_roles.yml"]
              end

      @@roles = { options[:root] => {} }

      files.each do |file|
        data = YAML.load_file("#{Rails.root}/#{file}")
        next unless data
        data.each do |key, value|
          begin
            @@roles[key] = @@roles[key].merge(value)
          rescue
            @@roles[key] = value
          end
        end
      end

      return @@roles.compact

    end

    mattr_accessor :roles

  end

end