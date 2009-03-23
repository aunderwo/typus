require 'test/helper'

class TypusControllerTest < ActionController::TestCase

  def setup
    Typus::Configuration.options[:recover_password] = true
    Typus::Configuration.options[:app_name] = 'whatistypus.com'
  end

  def test_should_render_login
    get :sign_in
    assert_response :success
    assert_template 'sign_in'
  end

  def test_should_sign_in_and_redirect_to_dashboard
    typus_user = typus_users(:admin)
    post :sign_in, { :user => { :email => typus_user.email, 
                                :password => '12345678' } }
    assert_equal typus_user.id, @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_dashboard_path
  end

  def test_should_not_sign_in_a_disabled_user
    typus_user = typus_users(:disabled_user)
    post :sign_in, { :user => { :email => typus_user.email, 
                                :password => '12345678' } }
    assert_nil @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_sign_in_path
  end

  def test_should_not_sign_in_a_removed_role
    typus_user = typus_users(:removed_role)
    post :sign_in, { :user => { :email => typus_user.email, 
                                :password => '12345678' } }
    assert_equal typus_user.id, @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_dashboard_path
    get :dashboard
    assert_redirected_to admin_sign_in_path
    assert_nil @request.session[:typus]
    assert flash[:notice]
    assert_equal 'Typus user or role no longer exist.', flash[:notice]
  end

  def test_should_not_send_recovery_password_link_to_unexisting_user
    post :recover_password, { :user => { :email => 'unexisting' } }
    assert_response :redirect
    assert_redirected_to admin_recover_password_path
    [ :notice, :error, :warning ].each { |f| assert !flash[f] }
  end

  def test_should_send_recovery_password_link_to_existing_user
    admin = typus_users(:admin)
    post :recover_password, { :user => { :email => admin.email } }
    assert_response :redirect
    assert_redirected_to admin_sign_in_path
    assert flash[:success]
    assert_match /Password recovery link sent to your email/, flash[:success]
  end

  def test_should_sign_out
    admin = typus_users(:admin)
    @request.session[:typus] = admin.id
    get :sign_out
    assert_nil @request.session[:typus]
    assert_response :redirect
    assert_redirected_to admin_sign_in_path
    [ :notice, :error, :warning ].each { |f| assert !flash[f] }
  end

  def test_should_verify_we_can_disable_users_and_block_acess_on_the_fly

    admin = typus_users(:admin)
    @request.session[:typus] = admin.id
    get :dashboard
    assert_response :success

    # Disable user ...

    admin.update_attributes :status => false

    get :dashboard
    assert_response :redirect
    assert_redirected_to admin_sign_in_path

    assert flash[:notice]
    assert_equal "Your typus user has been disabled.", flash[:notice]
    assert_nil @request.session[:typus]

  end

  def test_should_not_allow_reset_password_if_disabled

    typus_user = typus_users(:admin)
    get :reset_password, { :token => typus_user.token }
    assert_response :success
    assert_template 'reset_password'

    options = Typus::Configuration.options.merge(:recover_password => false)
    Typus::Configuration.stubs(:options).returns(options)

    get :reset_password
    assert_response :redirect
    assert_redirected_to admin_sign_in_path

  end

  def test_should_return_404_when_reseting_passsowrd_if_token_is_invalid
    assert_raise(ActiveRecord::RecordNotFound) { get :reset_password, { :token => 'INVALID' } }
  end

  def test_should_allow_a_user_with_valid_token_to_change_password
    typus_user = typus_users(:admin)
    get :reset_password, { :token => typus_user.token }
    assert_response :success
    assert_template 'reset_password'
  end

  def test_should_verify_typus_sign_in_layout_includes_recover_password_link
    options = Typus::Configuration.options.merge(:recover_password => true)
    Typus::Configuration.stubs(:options).returns(options)
    get :sign_in
    assert @response.body.include?('Recover password')
  end

  def test_should_verify_typus_sign_in_layout_does_not_include_recover_password_link
    options = Typus::Configuration.options.merge(:recover_password => false)
    Typus::Configuration.stubs(:options).returns(options)
    get :sign_in
    assert !@response.body.include?('Recover password')
  end

  def test_should_render_typus_login_footer
    expected = 'Typus'
    get :sign_in
    assert_response :success
    assert_match /#{expected}/, @response.body
    assert_match /layouts\/typus/, @controller.active_layout.to_s
  end

  def test_should_render_admin_login_bottom
    get :sign_in
    assert_response :success
    assert_select 'h1', 'whatistypus.com'
    assert_match /layouts\/typus/, @controller.active_layout.to_s
  end

  def test_should_verify_page_title_on_sign_in
    get :sign_in
    assert_select 'title', "#{Typus::Configuration.options[:app_name]} &rsaquo; Sign in"
  end

  def test_should_create_first_typus_user

    TypusUser.destroy_all
    assert_nil @request.session[:typus]
    assert TypusUser.find(:all).empty?

    get :sign_in
    assert_response :redirect
    assert_redirected_to admin_sign_up_path

    get :sign_up
    assert flash[:notice]
    assert_equal 'Enter your email below to create the first user.', flash[:notice]

    post :sign_up, :user => { :email => 'example.com' }
    assert_response :redirect
    assert_redirected_to admin_sign_up_path
    assert flash[:error]
    assert_equal 'That doesn\'t seem like a valid email address.', flash[:error]

    post :sign_up, :user => { :email => 'john@example.com' }
    assert_response :redirect
    assert_redirected_to admin_dashboard_path
    assert flash[:notice]
    assert_match /Your new password is/, flash[:notice]
    assert @request.session[:typus]
    assert !TypusUser.find(:all).empty?

    get :sign_out
    assert_nil @request.session[:typus]
    assert_redirected_to admin_sign_in_path

    get :sign_up
    assert_redirected_to admin_sign_in_path

  end

  def test_should_redirect_to_login_if_not_logged
    @request.session[:typus] = nil
    get :dashboard
    assert_response :redirect
    assert_redirected_to admin_sign_in_path
  end

  def test_should_render_dashboard
    @request.session[:typus] = typus_users(:admin).id
    get :dashboard
    assert_response :success
    assert_template 'dashboard'
    assert_match 'whatistypus.com', @response.body
    assert_match /layouts\/admin/, @controller.active_layout.to_s
  end

  def test_should_verify_sign_up_works
    @request.session[:typus] = typus_users(:admin).id
    TypusUser.destroy_all
    get :sign_up
    assert_response :success
    assert_template 'sign_up'
    assert_match /layouts\/typus/, @controller.active_layout.to_s
  end

  def test_should_verify_page_title_on_dashboard
    @request.session[:typus] = typus_users(:admin).id
    get :dashboard
    assert_select 'title', "#{Typus::Configuration.options[:app_name]} &rsaquo; Dashboard"
  end

  def test_should_verify_link_to_edit_typus_user

    typus_user = typus_users(:admin)
    @request.session[:typus] = typus_user.id
    get :dashboard
    assert_response :success

    assert_match "href=\"\/typus\/typus_users\/#{typus_user.id}\/edit\"", @response.body

    assert_select 'body div#header' do
      assert_select 'a', 'Admin Example (admin)'
      assert_select 'a', 'Sign out'
    end

  end

  def test_should_verify_link_to_sign_out

    @request.session[:typus] = typus_users(:admin).id
    get :dashboard
    assert_response :success

    assert_match "href=\"\/typus\/sign_out\"", @response.body

  end

  def test_should_show_add_links_in_resources_list_for_admin

    @request.session[:typus] = typus_users(:admin).id
    get :dashboard

    %w( typus_users posts pages assets ).each do |resource|
      assert_match "/typus/#{resource}/new", @response.body
    end

    %w( statuses orders ).each do |resource|
      assert_no_match /\/admin\/#{resource}\n/, @response.body
    end

  end

  def test_should_show_add_links_in_resources_list_for_editor
    editor = typus_users(:editor)
    @request.session[:typus] = editor.id
    get :dashboard
    assert_match '/typus/posts/new', @response.body
    assert_no_match /\/admin\/typus_users\/new/, @response.body
    # We have loaded categories as a module, so are not displayed 
    # on the applications list.
    assert_no_match /\/admin\/categories\/new/, @response.body
  end

  def test_should_show_add_links_in_resources_list_for_designer
    designer = typus_users(:designer)
    @request.session[:typus] = designer.id
    get :dashboard
    assert_no_match /\/admin\/posts\/new/, @response.body
    assert_no_match /\/admin\/typus_users\/new/, @response.body
  end

  def test_should_render_application_dashboard_template_extensions
    admin = typus_users(:admin)
    @request.session[:typus] = admin.id
    get :dashboard
    assert_response :success
    partials = %w( _sidebar.html.erb _top.html.erb _bottom.html.erb )
    partials.each { |p| assert_match p, @response.body }
  end

end