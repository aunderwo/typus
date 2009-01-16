require File.dirname(__FILE__) + '/../test_helper'

class StringTest < Test::Unit::TestCase

  def test_should_verify_typus_actions_for
    assert "TypusUser".typus_actions_for('list').empty?
    assert "TypusUser".typus_actions_for(:list).empty?
  end

  def test_should_return_post_actions_on_index
    assert_equal %w( cleanup ), "Post".typus_actions_for('index')
    assert_equal %w( cleanup ), "Post".typus_actions_for(:index)
  end

  def test_should_return_post_actions_on_edit
    assert_equal %w( send_as_newsletter preview ), "Post".typus_actions_for('edit')
    assert_equal %w( send_as_newsletter preview ), "Post".typus_actions_for(:edit)
  end

end