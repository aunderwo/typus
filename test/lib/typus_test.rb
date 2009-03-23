require 'test/helper'

class TypusTest < ActiveSupport::TestCase

  def test_should_return_locales
    assert Typus.respond_to?(:locales)
    assert Typus.locales.kind_of?(Array)
    assert_equal [["English", :en]], Typus.locales
  end

  def test_should_return_default_locale
    assert Typus.respond_to?(:default_locale)
    assert Typus.default_locale.kind_of?(Symbol)
    assert_equal :en, Typus.default_locale
  end

  def test_should_return_applications_and_should_be_sorted
    assert Typus.respond_to?(:applications)
    assert Typus.applications.kind_of?(Array)
    assert_equal %w( Blog Site Typus ), Typus.applications
  end

  def test_should_return_modules_of_an_application
    assert Typus.respond_to?(:application)
    assert_equal %w( Comment Post ), Typus.application('Blog')
  end

  def test_should_return_modules_of_a_module
    assert Typus.respond_to?(:module)
    assert_equal %w( Category ), Typus.module('Post')
  end

  def test_should_verify_parent_exists
    assert Typus.respond_to?(:parent)
  end

=begin

  def test_should_verify_parent_for_module
    assert Typus.parent(TypusUser.name, 'module').kind_of?(String)
    assert_equal 'Typus', Typus.parent(TypusUser.name, 'module')
  end

=end

  def test_should_verify_parent_for_application
    assert Typus.parent(TypusUser.name, 'application').kind_of?(String)
    assert_equal 'Typus', Typus.parent(TypusUser.name, 'application')
  end

  def test_should_verify_parent_for_nothing
    assert Typus.parent(TypusUser.name, 'nothing').kind_of?(String)
    assert_equal '', Typus.parent(TypusUser.name, 'nothing')
  end

  def test_should_return_models_and_should_be_sorted
    assert Typus.respond_to?(:models)
    assert Typus.models.kind_of?(Array)
    assert_equal %w( Asset Category Comment Page Post TypusUser User ), Typus.models
  end

  def test_should_verify_resources_class_method
    assert Typus.respond_to?(:resources)
    models = Typus.models
    assert_equal %w( Git Status WatchDog ), Typus.resources(models)
  end

  def test_should_return_description_of_module
    assert Typus.respond_to?(:module_description)
    assert_equal 'System Users Administration', Typus.module_description('TypusUser')
  end

  def test_should_verify_enable_exists
    assert Typus.respond_to?(:enable)
  end

  def test_should_verify_enable_exists
    assert Typus.respond_to?(:generator)
  end

  def test_should_return_user_class
    assert_equal TypusUser, Typus.user_class
  end

  def test_should_return_overwritted_user_class
    options = { :user_class_name => 'CustomUser' }
    Typus::Configuration.stubs(:options).returns(options)
    assert_equal CustomUser, Typus.user_class
  end

  def test_should_return_user_fk
    assert_equal 'typus_user_id', Typus.user_fk
  end

  def test_should_return_overwritted_user_fk
    options = { :user_fk => 'my_user_fk' }
    Typus::Configuration.stubs(:options).returns(options)
    assert_equal 'my_user_fk', Typus.user_fk
  end

  def test_should_verify_to_sentence_options

    assert Typus.respond_to?(:to_sentence_options)
    assert Typus.to_sentence_options.kind_of?(Hash)

    expected = { :words_connector => ', ', :last_word_connector => ' & ' }
    assert_equal expected, Typus.to_sentence_options

    expected = { :words_connector => ', ', :last_word_connector => ' or ' }
    assert_equal expected, Typus.to_sentence_options('or')

  end

end