module Typus

  class << self

    ##
    # Typus Root
    #
    def root
      File.dirname(__FILE__) + '/../'
    end

    ##
    # Returns a list of the available locales.
    #
    def locales
      Typus::Configuration.options[:locales]
    end

    ##
    # Get the default locale.
    #
    def default_locale
      locales.map(&:last).first
    end

    ##
    # Returns a list of all the applications.
    #
    def applications
      Typus::Configuration.config.collect { |i| i.last['application'] }.compact.uniq.sort
    end

    ##
    # Returns a list of the modules of an application.
    #
    def application(name)
      Typus::Configuration.config.collect { |i| i.first if i.last['application'] == name }.compact.uniq.sort
    end

    ##
    # Returns a list of the submodules of a module.
    #
    def module(name)
      Typus::Configuration.config.collect { |i| i.first if i.last['module'] == name }.compact.uniq.sort
    end

    ##
    # Parent
    #
    #  Typus::Configuration.config['Post']['module']
    #  Typus::Configuration.config['Post']['application']
    #
    def parent(model, name)
      Typus::Configuration.config[model][name] || ''
    end

    ##
    # Return a list of models.
    #
    def models
      Typus::Configuration.config.map { |i| i.first }.sort
    end

    ##
    # Return a list of resources, which are models tableless.
    #
    def resources(models = get_model_names)

      all_resources = Typus::Configuration.roles.keys.map do |key|
                        Typus::Configuration.roles[key].keys
                      end.flatten.sort.uniq

      all_resources.delete_if { |x| models.include?(x) } rescue []

    end

    ##
    # Get models folders
    #
    def get_model_names
      Dir[ "#{Rails.root}/app/models/**/*.rb", 
           "#{Rails.root}/vendor/plugins/**/app/models/**/*.rb" ].collect { |m| File.basename(m).sub(/\.rb$/,'').camelize }
    end

    def module_description(modulo)
      Typus::Configuration.config[modulo]['description']
    end

    def user_class
      Typus::Configuration.options[:user_class_name].constantize
    end

    def user_fk
      Typus::Configuration.options[:user_fk]
    end

    ##
    # Load configuration files, translations, modules and extensions.
    #
    def enable

      # Ruby Extensions
      require 'typus/hash'
      require 'typus/string'

      Typus::Configuration.config!
      Typus::Configuration.roles!
      I18n.load_path += Dir[File.join("#{Rails.root}/vendor/plugins/typus/config/locales/*.yml")]

      require File.dirname(__FILE__) + '/../test/models' if Rails.env.test?

      # Rails Extensions
      require 'typus/active_record'
      require 'typus/routes'

      # Rails Overwrites
      require 'typus/translation_helper' if Typus::Configuration.options[:ignore_missing_translations]

      # Mixins
      require 'typus/authentication'
      require 'typus/export'
      require 'typus/greetings'
      require 'typus/locale'
      require 'typus/user'
      require 'typus/generator'
      require 'typus/more'

      # Vendor
      require 'vendor/active_record'
      require 'vendor/paginator'

    end

  end

end