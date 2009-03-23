require 'test/helper'

##
# Here we test position action if acts as list is installed.
#
class Admin::CategoriesControllerTest < ActionController::TestCase

  def setup
    user = typus_users(:editor)
    @request.session[:typus] = user.id
    @request.env['HTTP_REFERER'] = '/typus/categories'
  end

  def test_should_position_item_one_step_down
    return if !defined?(ActiveRecord::Acts::List)
    first_category = categories(:first)
    assert_equal 1, first_category.position
    second_category = categories(:second)
    assert_equal 2, second_category.position
    get :position, { :id => first_category.id, :go => 'move_lower' }
    assert flash[:success]
    assert_match /Record moved lower./, flash[:success]
    assert_equal 2, first_category.reload.position
    assert_equal 1, second_category.reload.position
  end

  def test_should_position_item_one_step_up
    return if !defined?(ActiveRecord::Acts::List)
    first_category = categories(:first)
    assert_equal 1, first_category.position
    second_category = categories(:second)
    assert_equal 2, second_category.position
    get :position, { :id => second_category.id, :go => 'move_higher' }
    assert flash[:success]
    assert_match /Record moved higher./, flash[:success]
    assert_equal 2, first_category.reload.position
    assert_equal 1, second_category.reload.position
  end

  def test_should_position_top_item_to_bottom
    return if !defined?(ActiveRecord::Acts::List)
    first_category = categories(:first)
    assert_equal 1, first_category.position
    get :position, { :id => first_category.id, :go => 'move_to_bottom' }
    assert flash[:success]
    assert_match /Record moved to bottom./, flash[:success]
    assert_equal 3, first_category.reload.position
  end

  def test_should_position_bottom_item_to_top
    return if !defined?(ActiveRecord::Acts::List)
    third_category = categories(:third)
    assert_equal 3, third_category.position
    get :position, { :id => third_category.id, :go => 'move_to_top' }
    assert flash[:success]
    assert_match /Record moved to top./, flash[:success]
    assert_equal 1, third_category.reload.position
  end

  def test_should_verify_items_are_sorted_by_position_on_list
    get :index
    assert_response :success
    assert_equal [ 1, 2, 3 ], assigns['items'].items.map(&:position)
    assert_equal [ 2, 3, 1 ], Category.find(:all).map(&:position)
  end

  def test_should_allow_admin_to_add_a_category
    admin = typus_users(:admin)
    @request.session[:typus] = admin.id
    assert admin.can_perform?('Category', 'create')
  end

  def test_should_not_allow_designer_to_add_a_category
    designer = typus_users(:designer)
    @request.session[:typus] = designer.id
    category = categories(:first)
    get :new
    assert_response :redirect
    assert flash[:notice]
    assert_equal 'Designer can\'t perform action (new)', flash[:notice]
    assert_redirected_to :action => :index
  end

  def test_should_allow_admin_to_destroy_a_category
    admin = typus_users(:admin)
    @request.session[:typus] = admin.id
    category = categories(:first)
    get :destroy, { :id => category.id }
    assert_response :redirect
    assert flash[:success]
    assert_match /Category successfully removed./, flash[:success]
    assert_redirected_to :action => :index
  end

  def test_should_not_allow_designer_to_destroy_a_category
    designer = typus_users(:designer)
    @request.session[:typus] = designer.id
    category = categories(:first)
    get :destroy, { :id => category.id, :method => :delete }
    assert_response :redirect
    assert flash[:notice]
    assert_match /Designer can't delete this item./, flash[:notice]
    assert_redirected_to :action => :index
  end

end