module AdminHelper

  include TypusHelper

  include AdminSidebarHelper
  include AdminFormHelper
  include AdminTableHelper

  def display_link_to_previous

    message = if params[:resource]
                t("You're adding a new {{resource_from}} to a {{resource_to}}.", :resource_from => @resource[:class_name].titleize, :resource_to => params[:resource].classify.titleize)
              else
                t("You're adding a new {{resource}}.", :resource => @resource[:class_name].titleize)
              end

    returning(String.new) do |html|
      html << <<-HTML
<div id="flash" class="notice">
<p>#{message} Do you want to cancel it? #{link_to "Click here", params[:back_to]}.</p>
</div>
      HTML
    end
  end

  ##
  # If there's a partial with a "microformat" of the data we want to 
  # display, this will be used, otherwise we use a default table which 
  # it's build from the options defined on the yaml configuration file.
  #
  def build_list(model, fields, items)
    template = "app/views/admin/#{@resource[:self]}/_#{@resource[:self].singularize}.html.erb"
    if File.exists?(template)
      render :partial => template.gsub('/_', '/'), :collection => @items, :as => :item
    else
      build_table(model, fields, items)
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