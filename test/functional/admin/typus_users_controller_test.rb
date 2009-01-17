require File.dirname(__FILE__) + '/../../test_helper'

##
# Here we test what the TypusUsers can do.
#
class Admin::TypusUsersControllerTest < ActionController::TestCase

  def setup
    Typus::Configuration.options[:root] = 'admin'
    @typus_user = typus_users(:admin)
    @request.session[:typus] = @typus_user.id
  end

  def test_should_allow_admin_to_create_typus_users
    get :new
    assert_response :success
  end

  def test_should_not_allow_admin_to_toggle_her_status

    @request.env['HTTP_REFERER'] = "/admin/typus_users"
    get :toggle, { :id => @typus_user.id, :field => 'status' }

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /You can't toggle your status./, flash[:notice]

  end

  def test_should_allow_admin_to_toggle_other_users_status

    @request.env['HTTP_REFERER'] = "/admin/typus_users"
    editor = typus_users(:editor)
    get :toggle, { :id => editor.id, :field => 'status' }

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:success]
    assert_match /Typus User status changed./, flash[:success]

  end

  def test_should_not_allow_non_root_typus_user_to_toggle_status

    @request.env['HTTP_REFERER'] = "/admin/typus_users"
    @typus_user = typus_users(:editor)
    @request.session[:typus] = @typus_user.id
    get :toggle, { :id => @typus_user.id, :field => 'status' }

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /You're not allowed to toggle status./, flash[:notice]

  end

  def test_should_verify_admin_cannot_destroy_herself

    @request.env['HTTP_REFERER'] = "/admin/typus_users"

    assert_difference('TypusUser.count', 0) do
      delete :destroy, :id => @typus_user.id
    end

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /You can't remove yourself./, flash[:notice]

  end

  def test_should_verify_admin_can_destroy_others

    @request.env['HTTP_REFERER'] = "/admin/typus_users"

    assert_difference('TypusUser.count', -1) do
      delete :destroy, :id => typus_users(:editor).id
    end

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:success]
    assert_match /Typus User successfully removed./, flash[:success]

  end

  def test_should_not_allow_editor_to_create_typus_users

    @request.env['HTTP_REFERER'] = "/admin/typus_users"
    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    get :new

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_equal "Editor can't perform action. (new)", flash[:notice].to_s

  end

  def test_should_allow_editor_to_update_himself

    Typus::Configuration.options[:edit_after_create] = true
    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    @request.env['HTTP_REFERER'] = "/admin/typus_users/#{typus_user.id}/edit"
    get :edit, { :id => typus_user.id }

    assert_response :success
    assert_equal 'editor', typus_user.roles

    post :update, { :id => typus_user.id, 
                    :item => { :first_name => "Richard", 
                               :last_name => "Ashcroft", 
                               :roles => "editor" } }

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:success]
    assert_match /Typus User successfully updated./, flash[:success]

  end

  def test_should_not_allow_editor_to_update_himself_to_become_admin

    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    @request.env['HTTP_REFERER'] = "/admin/typus_users/#{typus_user.id}/edit"

    assert_equal 'editor', typus_user.roles

    post :update, { :id => typus_user.id, 
                    :item => { :roles => 'admin' } }

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /You can't change your role./, flash[:notice]

  end

  def test_should_not_allow_editor_to_edit_other_users_profiles

    @request.env['HTTP_REFERER'] = "/admin/typus_users"
    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    get :edit, { :id => typus_user.id }

    assert_response :success
    assert_template 'edit'

    get :edit, { :id => typus_users(:admin).id }

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /As you're not the admin or the owner of this record you cannot edit it./, flash[:notice]

  end

  def test_should_not_allow_editor_to_destroy_users

    @request.env['HTTP_REFERER'] = "/admin/typus_users"
    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    delete :destroy, :id => typus_users(:admin).id

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /You're not allowed to remove Typus Users./, flash[:notice]

  end

  def test_should_not_allow_editor_to_destroy_herself

    @request.env['HTTP_REFERER'] = "/admin/typus_users"
    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    delete :destroy, :id => typus_user.id

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /You're not allowed to remove Typus Users./, flash[:notice]

  end

  def test_should_redirect_to_typus_dashboard_if_user_does_not_have_privileges

    @request.env['HTTP_REFERER'] = "/admin"
    typus_user = typus_users(:designer)
    @request.session[:typus] = typus_user.id
    get :index

    assert_response :redirect
    assert_redirected_to @request.env['HTTP_REFERER']
    assert flash[:notice]
    assert_match /Designer can't display items./, flash[:notice]

  end

  def test_should_change_root_to_editor_so_editor_can_edit_others_content

    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    @request.env['HTTP_REFERER'] = "/admin/typus_users"

    assert_equal 'editor', typus_user.roles

    get :edit, :id => typus_user.id
    assert_response :success

    get :edit, :id => typus_users(:admin).id
    assert_response :redirect
    assert_redirected_to @request.env["HTTP_REFERER"]
    assert flash[:notice]
    assert_match /As you're not the admin or the owner of this record you cannot edit it./, flash[:notice]

    ##
    # Here we change the behavior, editor has become root, so he 
    # has access to all TypusUser records.
    #

    Typus::Configuration.options[:root] = 'editor'

    get :edit, :id => typus_user.id
    assert_response :success

    get :edit, :id => typus_users(:admin).id
    assert_response :success

  end

end