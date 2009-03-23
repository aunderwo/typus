module Typus

  module Configuration

    module Reloader

      ##
      # Reload config and roles when app is running in development.
      #
      def reload_config_et_roles
        return unless Rails.env.development?
        logger.info "=> [typus] Configuration files have been reloaded."
        Typus::Configuration.roles!
        Typus::Configuration.config!
      end

    end

    ##
    # Default typus options that can be overwritten from an initializer.
    #
    typus_options = { :app_name => 'Typus', 
                      :config_folder => 'config/typus', 
                      :email => 'admin@example.com', 
                      :ignore_missing_translations => true, 
                      :locales => [ [ "English", :en ] ], 
                      :path_prefix => 'admin', 
                      :recover_password => false, 
                      :root => 'admin', 
                      :ssl => false, 
                      :templates_folder => 'admin/templates',
                      :user_class_name => 'TypusUser', 
                      :user_fk => 'typus_user_id' }

    ##
    # Default model options that can be overwritten from an initializer.
    #
    model_options = { :edit_after_create => true, 
                      :end_year => nil,
                      :form_rows => 10, 
                      :icon_on_boolean => true, 
                      :minute_step => 5, 
                      :nil => 'nil', 
                      :per_page => 15, 
                      :sidebar_selector => 10, 
                      :start_year => nil, 
                      :toggle => true }

    @@options = typus_options.merge(model_options)

    mattr_accessor :options

    ##
    # Read Typus Configuration file
    #
    #   Typus::Configuration.config! overwrites @@config
    #
    def self.config!

      files = Dir["#{Rails.root}/#{options[:config_folder]}/*.yml"].sort
      files = files.delete_if { |x| x.include?('_roles.yml') }

      @@config = {}
      files.each do |file|
        data = YAML.load_file(file)
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

      files = Dir["#{Rails.root}/#{options[:config_folder]}/*_roles.yml"].sort

      @@roles = { options[:root] => {} }

      files.each do |file|
        data = YAML.load_file(file)
        next unless data
        data.each do |key, value|
          next unless value
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