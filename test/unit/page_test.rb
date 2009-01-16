require File.dirname(__FILE__) + '/../test_helper'

##
# Here we test special methods which allow to overwrite the typus.yml 
# configuration file, or add the atributes which are not defined.
#
class PageTest < ActiveSupport::TestCase

  def test_should_verify_admin_fields_for_list_are_overwrited

    assert_equal 'title, body, status', Typus::Configuration.config['Page']['fields']['list']

    assert Page.respond_to?('admin_fields_for_list')
    assert_equal Page.admin_fields_for_list, Page.typus_fields_for('list').map { |i| i.first }

  end

  def test_should_verify_admin_fields_for_form_are_overwrited

    assert_equal 'title, body, status', Typus::Configuration.config['Page']['fields']['form']

    assert Page.respond_to?('admin_fields_for_form')
    assert_equal Page.admin_fields_for_form, Page.typus_fields_for('form').map { |i| i.first }

  end

  def test_should_verify_admin_order_by_is_defined_in_the_model

    assert_nil Typus::Configuration.config['Page']['order_by']

    assert Page.respond_to?('admin_order_by')
    assert_equal "`pages`.status ASC", Page.typus_order_by
    assert_equal %w( status ), Page.admin_order_by

  end

  def test_should_verify_admin_search_is_defined_in_the_model

    assert_nil Typus::Configuration.config['Page']['search']

    assert Page.respond_to?('admin_search')
    assert_equal [ 'title', 'body' ], Page.admin_search

  end

  def test_should_verify_actions_for_are_called_from_the_model

    assert_nil Typus::Configuration.config['Page']['actions']

    assert Page.respond_to?('admin_actions_for_index')
    assert_equal %w( rebuild_all ), Page.typus_actions_for('index')
    assert_equal %w( rebuild_all ), Page.admin_actions_for_index

    assert Page.respond_to?('admin_actions_for_edit')
    assert_equal %w( rebuild ), Page.typus_actions_for('edit')
    assert_equal %w( rebuild ), Page.admin_actions_for_edit

  end

  def test_should_verify_admin_filters_is_called_from_the_model

    assert_nil Typus::Configuration.config['Page']['filters']

    assert Page.respond_to?('admin_filters')
    assert_equal %w( status created_at ), Page.admin_filters
    assert_equal %w( status created_at ), Page.typus_filters.collect { |i| i.first }
    assert_equal [["status", :boolean], ["created_at", nil]], Page.typus_filters

  end

end