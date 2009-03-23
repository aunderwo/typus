require 'test/helper'

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

  def test_should_render_posts_extensions_on_index
    get :index
    assert_response :success
    partials = %w( _index_sidebar.html.erb _index_top.html.erb _index_bottom.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

  def test_should_render_posts_extensions_on_edit
    get :edit, { :id => @comment.id }
    assert_response :success
    partials = %w( _edit_sidebar.html.erb _edit_top.html.erb _edit_bottom.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

  def test_should_render_posts_extensions_on_show
    get :show, { :id => @comment.id }
    assert_response :success
    partials = %w( _show_sidebar.html.erb _show_top.html.erb _show_bottom.html.erb )
    partials.each { |p| assert_match p, @response.body }
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
    assert_match 'Add entry', @response.body
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

  def test_should_verify_new_comment_contains_a_link_to_add_a_new_post
    get :new
    match = '/typus/posts/new?back_to=%2Ftypus%2Fcomments%2Fnew&amp;selected=post_id'
    assert_match match, @response.body
  end

  def test_should_verify_edit_comment_contains_a_link_to_add_a_new_post
    comment = comments(:first)
    get :edit, :id => comment.id
    match = "/typus/posts/new?back_to=%2Ftypus%2Fcomments%2F#{comment.id}%2Fedit&amp;selected=post_id"
    assert_match match, @response.body
  end

end