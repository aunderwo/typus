require 'test/helper'

class AdminHelperTest < ActiveSupport::TestCase

  include AdminHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TagHelper

  def test_display_link_to_previous

    output = display_link_to_previous('Post', { :action => 'edit', :back_to => '/back_to_param' })
    expected = <<-HTML
<div id="flash" class="notice">
  <p>You're updating a Post. <a href="/back_to_param">Do you want to cancel it?</a></p>
</div>
    HTML

    assert_equal expected, output

  end

  def test_remove_filter_link
    output = remove_filter_link('')
    assert output.nil?
  end

  def test_build_list_when_returns_a_typus_table

    model = TypusUser
    fields = [ 'email', 'roles', 'status' ]
    items = TypusUser.find(:all)
    resource = 'typus_users'

    self.stubs(:build_typus_table).returns('a_list_with_items')

    output = build_list(model, fields, items, resource)
    expected = 'a_list_with_items'

    assert_equal expected, output

  end

  def test_build_list_when_returns_a_template

    model = TypusUser
    fields = [ 'email', 'roles', 'status' ]
    items = TypusUser.find(:all)
    resource = 'typus_users'

    self.stubs(:render).returns('a_template')
    File.stubs(:exists?).returns(true)

    output = build_list(model, fields, items, resource)
    expected = 'a_template'

    assert_equal expected, output

  end

  def test_build_pagination
    assert true
  end

end