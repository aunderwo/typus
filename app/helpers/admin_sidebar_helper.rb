module AdminSidebarHelper

  def actions

    returning(String.new) do |html|

      html << <<-HTML
#{build_my_list(default_actions, 'actions')}
#{build_my_list(previous_and_next, 'go_to')}
      HTML

      %w( parent_module submodules ).each do |block|
        html << <<-HTML
#{build_my_list(modules(block), block)}
        HTML
      end

    end

  end

  def default_actions

    returning(Array.new) do |items|

      case params[:action]
      when 'index', 'edit', 'update'
        if @current_user.can_perform?(@resource[:class], 'create')
          items << "<li>#{link_to t("Add entry"), :action => 'new'}</li>"
        end
      end

      items << non_crud_actions

      case params[:action]
      when 'new', 'create', 'edit', 'update'
        items << "<li>#{link_to t("Back to list"), :action => 'index'}</li>"
      end

    end

  end

  def non_crud_actions
    returning(Array.new) do |actions|
      @resource[:class].typus_actions_for(params[:action]).each do |action|
        if @current_user.can_perform?(@resource[:class], action)
          actions << "<li>#{link_to action.titleize.capitalize, :action => action}</li>"
        end
      end
    end
  end

  def build_my_list(items, header = nil)
    return "" if items.empty?
    returning(String.new) do |html|
      html << "<h2>#{t(header.humanize)}</h2>" unless header.nil?
      html << <<-HTML
<ul>
  #{items.join("\n")}
</ul>
      HTML
    end
  end

  def modules(name)

    models = case name
             when 'parent_module': Typus.parent(@resource[:class_name], 'module')
             when 'submodules':    Typus.module(@resource[:class_name])
             end

    return [] if models.empty?

    returning(Array.new) do |items|
      models.each do |model|
        items << "<li>#{link_to model.titleize.capitalize, :controller => model.tableize}</li>"
      end
    end

  end

  def previous_and_next
    return [] unless %w( edit update ).include?(params[:action])
    returning(Array.new) do |items|
      items << "<li>#{link_to t("Next"), :action => 'edit', :id => @next.id}</li>" if @next
      items << "<li>#{link_to t("Previous"), :action => 'edit', :id => @previous.id}</li>" if @previous
    end
  end

  def search

    typus_search = Typus::Configuration.config[@resource[:class_name]]['search']
    return if typus_search.nil?

    search_params = params.dup
    %w( action controller search page ).each { |p| search_params.delete(p) }

    hidden_params = []
    search_params.each { |key, value| hidden_params << hidden_field_tag(key, value) }

    returning(String.new) do |html|
      html << <<-HTML
<h2>#{t("Search")}</h2>
<form action="" method="get">
<p><input id="search" name="search" type="text" value="#{params[:search]}"/></p>
#{hidden_params.join("\n")}
</form>
<p style="margin: -10px 0px 10px 0px;"><small>#{t("Search by")} #{typus_search.split(', ').to_sentence(:skip_last_comma => true, :connector => '&').titleize.downcase}.</small></p>
      HTML
    end

  end

  def filters

    typus_filters = @resource[:class].typus_filters
    return if typus_filters.empty?

    current_request = request.env['QUERY_STRING'] || []

    returning(String.new) do |html|
      typus_filters.each do |key, value|
        html << "<h2>#{t(key.humanize)}</h2>\n"
        case value
        when :boolean:      html << boolean_filter(current_request, key)
        when :string:       html << string_filter(current_request, key)
        when :datetime:     html << datetime_filter(current_request, key)
        when :belongs_to:   html << relationship_filter(current_request, key)
        when :has_and_belongs_to_many:
          html << relationship_filter(current_request, key, true)
        else
          html << "<p>Unknown</p>"
        end
      end
    end

  end

  def relationship_filter(request, filter, habtm = false)

    if habtm
      model = filter.classify.constantize
      related_fk = filter
    else
      model = filter.capitalize.camelize.constantize
      related_fk = @resource[:class].reflect_on_association(filter.to_sym).primary_key_name
    end

    params_without_filter = params.dup
    %w( controller action page ).each { |p| params_without_filter.delete(p) }
    params_without_filter.delete(related_fk)

    returning(String.new) do |html|
      html << "<p>No available #{model.name.titleize.pluralize.downcase}.</p>" and next if model.count.zero?
      related_items = model.find(:all, :order => model.typus_order_by)
      if related_items.size > Typus::Configuration.options[:sidebar_selector]
        items = []
        related_items.each do |item|
          switch = request.include?("#{related_fk}=#{item.id}") ? 'selected' : ''
          items << "<option #{switch} value=\"#{url_for params.merge(related_fk => item.id, :page => nil)}\">#{item.typus_name}</option>"
        end
        html << <<-HTML
<!-- Embedded JS -->
<script>
function surfto_#{model.name.downcase.pluralize}(form) {
  var myindex = form.#{model.name.downcase.pluralize}.selectedIndex
  if (form.#{model.name.downcase.pluralize}.options[myindex].value != "0") {
    top.location.href = form.#{model.name.downcase.pluralize}.options[myindex].value;
  }
}
</script>
<!-- /Embedded JS -->
<p><form class="form" action="#">
  <select name="#{model.name.downcase.pluralize}" onChange="surfto_#{model.name.downcase.pluralize}(this.form)">
    <option value=\"#{url_for params_without_filter}\">Filter by #{model.name.titleize.humanize}</option>
    #{items.join("\n")}
  </select>
</form></p>
        HTML
      else
        items = []
        related_items.each do |item|
          switch = request.include?("#{related_fk}=#{item.id}") ? 'on' : 'off'
          items << "<li>#{link_to item.typus_name, { :params => params.merge(related_fk => item.id, :page => nil) }, :class => switch}</li>"
        end
        html << <<-HTML
<ul>
#{items.join("\n")}
</ul>
        HTML
      end
    end
  end

  def datetime_filter(request, filter)
    returning(String.new) do |html|
      items = []
      %w( today past_7_days this_month this_year ).each do |timeline|
        switch = request.include?("#{filter}=#{timeline}") ? 'on' : 'off'
        items << "<li>#{link_to timeline.titleize, { :params => params.merge(filter => timeline, :page => nil) }, :class => switch}</li>"
      end
      html << <<-HTML
<ul>
#{items.join("\n")}
</ul>
      HTML
    end
  end

  def boolean_filter(request, filter)
    returning(String.new) do |html|
      items = []
      @resource[:class].typus_boolean(filter).each do |key, value|
        switch = request.include?("#{filter}=#{key}") ? 'on' : 'off'
        items << "<li>#{link_to value, { :params => params.merge(filter => key, :page => nil) }, :class => switch}</li>"
      end
      html << <<-HTML
<ul>
#{items.join("\n")}
</ul>
      HTML
    end
  end

  def string_filter(request, filter)
    values = @resource[:class].send(filter)
    returning(String.new) do |html|
      unless values.empty?
        items = []
        values.each do |item|
          switch = request.include?("#{filter}=#{item}") ? 'on' : 'off'
          items << "<li>#{link_to item.capitalize, { :params => params.merge(filter => item, :page => nil) }, :class => switch}</li>"
        end
        html << <<-HTML
<ul>
#{items.join("\n")}
</ul>
        HTML
      else
        html << "<p>No available #{filter}.</p>"
      end
    end
  end

end