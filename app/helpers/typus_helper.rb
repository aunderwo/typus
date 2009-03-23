module TypusHelper

  ##
  # Applications list on the dashboard
  #
  def applications

    returning(String.new) do |html|

      Typus.applications.each do |app|

        available = Typus.application(app).map do |resource|
                      resource if @current_user.resources.include?(resource)
                    end
        next if available.compact.empty?

        html << <<-HTML
<table>
<tr>
<th colspan="2">#{app}</th>
</tr>
        HTML

        available.compact.each do |model|
          description = Typus.module_description(model)
          html << <<-HTML
<tr class="#{cycle('even', 'odd')}">
<td>#{link_to I18n.t(model.titleize.pluralize, :default => model.titleize.pluralize), send("admin_#{model.tableize}_path")}<br /><small>#{I18n.t(description, :default => "#{description}")}</small></td>
<td class="right"><small>
#{link_to I18n.t('Add', :default => 'Add'), send("new_admin_#{model.tableize.singularize}_path") if @current_user.can_perform?(model, 'create')}
</small></td>
</tr>
          HTML
        end

        html << <<-HTML
</table>
        HTML

      end

    end

  end

  ##
  # Resources (wich are not models) on the dashboard.
  #
  def resources

    available = Typus.resources.map do |resource|
                  resource if @current_user.resources.include?(resource)
                end
    return if available.compact.empty?

    returning(String.new) do |html|

      html << <<-HTML
<table>
<tr>
<th colspan="2">#{I18n.t('Resources')}</th>
</tr>
      HTML

      available.compact.each do |resource|

        html << <<-HTML
<tr class="#{cycle('even', 'odd')}">
<td>#{link_to I18n.t(resource.titleize, :default => resource.titleize), "#{Typus::Configuration.options[:path_prefix]}/#{resource.underscore}"}</td>
<td align="right" style="vertical-align: bottom;"></td>
</tr>
        HTML

      end

      html << <<-HTML
</table>
      HTML

    end

  end

  def typus_block(*args)

    options = args.extract_options!
    template = [ 'admin', options[:model], options[:location], "_#{options[:partial]}.html.erb" ].compact.join('/')

    exists = ActionController::Base.view_paths.map { |vp| File.exists?("#{Rails.root}/#{vp}/#{template}") }

    return unless exists.include?(true)
    render :partial => template.gsub('/_', '/')

  end

  def page_title(action = params[:action])
    crumbs = [ Typus::Configuration.options[:app_name] ]
    crumbs << @resource[:class_name_humanized].pluralize if @resource
    crumbs << I18n.t(action.humanize, :default => action.humanize) unless %w( index ).include?(action)
    return crumbs.compact.map { |x| x }.join(' &rsaquo; ')
  end

  def header

    if ActionController::Routing::Routes.named_routes.routes.keys.include?(:root)
      link_to_site = <<-HTML
<small>#{link_to I18n.t("View site"), root_path, :target => 'blank'}</small>
      HTML
    end

    html = <<-HTML
<h1>#{Typus::Configuration.options[:app_name]} #{link_to_site}</h1>
    HTML

    return html

  end

  def login_info(user = @current_user)
    <<-HTML
<ul>
  <li>#{I18n.t('Logged as')} #{link_to user.full_name(:display_role => true), edit_admin_typus_user_path(user.id)}</li>
  <li>#{link_to I18n.t('Sign out'), admin_sign_out_path }</li>
</ul>
    HTML
  end

  def display_flash_message(message = flash)

    return if message.empty?
    flash_type = message.keys.first

    <<-HTML
<div id="flash" class="#{flash_type}">
  <p>#{message[flash_type]}</p>
</div>
    HTML

  end

  def typus_message(message, html_class = 'notice')
    <<-HTML
<div id="flash" class="#{html_class}">
  <p>#{message}</p>
</div>
    HTML
  end

  def locales(uri = admin_set_locale_path)

    return unless Typus.locales.many?

    locales_link = Typus.locales.map do |locale|
                     <<-HTML
<li><a href="#{uri}?locale=#{locale.last}">#{locale.first}</a></li>
                     HTML
                   end

    html = <<-HTML
<ul>
<li>#{I18n.t("Set language", :default => "Set language")}:</li>
#{locales_link.join}
</ul>
    HTML

    return html

  end

end