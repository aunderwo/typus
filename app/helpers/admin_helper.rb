module AdminHelper

  include TypusHelper

  include AdminSidebarHelper
  include AdminFormHelper
  include AdminTableHelper

  def display_link_to_previous(klass_name = @resource[:class_name], _params = params)

    options = {}
    options[:resource_from] = klass_name.titleize
    options[:resource_to] = _params[:resource].classify.titleize if _params[:resource]

    editing = %w( edit update ).include?(_params[:action])

    message = case
              when _params[:resource] && editing
                I18n.t("You're updating a {{resource_from}} for {{resource_to}}", options)
              when editing
                I18n.t("You're updating a {{resource_from}}", options)
              when _params[:resource]
                I18n.t("You're adding a new {{resource_from}} to {{resource_to}}", options)
              else
                I18n.t("You're adding a new {{resource_from}}", options)
              end

    returning(String.new) do |html|
      html << <<-HTML
<div id="flash" class="notice">
  <p>#{message} #{link_to(I18n.t("Do you want to cancel it?"), _params[:back_to])}</p>
</div>
      HTML
    end

  end

  def remove_filter_link(filter = request.env['QUERY_STRING'])
    return unless filter && !filter.blank?
    <<-HTML
<small>#{link_to t("Remove filter")}</small>
    HTML
  end

  ##
  # If there's a partial with a "microformat" of the data we want to 
  # display, this will be used, otherwise we use a default table which 
  # it's build from the options defined on the yaml configuration file.
  #
  def build_list(model, fields, items, resource = @resource[:self], link_options = {})

    template = "app/views/admin/#{resource}/_#{resource.singularize}.html.erb"

    if File.exists?(template)
      render :partial => template.gsub('/_', '/'), :collection => items, :as => :item
    else
      build_typus_table(model, fields, items, link_options)
    end

  end

  ##
  # Simple and clean pagination links
  #
  def build_pagination(pager, options = {})

    options[:link_to_current_page] ||= true
    options[:always_show_anchors] ||= true

    # Calculate the window start and end pages
    options[:padding] ||= 2
    options[:padding] = options[:padding] < 0 ? 0 : options[:padding]

    page = params[:page].blank? ? 1 : params[:page].to_i
    current_page = pager.page(page)

    first = pager.first.number <= (current_page.number - options[:padding]) && pager.last.number >= (current_page.number - options[:padding]) ? current_page.number - options[:padding] : 1
    last = pager.first.number <= (current_page.number + options[:padding]) && pager.last.number >= (current_page.number + options[:padding]) ? current_page.number + options[:padding] : pager.last.number

    returning(String.new) do |html|
      # Print start page if anchors are enabled
      html << yield(1) if options[:always_show_anchors] and not first == 1
      # Print window pages
      first.upto(last) do |page|
        (current_page.number == page && !options[:link_to_current_page]) ? html << page.to_s : html << (yield(page)).to_s
      end
      # Print end page if anchors are enabled
      html << yield(pager.last.number).to_s if options[:always_show_anchors] and not last == pager.last.number
    end

  end

end