require File.dirname(__FILE__) + '/../test_helper'

class TypusTest < Test::Unit::TestCase

  def test_should_verify_models
    assert Category.kind_of?(Class)
    assert Comment.kind_of?(Class)
    assert Post.kind_of?(Class)
    assert TypusUser.kind_of?(Class)
  end

  def test_should_verify_fixtures_are_loaded
    assert_equal 3, Category.count
    assert_equal 2, Comment.count
    assert_equal 2, Post.count
    assert_equal 5, TypusUser.count
  end

end