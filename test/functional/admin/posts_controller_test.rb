require 'test/helper'

##
# Here we test the CRUD actions and ...
#
#   - Relate comment which is a has_many relationship.
#   - Unrelate comment which is a has_many relationship.
#
class Admin::PostsControllerTest < ActionController::TestCase

  def setup
    typus_user = typus_users(:admin)
    @request.session[:typus] = typus_user.id
  end

  def test_should_redirect_to_login

    @request.session[:typus] = nil

    get :index
    assert_response :redirect
    assert_redirected_to admin_sign_in_path(:back_to => '/typus/posts')
    get :edit, { :id => 1 }
    assert_response :redirect
    assert_redirected_to admin_sign_in_path(:back_to => '/typus/posts')

  end

  def test_should_render_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_should_render_new
    test_should_update_item_and_redirect_to_index
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_should_create_item_and_redirect_to_index

    options = Typus::Configuration.options.merge(:edit_after_create => false)
    Typus::Configuration.stubs(:options).returns(options)

    assert_difference 'Post.count' do
      post :create, { :item => { :title => 'This is another title', :body => 'Body' } }
      assert_response :redirect
      assert_redirected_to :action => 'index'
    end

  end

  def test_should_create_item_and_redirect_to_edit

    options = Typus::Configuration.options.merge(:edit_after_create => true)
    Typus::Configuration.stubs(:options).returns(options)

    assert_difference 'Post.count' do
      post :create, { :item => { :title => 'This is another title', :body => 'Body' } }
      assert_response :redirect
      assert_redirected_to :action => 'edit'
    end

  end

  def test_should_render_show
    post_ = posts(:published)
    get :show, { :id => post_.id }
    assert_response :success
    assert_template 'show'
  end

  def test_should_render_edit
    post_ = posts(:published)
    get :edit, { :id => post_.id }
    assert_response :success
    assert_template 'edit'
  end

  def test_should_update_item_and_redirect_to_index

    options = Typus::Configuration.options.merge(:edit_after_create => false)
    Typus::Configuration.stubs(:options).returns(options)

    post_ = posts(:published)
    post :update, { :id => post_.id, :title => 'Updated' }
    assert_response :redirect
    assert_redirected_to :action => 'index'

  end

  def test_should_update_item_and_redirect_to_edit

    options = Typus::Configuration.options.merge(:edit_after_create => true)
    Typus::Configuration.stubs(:options).returns(options)

    post_ = posts(:published)
    post :update, { :id => post_.id, :title => 'Updated' }
    assert_response :redirect
    assert_redirected_to :action => 'edit', :id => post_.id

  end

  def test_should_allow_admin_to_toggle_item
    @request.env['HTTP_REFERER'] = '/typus/posts'
    post = posts(:unpublished)
    get :toggle, { :id => post.id, :field => 'status' }
    assert_response :redirect
    assert_redirected_to :action => 'index'
    assert flash[:success]
    assert Post.find(post.id).status
  end

  def test_should_perform_a_search
    typus_user = typus_users(:admin)
    @request.session[:typus] = typus_user.id
    get :index, { :search => 'neinonon' }
    assert_response :success
    assert_template 'index'
  end

  def test_should_relate_category_to_post_which_is_a_habtm_relationship
    category = categories(:first)
    post_ = posts(:published)
    @request.env['HTTP_REFERER'] = "/typus/posts/#{post_.id}/edit#categories"
    assert_difference('category.posts.count') do
      post :relate, { :id => post_.id, :related => { :model => 'Category', :id => category.id } }
    end
    assert_response :redirect
    assert flash[:success]
    assert_redirected_to @request.env['HTTP_REFERER']
  end

  def test_should_unrelate_category_from_post_which_is_a_habtm_relationship
    category = categories(:first)
    post_ = posts(:published)
    @request.env['HTTP_REFERER'] = "/typus/posts/#{post_.id}/edit#categories"
    assert_difference('category.posts.count', 0) do
      post :unrelate, { :id => post_.id, :resource => 'categories', :resource_id => category.id }
    end
    assert_response :redirect
    assert flash[:success]
    assert_match /Category unrelated from/, flash[:success]
    assert_redirected_to @request.env['HTTP_REFERER']
  end

  ##
  # This is a polimorphic relationship.
  #
  def test_should_unrelate_an_asset_from_a_post

    post_ = posts(:published)

    @request.env['HTTP_REFERER'] = "/typus/posts/#{post_.id}/edit#assets"

    assert_difference('post_.assets.count', -1) do
      get :unrelate, { :id => post_.id, :resource => 'assets', :resource_id => post_.assets.first.id }
    end

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:success]
    assert_match /Asset removed from/, flash[:success]

  end

  def test_should_check_redirection_when_theres_no_http_referer_on_new

    typus_user = typus_users(:designer)
    @request.session[:typus] = typus_user.id

    get :new
    assert_response :redirect
    assert_redirected_to admin_dashboard_path

    assert flash[:notice]
    assert_equal 'Designer can\'t perform action (new)', flash[:notice]

    @request.env['HTTP_REFERER'] = '/admin/posts'

    typus_user = typus_users(:designer)
    @request.session[:typus] = typus_user.id

    get :new
    assert_response :redirect
    assert_redirected_to '/admin/posts'

    assert flash[:notice]
    assert_equal 'Designer can\'t perform action (new)', flash[:notice]

  end

  def test_should_disable_toggle_and_check_links_are_disabled

    options = Typus::Configuration.options.merge(:toggle => false)
    Typus::Configuration.stubs(:options).returns(options)

    @request.env['HTTP_REFERER'] = '/typus/posts'
    post = posts(:unpublished)
    get :toggle, { :id => post.id, :field => 'status' }
    assert_response :redirect
    assert_redirected_to :action => 'index'
    assert !flash[:success]
    assert flash[:warning]
    assert_match /Toggle is disabled/, flash[:warning]

  end

  def test_should_show_form_templates
    get :new
    assert_response :success
    assert_match /datepicker_template_published_at/, @response.body
  end

  def test_should_add_back_to_params_for_comment_items

    post_ = posts(:published)
    get :edit, { :id => post_.id }
    assert_response :success
    back_to = "/posts/#{post_.id}/edit"
    re = /<a href="\/typus\/assets\/1\/edit(.*)">This is the caption\.<\/a>/
    params = re.match(@response.body)

    assert_equal params[1], "?back_to=%2Ftypus%2Fposts%2F1%2Fedit&amp;resource=posts&amp;resource_id=#{post_.id}"

  end

end