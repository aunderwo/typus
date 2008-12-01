module TypusHelper

  ##
  # Applications list on the dashboard
  #
  def applications

    if Typus.applications.empty?
      return display_error("There are not defined applications in config/typus/*.yml")
    end

    html = ""

    Typus.applications.each do |app|

      available = []

      Typus.application(app).each do |resource|
        available << resource if @current_user.resources.include?(resource)
      end

      unless available.empty?

        html << <<-HTML
<table>
<tr>
  <th colspan="2">#{app}</th>
</tr>
        HTML

        available.each do |model|
          description = Typus.module_description(model)
          html << <<-HTML
<tr class=\"#{cycle('even', 'odd')}\">
<td>#{link_to model.titleize.pluralize, send("admin_#{model.tableize}_url")}<br /><small>#{description}</small></td>
<td class=\"right\"><small>
  #{link_to 'Add', send("admin_#{model.tableize}_url") if @current_user.can_perform?(model, 'create')}
</small></td>
</tr>
          HTML
        end

        html << <<-HTML
</table>
        HTML

      end

    end

    return html

  end

  ##
  # Resources (wich are not models) on the dashboard.
  #
  def resources

    available = []

    Typus.resources.each do |resource|
      available << resource if @current_user.resources.include?(resource)
    end

    unless available.empty?

      html = <<-HTML
<table>
<tr>
  <th colspan="2">Resources</th>
</tr>
      HTML

      available.each do |resource|
        html << <<-HTML
<tr class="#{cycle('even', 'odd')}">
  <td>#{link_to resource.titleize, "#{Typus::Configuration.options[:prefix]}/#{resource.underscore}"}</td>
  <td align="right" style="vertical-align: bottom;"></td>
</tr>
        HTML
      end

      html << <<-HTML
</table>
      HTML

    end

    return html rescue nil

  end

  def typus_block(name, location = nil)
    if location
      render :partial => "admin/#{location}/#{name}" rescue nil
    else
      render :partial => "admin/#{name}" rescue nil
    end
  end

  def display_error(error)
    "<div id=\"flash\" class=\"error\"><p>#{error}</p></div>"
  end

  def page_title
    crumbs = []
    crumbs << Typus::Configuration.options[:app_name]
    crumbs << @model.name.pluralize if @model
    crumbs << params[:action].titleize unless %w( index ).include?(params[:action])
    return crumbs.compact.map { |x| x }.join(" &rsaquo; ")
  end

  def header
    "<h1>#{Typus::Configuration.options[:app_name]} <small>#{link_to "View site", root_url, :target => 'blank' rescue ''}</small></h1>"
  end

  def login_info
    html = <<-HTML
<ul>
  <li>Logged as #{link_to @current_user.full_name(true), :controller => 'admin/typus_users', :action => 'edit', :id => @current_user.id}</li>
  <li>#{link_to "Logout", typus_logout_url}</li>
</ul>
    HTML
    return html
  end

  def display_flash_message
    flash_types = [ :error, :warning, :notice ]
    flash_type = flash_types.detect{ |a| flash.keys.include?(a) } || flash.keys.first
    if flash_type
      "<div id=\"flash\" class=\"%s\"><p>%s</p></div>" % [flash_type.to_s, flash[flash_type]]
    end
  end

  def display_error(error)
    log_error error
    "<div id=\"flash\" class=\"error\"><p>#{error}</p></div>"
  end

  ##
  #
  #
  def log_error(exception)
    ActiveSupport::Deprecation.silence do
        logger.fatal(
        "Typus Error:\n\n#{exception.class} (#{exception.message}):\n    " +
        exception.backtrace.join("\n    ") +
        "\n\n"
        )
    end
  end

end