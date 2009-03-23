module AdminPublicHelper

  ##
  #
  #
  def quick_edit(*args)

    options = args.extract_options!
    options[:color] ||= '#000'
    options[:link] ||= admin_quick_edit_path

    query = options.dup
    [ :color, :link ].each { |o| query.delete(o) }

    <<-HTML
<script type="text/javascript">
  document.write('<script type="text/javascript" src="#{options[:link]}?#{query.to_query}" />');
</script>
    HTML

  end

end