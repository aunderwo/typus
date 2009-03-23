require 'typus'
require 'sha1'

if Rails.env.test?
  Typus::Configuration.options[:config_folder] = 'vendor/plugins/typus/test/config/working'
  Typus::Configuration.options[:path_prefix] = 'typus'
end

##
# Typus.enable and run the generator unless we are testing the plugin.
# Do not Typus.enable or generate files if we are running a rails 
# generator.
#

scripts = %w( script/generate script/destroy )

unless scripts.include?($0)
  Typus.enable
  Typus.generator unless Rails.env.test?
end