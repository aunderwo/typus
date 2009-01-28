require File.dirname(__FILE__) + '/../../test_helper'

##
# Here we test the template extensions rendering and all the 
# things related to views.
#
class Admin::CommentsControllerTest < ActionController::TestCase

  def setup
    @typus_user = typus_users(:admin)
    @request.session[:typus] = @typus_user.id
    @comment = comments(:first)
  end

  def test_should_render_posts_sidebar_on_index_edit_and_show

    get :index
    assert_response :success
    assert_match /_index_sidebar.html.erb/, @response.body

    get :edit, { :id => @comment.id }
    assert_response :success
    assert_match /_edit_sidebar.html.erb/, @response.body

    get :show, { :id => @comment.id }
    assert_response :success
    assert_match /_show_sidebar.html.erb/, @response.body

  end

  def test_should_render_posts_top_on_index_show_and_edit

    get :index
    assert_response :success
    assert_match /_index_top.html.erb/, @response.body

    get :edit, { :id => @comment.id }
    assert_response :success
    assert_match /_edit_top.html.erb/, @response.body

    get :show, { :id => @comment.id }
    assert_response :success
    assert_match /_show_top.html.erb/, @response.body

  end

  def test_should_render_posts_bottom_on_index_show_and_edit

    get :index
    assert_response :success
    assert_match /_index_bottom.html.erb/, @response.body

    get :edit, { :id => @comment.id }
    assert_response :success
    assert_match /_edit_bottom.html.erb/, @response.body

    get :show, { :id => @comment.id }
    assert_response :success
    assert_match /_show_bottom.html.erb/, @response.body

  end

  def test_should_verify_page_title_on_index
    get :index
    assert_select 'title', /#{Typus::Configuration.options[:app_name]}/
    assert_select 'title', /Comments/
    assert_select 'title', /&rsaquo;/
  end

  def test_should_verify_page_title_on_new
    get :new
    assert_select 'title', /#{Typus::Configuration.options[:app_name]}/
    assert_select 'title', /Comments/
    assert_select 'title', /New/
    assert_select 'title', /&rsaquo;/
  end

  def test_should_verify_page_title_on_edit
    comment = comments(:first)
    get :edit, :id => comment.id
    assert_select 'title', /#{Typus::Configuration.options[:app_name]}/
    assert_select 'title', /Comments/
    assert_select 'title', /Edit/
    assert_select 'title', /&rsaquo;/
  end

  def test_should_show_add_new_link_in_index
    get :index
    assert_response :success
    assert_match "Add entry", @response.body
  end

  def test_should_not_show_add_new_link_in_index

    typus_user = typus_users(:designer)
    @request.session[:typus] = typus_user.id

    get :index
    assert_response :success
    assert_no_match /Add comment/, @response.body

  end

  def test_should_show_trash_record_image_and_link_in_index
    get :index
    assert_response :success
    assert_match /trash.gif/, @response.body
  end

  def test_should_not_show_remove_record_link_in_index

    typus_user = typus_users(:designer)
    @request.session[:typus] = typus_user.id

    get :index
    assert_response :success
    assert_no_match /trash.gif/, @response.body

  end

  def test_should_verify_new_and_edit_page_contains_a_link_to_add_a_new_user

    get :new
    match = "/admin/users/new?back_to=%2Fadmin%2Fposts%2Fnew&amp;selected=user_id"
    assert_match match, @response.body

    post_ = posts(:published)
    get :edit, :id => post_.id
    match = "/admin/users/new?back_to=%2Fadmin%2Fposts%2F1%2Fedit&amp;selected=user_id"
    assert_match match, @response.body

  end

  def test_should_verify_new_and_edit_page_contains_a_link_to_add_a_new_user
    get :new
    match = "/admin/posts/new?back_to=%2Fadmin%2Fcomments%2Fnew&amp;selected=post_id"
    assert_match match, @response.body
  end

  def test_should_verify_new_and_edit_page_contains_a_link_to_add_a_new_user
    comment = comments(:first)
    get :edit, :id => comment.id
    match = "/admin/posts/new?back_to=%2Fadmin%2Fcomments%2F#{comment.id}%2Fedit&amp;selected=post_id"
    assert_match match, @response.body
  end

end