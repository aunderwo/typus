require 'test/helper'

class AdminSidebarHelperTest < ActiveSupport::TestCase

  include AdminSidebarHelper
  include ActionView::Helpers::UrlHelper
  include ActionController::UrlWriter
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper

  def setup
    default_url_options[:host] = 'test.host'
  end

  def test_actions

    self.expects(:default_actions).returns(['action1', 'action2'])
    self.expects(:previous_and_next).returns(['previous', 'next'])
    self.expects(:modules).with('parent_module').returns(['parent_module'])
    self.expects(:modules).with('submodules').returns(['submodules'])

    output = actions
    expected = <<-HTML
<h2>Actions</h2>
<ul>
<li>action1</li>
<li>action2</li>
</ul>

<h2>Go to</h2>
<ul>
<li>previous</li>
<li>next</li>
</ul>

<h2>Parent module</h2>
<ul>
<li>parent_module</li>
</ul>

<h2>Submodules</h2>
<ul>
<li>submodules</li>
</ul>

    HTML

    assert_equal expected, output

  end

  def test_default_actions
    assert true
  end

  def test_non_crud_actions

    @resource = { :class => Page }
    @current_user = typus_users(:admin)

    # Index without params

    params = { :controller => 'admin/pages', :action => 'index' }
    self.expects(:params).at_least_once.returns(params)

    output = non_crud_actions
    expected = [ "<a href=\"http://test.host/typus/pages/rebuild_all\">Rebuild all</a>" ]
    assert output.kind_of?(Array)
    assert_equal expected, output

    # Index with params

    params = { :controller => 'admin/pages', :action => 'index', :status => true }
    self.expects(:params).at_least_once.returns(params)

    output = non_crud_actions
    expected = [ "<a href=\"http://test.host/typus/pages/rebuild_all?status=true\">Rebuild all</a>" ]
    assert output.kind_of?(Array)
    assert_equal expected, output

    # Edit

    params = { :controller => 'admin/pages', :action => 'edit', :id => 1 }
    self.expects(:params).at_least_once.returns(params)

    output = non_crud_actions
    expected = [ "<a href=\"http://test.host/typus/pages/1/rebuild\">Rebuild</a>" ]
    assert output.kind_of?(Array)
    assert_equal expected, output

  end

  def test_build_typus_list

    output = build_typus_list([], header = nil)
    assert output.empty?

    output = build_typus_list(['item1', 'item2'], "Chunky Bacon")
    assert !output.empty?
    assert_match /Chunky bacon/, output

    output = build_typus_list(['item1', 'item2'])
    assert !output.empty?
    assert_no_match /h2/, output
    assert_no_match /\/h2/, output

  end

  def test_modules
    assert true
  end

  def test_previous_and_next

    params = { :controller => 'admin/typus_users', :action => 'index' }
    self.expects(:params).at_least_once.returns(params)

    output = previous_and_next
    assert output.empty?

    # Test when there are no records.

    typus_user = TypusUser.first
    @next = nil
    @previous = nil

    params = { :controller => 'admin/typus_users', :action => 'edit', :id => typus_user.id }
    self.expects(:params).at_least_once.returns(params)

    output = previous_and_next
    assert output.empty?

    # Test when we are on the first item.

    typus_user = TypusUser.first
    @previous, @next = typus_user.previous_and_next

    output = previous_and_next
    expected = [ "<a href=\"http://test.host/typus/typus_users/#{@next.id}/edit\">Next</a>" ]
    assert_equal expected, output

    # Test when we are on the last item.

    typus_user = TypusUser.last
    @previous, @next = typus_user.previous_and_next

    output = previous_and_next
    expected = [ "<a href=\"http://test.host/typus/typus_users/#{@previous.id}/edit\">Previous</a>" ]
    assert_equal expected, output

    # Test when we are on the middle.

    typus_user = TypusUser.find(3)
    @previous, @next = typus_user.previous_and_next

    output = previous_and_next
    expected = [ "<a href=\"http://test.host/typus/typus_users/#{@next.id}/edit\">Next</a>", 
                 "<a href=\"http://test.host/typus/typus_users/#{@previous.id}/edit\">Previous</a>" ]
    assert_equal expected, output

  end

  def test_previous_and_next_with_params
    assert true
  end

  def test_search

    @resource = { :class => TypusUser, :self => 'typus_users' }

    params = { :controller => 'admin/typus_users', :action => 'index' }
    self.expects(:params).at_least_once.returns(params)

    output = search
    expected = <<-HTML
<h2>Search</h2>
<form action="" method="get">
<p><input id="search" name="search" type="text" value=""/></p>
<input id="action" name="action" type="hidden" value="index" />
<input id="controller" name="controller" type="hidden" value="admin/typus_users" />
</form>
<p class="tip">Search by first name, last name, email & roles.</p>
    HTML

    assert_equal expected, output

  end

  def test_filters

    @resource = { :class => TypusUser, :self => 'typus_users' }

    @resource[:class].expects(:typus_filters).returns(Array.new)

    output = filters
    assert output.nil?

    # TODO: Test filters when @resource[:class].typus_filters returns filters.

  end

  def test_relationship_filter
    assert true
  end

  def test_datetime_filter

    @resource = { :class => TypusUser, :self => 'typus_users' }
    filter = 'created_at'

    params = { :controller => 'admin/typus_users', :action => 'index' }
    self.expects(:params).at_least_once.returns(params)

    request = ''
    output = datetime_filter(request, filter)
    expected = <<-HTML
<h2>Created at</h2>
<ul>
<li><a href="http://test.host/typus/typus_users?created_at=today" class="off">Today</a></li>
<li><a href="http://test.host/typus/typus_users?created_at=past_7_days" class="off">Past 7 Days</a></li>
<li><a href="http://test.host/typus/typus_users?created_at=this_month" class="off">This Month</a></li>
<li><a href="http://test.host/typus/typus_users?created_at=this_year" class="off">This Year</a></li>
</ul>
    HTML
    assert_equal expected, output

    request = 'created_at=today&page=1'
    output = datetime_filter(request, filter)
    expected = <<-HTML
<h2>Created at</h2>
<ul>
<li><a href="http://test.host/typus/typus_users?created_at=today" class="on">Today</a></li>
<li><a href="http://test.host/typus/typus_users?created_at=past_7_days" class="off">Past 7 Days</a></li>
<li><a href="http://test.host/typus/typus_users?created_at=this_month" class="off">This Month</a></li>
<li><a href="http://test.host/typus/typus_users?created_at=this_year" class="off">This Year</a></li>
</ul>
    HTML
    assert_equal expected, output

  end

  def test_boolean_filter

    @resource = { :class => TypusUser, :self => 'typus_users' }
    filter = 'status'

    params = { :controller => 'admin/typus_users', :action => 'index' }
    self.expects(:params).at_least_once.returns(params)

    # Status is true

    request = 'status=true&page=1'
    output = boolean_filter(request, filter)
    expected = <<-HTML
<h2>Status</h2>
<ul>
<li><a href="http://test.host/typus/typus_users?status=true" class="on">Active</a></li>
<li><a href="http://test.host/typus/typus_users?status=false" class="off">Inactive</a></li>
</ul>
    HTML
    assert_equal expected, output

    # Status is false

    request = 'status=false&page=1'
    output = boolean_filter(request, filter)
    expected = <<-HTML
<h2>Status</h2>
<ul>
<li><a href="http://test.host/typus/typus_users?status=true" class="off">Active</a></li>
<li><a href="http://test.host/typus/typus_users?status=false" class="on">Inactive</a></li>
</ul>
    HTML
    assert_equal expected, output

  end

  def test_string_filter_when_values_are_strings

    @resource = { :class => TypusUser, :self => 'typus_users' }
    filter = 'roles'

    params = { :controller => 'admin/typus_users', :action => 'index' }
    self.expects(:params).at_least_once.returns(params)

    # Roles is admin

    request = 'roles=admin&page=1'
    @resource[:class].expects('roles').returns(['admin', 'designer', 'editor'])
    output = string_filter(request, filter)
    expected = <<-HTML
<h2>Roles</h2>
<ul>
<li><a href="http://test.host/typus/typus_users?roles=admin" class="on">Admin</a></li>
<li><a href="http://test.host/typus/typus_users?roles=designer" class="off">Designer</a></li>
<li><a href="http://test.host/typus/typus_users?roles=editor" class="off">Editor</a></li>
</ul>
    HTML
    assert_equal expected, output

    # Roles is editor

    request = 'roles=editor&page=1'
    @resource[:class].expects('roles').returns(['admin', 'designer', 'editor'])
    output = string_filter(request, filter)
    expected = <<-HTML
<h2>Roles</h2>
<ul>
<li><a href="http://test.host/typus/typus_users?roles=admin" class="off">Admin</a></li>
<li><a href="http://test.host/typus/typus_users?roles=designer" class="off">Designer</a></li>
<li><a href="http://test.host/typus/typus_users?roles=editor" class="on">Editor</a></li>
</ul>
    HTML
    assert_equal expected, output

  end

  def test_string_filter_when_values_are_arrays_of_strings

    @resource = { :class => TypusUser, :self => 'typus_users' }
    filter = 'roles'

    params = { :controller => 'admin/typus_users', :action => 'index' }
    self.expects(:params).at_least_once.returns(params)

    request = 'roles=admin&page=1'
    array = [['Administrador', 'admin'], 
             ['Diseñador', 'designer'], 
             ['Editor', 'editor']]
    @resource[:class].expects('roles').returns(array)

    output = string_filter(request, filter)
    expected = <<-HTML
<h2>Roles</h2>
<ul>
<li><a href="http://test.host/typus/typus_users?roles=admin" class="on">Administrador</a></li>
<li><a href="http://test.host/typus/typus_users?roles=designer" class="off">Diseñador</a></li>
<li><a href="http://test.host/typus/typus_users?roles=editor" class="off">Editor</a></li>
</ul>
    HTML

    assert_equal expected, output

  end

  def test_string_filter_when_empty_values

    @resource = { :class => TypusUser }
    filter = 'roles'

    request = 'roles=admin&page=1'
    @resource[:class].expects('roles').returns([])
    output = string_filter(request, filter)
    assert output.empty?

  end

end