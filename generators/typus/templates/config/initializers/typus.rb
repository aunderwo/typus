# Be sure to restart your server when you modify this file.

# Typus configuration options which you only can set from the 
# environments. Set them on `production.rb`, `development.rb` on 
# `config/environments` folder.

# Typus::Configuration.options[:ignore_missing_translations] = true
# Typus::Configuration.options[:path_prefix] = 'admin'

# System wide options

Typus::Configuration.options[:app_name] = '<%= application %>'
# Typus::Configuration.options[:config_folder] = 'config/typus'
# Typus::Configuration.options[:email] = 'admin@example.com'
# Typus::Configuration.options[:locales] = [ [ "English", :en ], [ "Español", :es ] ]
# Typus::Configuration.options[:recover_password] = true
# Typus::Configuration.options[:root] = 'admin'
# Typus::Configuration.options[:ssl] = false
# Typus::Configuration.options[:templates_folder] = 'admin/templates'
# Typus::Configuration.options[:user_class_name] = 'TypusUser'
# Typus::Configuration.options[:user_fk] = 'typus_user_id'

# Model options.

# Typus::Configuration.options[:edit_after_create] = true
# Typus::Configuration.options[:end_year] = Time.now.year + 1
# Typus::Configuration.options[:form_rows] = 10
# Typus::Configuration.options[:icon_on_boolean] = false
# Typus::Configuration.options[:minute_step] = 5
# Typus::Configuration.options[:nil] = 'nil'
# Typus::Configuration.options[:per_page] = 15
# Typus::Configuration.options[:sidebar_selector] = 10
# Typus::Configuration.options[:start_year] = Time.now.year - 10
# Typus::Configuration.options[:toggle] = true