require 'test/helper'

class AdminPublicHelperTest < ActiveSupport::TestCase

  include AdminPublicHelper

  def test_quick_edit

    options = { :color => 'CC0000', :link => 'quick_edit', :resource => 'posts', :id => '1', :action => 'edit' }
    output = quick_edit(options)

    html = <<-HTML
<script type="text/javascript">
  document.write('<script type="text/javascript" src="quick_edit?action=edit&id=1&resource=posts" />');
</script>
    HTML

    assert_equal html, output

  end

end