require File.dirname(__FILE__) + '/../test_helper'

class TypusUserTest < ActiveSupport::TestCase

  def setup
    @data = { :first_name => "", 
              :last_name => "", 
              :email => "test@example.com", 
              :password => "12345678", 
              :password_confirmation => "12345678", 
              :roles => Typus::Configuration.options[:root] }
    @typus_user = TypusUser.new(@data)
  end

  def test_should_verify_typus_user_attributes
    %w( first_name last_name email roles salt crypted_password ).each do |attribute|
      assert TypusUser.instance_methods.include?(attribute)
    end
  end

  def test_should_verify_email_format
    @typus_user.email = 'admin'
    assert !@typus_user.valid?
    assert @typus_user.errors.invalid?(:email)
  end

  def test_should_verify_email_is_not_valid
    email = <<-END
this_is_chelm@example.com
<script>location.href="http://spammersite.com"</script>
END
    @typus_user.email = email
    assert !@typus_user.valid?
    assert @typus_user.errors.invalid?(:email)
  end

  def test_should_verify_email_is_unique
    @typus_user.save
    @another_typus_user = TypusUser.new(@data)
    assert !@another_typus_user.valid?
    assert @another_typus_user.errors.invalid?(:email)
  end

  def test_should_verify_length_of_password_when_under_within
    @typus_user.password = '1234'
    @typus_user.password_confirmation = '1234'
    assert !@typus_user.valid?
    assert @typus_user.errors.invalid?(:password)
  end

  def test_should_verify_length_of_password_when_its_within_on_lower_limit
    @typus_user.password = "=" * 8
    @typus_user.password_confirmation = "=" * 8
    assert @typus_user.valid?
  end

  def test_should_verify_length_of_password_when_its_within_on_upper_limit
    @typus_user.password = "=" * 40
    @typus_user.password_confirmation = "=" * 40
    assert @typus_user.valid?
  end

  def test_should_verify_length_of_password_when_its_over_within
    @typus_user.password = "=" * 50
    @typus_user.password_confirmation = "=" * 50
    assert !@typus_user.valid?
    assert @typus_user.errors.invalid?(:password)
  end

  def test_should_verify_confirmation_of_password
    @typus_user.password = "12345678"
    @typus_user.password_confirmation = "87654321"
    assert !@typus_user.valid?
    assert @typus_user.errors.invalid?(:password)
  end

  def test_should_return_full_name
    assert "#{@typus_user.email} (#{@typus_user.roles})", @typus_user.full_name(:display_role => true)
    assert "#{@typus_user.email}", @typus_user.full_name
  end

  def test_should_return_full_name_with_role
    @typus_user.first_name = "John"
    @typus_user.last_name = "Smith"
    assert "John Smith (#{@typus_user.roles})", @typus_user.full_name(:display_role => true)
    assert "John Smith", @typus_user.full_name
  end

  def test_should_return_verify_is_root
    assert @typus_user.is_root?
    editor = typus_users(:editor)
    assert !editor.is_root?
  end

end