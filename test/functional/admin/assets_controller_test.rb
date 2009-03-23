require 'test/helper'

##
# Here we test polimorphic relationships using the relate & unrelate 
# actions.
#
class Admin::AssetsControllerTest < ActionController::TestCase

  def setup
    typus_user = typus_users(:admin)
    @request.session[:typus] = typus_user.id
  end

  def test_should_test_polymorphic_relationship_message
    post_ = posts(:published)
    get :new, { :back_to => "/admin/posts/#{post_.id}/edit", :resource => post_.class.name, :resource_id => post_.id }
    assert_match 'You\'re adding a new Asset to Post.', @response.body
  end

  def test_should_create_a_polymorphic_relationship

    post_ = posts(:published)

    assert_difference('post_.assets.count') do
      post :create, { :back_to => "/admin/posts/#{post_.id}/edit", :resource => post_.class.name, :resource_id => post_.id }
    end

    assert_response :redirect
    assert_redirected_to '/admin/posts/1/edit#assets'
    assert flash[:success]
    assert_equal 'Asset successfully assigned to Post.', flash[:success]

  end

  def test_should_test_polymorphic_relationship_edit_message
    post_ = posts(:published)
    asset_ = assets(:first)
    get :edit, { :id => asset_.id, :back_to => "/admin/posts/#{post_.id}/edit", :resource => post_.class.name, :resource_id => post_.id }
    assert_match 'You\'re updating a Asset for Post.', @response.body
  end

  def test_should_return_to_back_to_url

    options = Typus::Configuration.options.merge(:edit_after_create => false)
    Typus::Configuration.stubs(:options).returns(options)

    post_ = posts(:published)
    asset_ = assets(:first)

    post :update, { :back_to => "/admin/posts/#{post_.id}/edit", :resource => post_.class.name, :resource_id => post_.id, :id => asset_.id }
    assert_response :redirect
    assert_redirected_to '/admin/posts/1/edit#assets'
    assert flash[:success]
    assert_equal 'Asset successfully updated.', flash[:success]

  end

end