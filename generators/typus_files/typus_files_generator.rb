class TypusFilesGenerator < Rails::Generator::Base

  def manifest

    record do |m|

      # We use the Dir[] to detect all the existing migrations because 
      # Rails is not working as expected.
      migrations = ['create_typus_users']
      migrations.each do |migration|
        if Dir["db/migrate/[0-9]*_*.rb"].grep(/[0-9]+_#{migration}.rb$/).empty?
          m.migration_template "db/#{migration}.rb", 
                               "db/migrate", 
                               { :migration_file_name => migration }
        end
      end

      application = File.basename(Dir.pwd)

      # For creating `typus.yml` and `typus_roles.yml` we need first to 
      # detect the available AR models of the application, not the plugins.
      Dir.chdir("#{Rails.root}/app/models")
      models, ar_models = Dir["*.rb"], []

      models.each do |model|
        class_name = model.sub(/\.rb$/,'').classify
        begin
          klass = class_name.constantize
          ar_models << klass if klass.superclass.to_s.include?("ActiveRecord::Base")
        rescue Exception => e
          puts "=> [typus] #{e.message} on `#{class_name}`."
        end
      end

      # Configuration files
      folder = "#{Rails.root}/config/typus"
      Dir.mkdir(folder) unless File.directory?(folder)

      files = %w( typus.yml typus_roles.yml application.yml application_roles.yml )
      files.each do |file|
        m.template "config/typus/#{file}", 
                   "config/typus/#{file}", 
                   :assigns => { :ar_models => ar_models, :application => application }
      end

      # Initializers
      m.template "initializers/typus.rb", 
                 "config/initializers/typus.rb", 
                 :assigns => { :application => application }

      # Public folders
      [ "#{Rails.root}/public/stylesheets/admin", 
        "#{Rails.root}/public/javascripts/admin", 
        "#{Rails.root}/public/images/admin" ].each do |folder|
        Dir.mkdir(folder) unless File.directory?(folder)
      end

      m.file "stylesheets/admin/screen.css", "public/stylesheets/admin/screen.css"
      m.file "stylesheets/admin/reset.css", "public/stylesheets/admin/reset.css"
      m.file "javascripts/admin/application.js", "public/javascripts/admin/application.js"

      files = %w( spinner.gif trash.gif status_false.gif status_true.gif )
      files.each { |file| m.file "images/admin/#{file}", "public/images/admin/#{file}" }

    end

  end

end