module AdminSidebarHelper

  def actions

    html = ""

    ##
    # Add
    #
    case params[:action]
    when 'index', 'edit', 'update'
      if @current_user.can_perform?(@model, 'create')
        html << <<-HTML
<ul>
<li>#{link_to "Add #{@model.name.titleize.downcase}", :action => 'new'}</li>
</ul>
        HTML
      end
    end

    ##
    # Edit, update ...
    #
    case params[:action]
    when 'edit', 'update'
      html << <<-HTML
<ul>
<li>#{link_to "Next", :id => @next.id if @next}</li>
<li>#{link_to "Previous", :id => @previous.id if @previous}</li>
</ul>
      HTML
    end

    ##
    # index, update, create
    #
    case params[:action]
    when 'new', 'create'
      html << <<-HTML
<ul>
<li>#{link_to "Back to list", :params => params.merge(:action => 'index')}</li>
</ul>
      HTML
    else
      html << more_actions
      html << block('parent_module')
      html << block('submodules')
    end

    html = "<h2>Actions</h2>\n#{html}" unless html.empty?
    return html

  end

  def more_actions
    html = ""
    @model.typus_actions_for(params[:action]).each do |action|
      if @current_user.can_perform?(@model, action)
        html << "<li>#{link_to action.titleize.capitalize, :action => action}</li>"
      end
    end
    html = "<ul>#{html}</ul>" unless html.empty?
    return html
  end

  def block(name)

    models = case name
             when 'parent_module': Typus.parent(@model.name, 'module')
             when 'submodules':    Typus.module(@model.name)
             else []
    end

    html = ""
    models.each do |m|
      model_cleaned = m.split(" ").join("").tableize
      html << "<li>#{link_to m, :controller => "admin/#{model_cleaned}"}</li>"
    end
    html = "<h2>#{name.humanize}</h2>\n<ul>#{html}</ul>" unless html.empty?

    return html

  end

  def search

    return "" if Typus::Configuration.config[@model.name]['search'].nil?

    search_params = params.dup
    %w( action controller search page ).each do |param|
      search_params.delete(param)
    end

    hidden_params = ""
    search_params.each do |key, value|
      hidden_params << "#{hidden_field_tag key, value}\n"
    end

    search = <<-HTML
<h2>Search</h2>
<form action="" method="get">
<p><input id="search" name="search" type="text" value="#{params[:search]}"/></p>
#{hidden_params}
</form>
<p style="margin: -10px 0px 10px 0px;"><small>Searching by #{Typus::Configuration.config[@model.name]['search'].split(', ').to_sentence(:skip_last_comma => true, :connector => '&').titleize.downcase}.</small></p>
    HTML

    return search

  end

  def filters
    current_request = request.env['QUERY_STRING'] || []
    if @model.typus_filters.size > 0
      html = ""
      @model.typus_filters.each do |f|
        html << "<h2>#{f[0].humanize}</h2>\n"
        case f[1]
        when 'boolean'
          html << "<ul>\n"
          %w( true false ).each do |status|
            switch = (current_request.include? "#{f[0]}=#{status}") ? 'on' : 'off'
            html << "<li>#{link_to status.capitalize, { :params => params.merge(f[0] => status, :page => nil) }, :class => switch}</li>\n"
          end
          html << "</ul>\n"
        when 'datetime'
          html << "<ul>\n"
          %w( today past_7_days this_month this_year ).each do |timeline|
            switch = (current_request.include? "#{f[0]}=#{timeline}") ? 'on' : 'off'
            html << "<li>#{link_to timeline.titleize, { :params => params.merge(f[0] => timeline, :page => nil) }, :class => switch}</li>\n"
          end
          html << "</ul>\n"
        when 'collection'
          model = f[0].capitalize.camelize.constantize
          related_fk = @model.reflect_on_association(f.first.to_sym).primary_key_name
          if !model.count.zero?
            ##
            # Here we have the option of having a selector.
            #
            # TODO
            #
            ##
            # Or having a simple list.
            #
            html << "<ul>\n"
            model.find(:all, :order => model.typus_order_by).each do |item|
              switch = (current_request.include? "#{related_fk}=#{item.id}") ? 'on' : 'off'
              html << "<li>#{link_to item.typus_name, { :params => params.merge(related_fk => item.id, :page => nil) }, :class => switch }</li>\n"
            end
            html << "</ul>\n"
          else
            html << "<p>No available #{model.name.downcase.pluralize}.</p>"
          end
        when 'string'
          values = @model.send(f[0])
          if !values.empty?
            html << "<ul>\n"
            values.each do |item|
              switch = current_request.include?("#{f[0]}=#{item}") ? 'on' : 'off'
              html << "<li>#{link_to item.capitalize, { :params => params.merge(f[0] => item) }, :class => switch }</li>\n"
            end
            html << "</ul>\n"
          else
            html << "<p>No available values.</p>"
          end
        else
          html << "<p>Unknown</p>"
        end
      end
    end
    return html
  end

end