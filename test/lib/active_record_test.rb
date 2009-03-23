require 'test/helper'

class ActiveRecordTest < ActiveSupport::TestCase

  def test_should_verify_model_fields_is_an_instance_of_active_support_ordered_hash
    assert TypusUser.model_fields.instance_of?(ActiveSupport::OrderedHash)
  end

  def test_should_return_model_fields_for_typus_user
    expected_fields = [[:id, :integer], 
                       [:first_name, :string], 
                       [:last_name, :string], 
                       [:roles, :string], 
                       [:email, :string], 
                       [:status, :boolean], 
                       [:token, :string], 
                       [:salt, :string], 
                       [:crypted_password, :string], 
                       [:created_at, :datetime], 
                       [:updated_at, :datetime]]
    assert_equal expected_fields.map { |i| i.first }, TypusUser.model_fields.keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.model_fields.values
  end

  def test_should_return_model_fields_for_post
    expected_fields = [[:id, :integer],
                       [:title, :string],
                       [:body, :text],
                       [:status, :boolean],
                       [:favorite_comment_id, :integer],
                       [:created_at, :datetime],
                       [:updated_at, :datetime],
                       [:published_at, :datetime]]
    assert_equal expected_fields.map { |i| i.first }, Post.model_fields.keys
    assert_equal expected_fields.map { |i| i.last }, Post.model_fields.values
  end

  def test_should_verify_model_relationships_is_an_instance_of_active_support_ordered_hash
    assert TypusUser.model_relationships.instance_of?(ActiveSupport::OrderedHash)
  end

  def test_should_return_model_relationships_for_post
    expected = [[:comments, :has_many],
                [:categories, :has_and_belongs_to_many],
                [:user, nil],
                [:assets, :has_many]]
    expected.each do |i|
      assert_equal i.last, Post.model_relationships[i.first]
    end
  end

  def test_should_return_typus_fields_for_list_for_typus_user
    expected_fields = [['email', :string], 
                       ['roles', :selector], 
                       ['status', :boolean]]
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for('list').keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for('list').values
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for(:list).keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for(:list).values
  end

  def test_should_return_typus_fields_for_list_for_post
    expected_fields = [['title', :string],
                       ['created_at', :datetime],
                       ['status', :selector]]
    assert_equal expected_fields.map { |i| i.first }, Post.typus_fields_for('list').keys
    assert_equal expected_fields.map { |i| i.last }, Post.typus_fields_for('list').values
    assert_equal expected_fields.map { |i| i.first }, Post.typus_fields_for(:list).keys
    assert_equal expected_fields.map { |i| i.last }, Post.typus_fields_for(:list).values
  end

  def test_should_return_typus_fields_for_form_for_typus_user
    expected_fields = [['first_name', :string], 
                       ['last_name', :string], 
                       ['roles', :selector], 
                       ['email', :string], 
                       ['password', :password], 
                       ['password_confirmation', :password]]
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for('form').keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for('form').values
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for(:form).keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for(:form).values
  end

  def test_should_return_typus_fields_for_a_model_without_configuration
    expected_fields = []
    klass = Class.new(ActiveRecord::Base)
    assert_equal expected_fields, klass.typus_fields_for(:form)
    assert_equal expected_fields, klass.typus_fields_for(:list)
  end

  def test_should_return_typus_fields_for_relationship_for_typus_user
    expected_fields = [['email', :string], 
                       ['roles', :selector], 
                       ['status', :boolean]]
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for('relationship').keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for('relationship').values
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for(:relationship).keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for(:relationship).values
  end

  def test_should_return_all_fields_for_undefined_field_type_on_typus_user
    expected_fields = [['email', :string], 
                       ['roles', :selector], 
                       ['status', :boolean]]
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for('undefined').keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for('undefined').values
    assert_equal expected_fields.map { |i| i.first }, TypusUser.typus_fields_for(:undefined).keys
    assert_equal expected_fields.map { |i| i.last }, TypusUser.typus_fields_for(:undefined).values
  end

  def test_should_return_filters_for_typus_user
    expected = [['status', :boolean], 
                ['roles', :string]]
    assert_equal 'status, roles', Typus::Configuration.config['TypusUser']['filters']
    assert_equal expected.map { |i| i.first }, TypusUser.typus_filters.keys
    assert_equal expected.map { |i| i.last }, TypusUser.typus_filters.values
  end

  def test_should_return_post_typus_filters
    expected = [['status', :boolean], 
                ['created_at', :datetime], 
                ['user', nil], 
                ['user_id', nil]]
    assert_equal expected.map { |i| i.first }.join(', '), Typus::Configuration.config['Post']['filters']
    assert_equal expected.map { |i| i.first }, Post.typus_filters.keys
    assert_equal expected.map { |i| i.last }, Post.typus_filters.values
  end

  def test_should_return_actions_on_list_for_typus_user
    assert TypusUser.typus_actions_for('list').empty?
    assert TypusUser.typus_actions_for(:list).empty?
  end

  def test_should_return_post_actions_on_index
    assert_equal %w( cleanup ), Post.typus_actions_for('index')
    assert_equal %w( cleanup ), Post.typus_actions_for(:index)
  end

  def test_should_return_post_actions_on_edit
    assert_equal %w( send_as_newsletter preview ), Post.typus_actions_for('edit')
    assert_equal %w( send_as_newsletter preview ), Post.typus_actions_for(:edit)
  end

  def test_should_return_field_options_for_post
    assert_equal [ :status ], Post.typus_field_options_for('selectors')
    assert_equal [ :status ], Post.typus_field_options_for(:selectors)
    assert_equal [ :permalink ], Post.typus_field_options_for('read_only')
    assert_equal [ :permalink ], Post.typus_field_options_for(:read_only)
    assert_equal [ :created_at ], Post.typus_field_options_for('auto_generated')
    assert_equal [ :created_at ], Post.typus_field_options_for(:auto_generated)
    assert_equal [ :status ], Post.typus_field_options_for('questions')
    assert_equal [ :status ], Post.typus_field_options_for(:questions)
  end

  def test_should_return_options_for_post_and_page

    assert_equal 10, Post.typus_options_for(:form_rows)
    assert_equal 10, Post.typus_options_for('form_rows')

    assert_equal 25, Page.typus_options_for(:form_rows)
    assert_equal 25, Page.typus_options_for('form_rows')

    assert_equal 10, Asset.typus_options_for(:form_rows)
    assert_equal 10, Asset.typus_options_for('form_rows')

    assert_equal 10, TypusUser.typus_options_for(:form_rows)
    assert_equal 10, TypusUser.typus_options_for('form_rows')

  end

  def test_should_verify_typus_boolean_is_an_instance_of_active_support_ordered_hash
    assert TypusUser.typus_boolean.instance_of?(ActiveSupport::OrderedHash)
  end

  def test_should_return_booleans_for_typus_users
    assert_equal [ :true, :false ], TypusUser.typus_boolean('status').keys
    assert_equal [ "Active", "Inactive" ], TypusUser.typus_boolean('status').values
    assert_equal [ :true, :false ], TypusUser.typus_boolean(:status).keys
    assert_equal [ "Active", "Inactive" ], TypusUser.typus_boolean(:status).values
  end

  def test_should_return_default_booleans_for_typus_users
    assert_equal [ :true, :false ], TypusUser.typus_boolean.keys
    assert_equal [ "True", "False" ], TypusUser.typus_boolean.values
  end

  def test_should_return_booleans_for_post
    assert_equal [ :true, :false ], Post.typus_boolean('status').keys
    assert_equal [ "True", "False" ], Post.typus_boolean('status').values
    assert_equal [ :true, :false ], Post.typus_boolean(:status).keys
    assert_equal [ "True", "False" ], Post.typus_boolean(:status).values
  end

  def test_should_return_date_formats_for_post
    assert_equal :post_short, Post.typus_date_format('created_at')
    assert_equal :post_short, Post.typus_date_format(:created_at)
    assert_equal :db, Post.typus_date_format
    assert_equal :db, Post.typus_date_format('unknown')
    assert_equal :db, Post.typus_date_format(:unknown)
  end

  def test_should_return_defaults_for_post
    assert_equal %w( title ), Post.typus_defaults_for('search')
    assert_equal %w( title ), Post.typus_defaults_for(:search)
    assert_equal %w( title -created_at ), Post.typus_defaults_for('order_by')
    assert_equal %w( title -created_at ), Post.typus_defaults_for(:order_by)
  end

  def test_should_return_relationships_for_post
    assert_equal %w( assets categories ), Post.typus_defaults_for('relationships')
    assert_equal %w( assets categories ), Post.typus_defaults_for(:relationships)
    assert !Post.typus_defaults_for('relationships').empty?
    assert !Post.typus_defaults_for(:relationships).empty?
  end

  def test_should_return_order_by_for_model
    assert_equal "`posts`.title ASC, `posts`.created_at DESC", Post.typus_order_by
    assert_equal %w( title -created_at ), Post.typus_defaults_for('order_by')
    assert_equal %w( title -created_at ), Post.typus_defaults_for(:order_by)
  end

  def test_should_return_sql_conditions_on_search_for_typus_user
    expected = "(LOWER(first_name) LIKE '%francesc%' OR LOWER(last_name) LIKE '%francesc%' OR LOWER(email) LIKE '%francesc%' OR LOWER(roles) LIKE '%francesc%')"
    params = { :search => 'francesc' }
    assert_equal expected, TypusUser.build_conditions(params).first
  end

  def test_should_return_sql_conditions_on_search_and_filter_for_typus_user_

    case ENV['DB']
    when /mysql|postgresql/
      boolean_true = "(`typus_users`.`status` = 1)"
      boolean_false = "(`typus_users`.`status` = 0)"
    else
      boolean_true = "(\"typus_users\".\"status\" = 't')"
      boolean_false = "(\"typus_users\".\"status\" = 'f')"
    end

    expected = "((LOWER(first_name) LIKE '%francesc%' OR LOWER(last_name) LIKE '%francesc%' OR LOWER(email) LIKE '%francesc%' OR LOWER(roles) LIKE '%francesc%')) AND #{boolean_true}"
    params = { :search => 'francesc', :status => 'true' }
    assert_equal expected, TypusUser.build_conditions(params).first
    params = { :search => 'francesc', :status => 'false' }
    assert_match /#{boolean_false}/, TypusUser.build_conditions(params).first

  end

  def test_should_return_sql_conditions_on_filtering_typus_users_by_status

    case ENV['DB']
    when /mysql|postgresql/
      boolean_true = "(`typus_users`.`status` = 1)"
      boolean_false = "(`typus_users`.`status` = 0)"
    else
      boolean_true = "(\"typus_users\".\"status\" = 't')"
      boolean_false = "(\"typus_users\".\"status\" = 'f')"
    end

    params = { :status => 'true' }
    assert_equal boolean_true, TypusUser.build_conditions(params).first
    params = { :status => 'false' }
    assert_equal boolean_false, TypusUser.build_conditions(params).first

  end

  def test_should_return_sql_conditions_on_filtering_typus_users_by_created_at

    expected = "(created_at BETWEEN '#{Time.today.to_s(:db)}' AND '#{Time.today.tomorrow.to_s(:db)}')"
    params = { :created_at => 'today' }
    assert_equal expected, TypusUser.build_conditions(params).first

    expected = "(created_at BETWEEN '#{6.days.ago.midnight.to_s(:db)}' AND '#{Time.today.tomorrow.to_s(:db)}')"
    params = { :created_at => 'past_7_days' }
    assert_equal expected, TypusUser.build_conditions(params).first

    expected = "(created_at BETWEEN '#{Time.today.last_month.to_s(:db)}' AND '#{Time.today.tomorrow.to_s(:db)}')"
    params = { :created_at => 'this_month' }
    assert_equal expected, TypusUser.build_conditions(params).first

    expected = "(created_at BETWEEN '#{Time.today.last_year.to_s(:db)}' AND '#{Time.today.tomorrow.to_s(:db)}')"
    params = { :created_at => 'this_year' }
    assert_equal expected, TypusUser.build_conditions(params).first

  end

  def test_should_return_sql_conditions_on_filtering_posts_by_published_at
    expected = "(published_at BETWEEN '#{Time.today.to_s(:db)}' AND '#{Time.today.tomorrow.to_s(:db)}')"
    params = { :published_at => 'today' }
    assert_equal expected, Post.build_conditions(params).first
  end

  def test_should_return_sql_conditions_on_filtering_posts_by_string
    expected = "(\"typus_users\".\"roles\" = 'admin')"
    params = { :roles => 'admin' }
    assert_equal expected, TypusUser.build_conditions(params).first
  end

  def test_should_verify_previous_and_next
    assert TypusUser.instance_methods.include?('previous_and_next')
    assert typus_users(:admin).previous_and_next.kind_of?(Array)
  end

  def test_should_verify_previous_and_next_works_without_conditions
    expected = [ typus_users(:admin), typus_users(:disabled_user) ]
    assert_equal expected, typus_users(:editor).previous_and_next
  end

  def test_should_verify_previous_and_next_works_with_conditions
    expected = [ typus_users(:editor), typus_users(:removed_role) ]
    conditions = { 'status' => 'true' }
    assert_equal expected, typus_users(:designer).previous_and_next(conditions)
  end

  def test_should_verify_typus_name_is_working_properly

    assert Category.new.respond_to?(:name)
    assert_equal 'First Category', categories(:first).typus_name

    assert !Page.new.respond_to?(:name)
    assert_equal 'Page#1', pages(:published).typus_name

    assert Comment.new.respond_to?(:name)
    assert_equal "John", comments(:first).typus_name

  end

  def test_should_verify_typus_template_is_working_properly

   assert_equal 'datepicker', Post.typus_template('published_at')
   assert_equal 'datepicker', Post.typus_template(:published_at)

   assert_equal nil, Post.typus_template('created_at')
   assert_equal nil, Post.typus_template('unknown')

  end

end