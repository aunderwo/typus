require File.dirname(__FILE__) + '/../test_helper'

class ConfigurationTest < Test::Unit::TestCase

  def test_should_verify_configuration_options
    initializer = "#{Rails.root}/config/initializers/typus.rb"
    unless File.exists?(initializer)
      assert_equal "Typus", Typus::Configuration.options[:app_name]
      assert_equal 15, Typus::Configuration.options[:per_page]
      assert_equal 10, Typus::Configuration.options[:form_rows]
      assert_equal 5, Typus::Configuration.options[:minute_step]
      assert_equal true, Typus::Configuration.options[:toggle]
      assert_equal true, Typus::Configuration.options[:edit_after_create]
      assert_equal 'admin@example.com', Typus::Configuration.options[:email]
      assert_equal 'nil', Typus::Configuration.options[:nil]
      assert_equal 'TypusUser', Typus::Configuration.options[:user_class_name]
      assert_equal 'typus_user_id', Typus::Configuration.options[:user_fk]
    else
      assert Typus::Configuration.respond_to?(:options)
    end
  end

  def test_should_verify_typus_roles_is_loaded
    assert Typus::Configuration.respond_to?(:roles!)
    assert Typus::Configuration.roles!.kind_of?(Hash)
  end

  def test_should_verify_typus_config_file_is_loaded
    assert Typus::Configuration.respond_to?(:config!)
    assert Typus::Configuration.config!.kind_of?(Hash)
  end

end