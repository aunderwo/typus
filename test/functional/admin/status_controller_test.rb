require 'test/helper'

##
# Here we test resources which are not related to an ActiveRecord model.
#
class Admin::StatusControllerTest < ActionController::TestCase

  def setup
    @typus_user = typus_users(:admin)
    @request.session[:typus] = @typus_user.id
  end

  def test_should_verify_admin_can_go_to_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_should_verify_status_is_not_available_if_user_not_logged
    @request.session[:typus] = nil
    get :index
    assert_response :redirect
    assert_redirected_to admin_sign_in_path(:back_to => '/typus/status')
  end

  def test_should_verify_admin_can_not_go_to_show
    get :show
    assert_response :redirect
    assert_redirected_to admin_dashboard_path
    assert flash[:notice]
    assert_match /#{@typus_user.roles.capitalize} can't go to show on status./, flash[:notice]
  end

  def test_should_verify_editor_can_not_go_to_index
    typus_user = typus_users(:editor)
    @request.session[:typus] = typus_user.id
    get :index
    assert_response :redirect
    assert flash[:notice]
    assert_match /#{typus_user.roles.capitalize} can't go to index on status./, flash[:notice]
  end

end