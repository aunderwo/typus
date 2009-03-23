class TypusGenerator < Rails::Generator::Base

  def manifest

    record do |m|

      ##
      # Default name for our application.
      #

      application = File.basename(Dir.pwd)

      ##
      # To create `application.yml` and `application_roles.yml` detect 
      # available AR models on the application.
      #

      models = Dir["#{Rails.root}/app/models/*.rb"].collect { |x| File.basename(x) }
      ar_models = []

      models.each do |model|
        class_name = model.sub(/\.rb$/,'').classify
        begin
          klass = class_name.constantize
          ar_models << klass if klass.superclass.equal?(ActiveRecord::Base)
        rescue Exception => e
          puts "=> [typus] #{e.message} on `#{class_name}`."
        end
      end

      ##
      # Configuration files
      #

      config_folder = Typus::Configuration.options[:config_folder]
      folder = "#{Rails.root}/#{config_folder}"
      Dir.mkdir(folder) unless File.directory?(folder)

      Dir["#{Typus.root}/generators/typus/templates/config/typus/*"].each do |f|
        base = File.basename(f)
        m.template "config/typus/#{base}", "#{config_folder}/#{base}", 
                   :assigns => { :ar_models => ar_models, :application => application }
      end

      ##
      # Initializers
      #

      m.template 'config/initializers/typus.rb', 'config/initializers/typus.rb', 
                 :assigns => { :application => application }

      ##
      # Public folders
      #

      [ "#{Rails.root}/public/stylesheets/admin", 
        "#{Rails.root}/public/javascripts/admin", 
        "#{Rails.root}/public/images/admin" ].each do |folder|
        Dir.mkdir(folder) unless File.directory?(folder)
      end

      m.file 'public/stylesheets/admin/screen.css', 'public/stylesheets/admin/screen.css'
      m.file 'public/stylesheets/admin/reset.css', 'public/stylesheets/admin/reset.css'
      m.file 'public/javascripts/admin/application.js', 'public/javascripts/admin/application.js'

      Dir["#{Typus.root}/generators/typus/templates/public/images/admin/*"].each do |f|
        base = File.basename(f)
        m.file "public/images/admin/#{base}", "public/images/admin/#{base}"
      end

      ##
      # Migration file
      #

      m.migration_template 'db/create_typus_users.rb', 'db/migrate', 
                            { :migration_file_name => 'create_typus_users' }

    end

  end

end