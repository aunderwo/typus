require 'test/helper'

class TypusHelperTest < ActiveSupport::TestCase

  include TypusHelper
  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TextHelper
  include ActionController::UrlWriter

  def test_applications
    assert true
  end

  def test_resources
    assert true
  end

  def test_typus_block
    output = typus_block(:model => 'posts', :location => 'sidebar', :partial => 'pum')
    assert output.nil?
  end

  def test_page_title
    params = {}
    options = { :app_name => 'whatistypus.com' }
    Typus::Configuration.stubs(:options).returns(options)
    output = page_title('custom_action')
    assert_equal 'whatistypus.com &rsaquo; Custom action', output
  end

  def test_header

    output = header
    expected = <<-HTML
<h1>#{Typus::Configuration.options[:app_name]} </h1>
    HTML

    assert_equal expected, output

  end

  def test_display_flash_message

    message = { :test => 'This is the message.' }

    output = display_flash_message(message)
    expected = <<-HTML
<div id="flash" class="test">
  <p>This is the message.</p>
</div>
    HTML

    assert_equal expected, output

    message = {}
    output = display_flash_message(message)
    assert output.nil?

  end

  def test_typus_message
    output = typus_message('chunky bacon', 'yay')
    expected = <<-HTML
<div id="flash" class="yay">
  <p>chunky bacon</p>
</div>
    HTML
    assert_equal expected, output
  end

  def test_locales

    options = { :locales => [ [ "English", :en ], [ "Español", :es ] ] }
    Typus::Configuration.stubs(:options).returns(options)

    output = locales('set_locale')
    expected = <<-HTML
<ul>
<li>Set language:</li>
<li><a href="set_locale?locale=en">English</a></li>
<li><a href="set_locale?locale=es">Español</a></li>

</ul>
    HTML
    assert_equal expected, output

  end

end