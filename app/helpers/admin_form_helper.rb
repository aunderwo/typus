module AdminFormHelper

  ##
  # All helpers related to form.
  #

  def build_form(fields)
    returning(String.new) do |html|
      html << "#{error_messages_for :item, :header_tag => "h3"}"
      html << "<ul>"
      fields.each do |key, value|

        attribute = key
        attribute_humanized = t(key.titleize.capitalize)

        case value
        when :belongs_to:      html << typus_belongs_to_field(attribute)
        when :boolean:         html << typus_boolean_field(attribute, attribute_humanized)
        when :date:            html << typus_date_field(attribute, attribute_humanized)
        when :datetime:        html << typus_datetime_field(attribute, attribute_humanized)
        when :file:            html << typus_file_field(attribute, attribute_humanized)
        when :password:        html << typus_password_field(attribute, attribute_humanized)
        when :selector:        html << typus_selector_field(attribute, attribute_humanized)
        when :text:            html << typus_text_field(attribute, attribute_humanized)
        when :time:            html << typus_time_field(attribute, attribute_humanized)
        when :tree:            html << typus_tree_field(attribute)
        else
          html << typus_string_field(attribute, attribute_humanized)
        end
      end
      html << "</ul>"
    end
  end

  def typus_belongs_to_field(attribute)

    ##
    # We only can pass parameters to 'new' and 'edit', so this hack makes
    # the work to replace the current action.
    #
    params[:action] = (params[:action] == 'create') ? 'new' : params[:action]
    back_to = "/" + ([] << params[:controller] << params[:id] << params[:action]).compact.join('/')

    related = @resource[:class].reflect_on_association(attribute.to_sym).class_name.constantize
    related_fk = @resource[:class].reflect_on_association(attribute.to_sym).primary_key_name

    message = []
    message << "Are you sure you want to leave this page?"
    message << "If you have made any changes to the fields without clicking the Save/Update entry button, your changes will be lost."
    message << "Click OK to continue, or click Cancel to stay on this page."

    returning(String.new) do |html|

      if related.respond_to?('roots')
        html << typus_tree_field(related_fk, related.roots, related_fk)
      else
        html << <<-HTML
<li><label for="item_#{attribute}">#{related_fk.humanize}
    <small>#{link_to t("Add new"), { :controller => attribute.tableize, :action => 'new', :back_to => back_to, :selected => related_fk }, :confirm => message.join("\n\n") if @current_user.can_perform?(related, 'create')}</small>
    </label>
#{select :item, related_fk, related.find(:all, :order => related.typus_order_by).collect { |p| [p.typus_name, p.id] }, { :include_blank => true }, { :disabled => attribute_disabled?(attribute) } }</li>
        HTML
      end

    end

  end

  def typus_boolean_field(attribute, attribute_humanized)

    question = true if @resource[:class].typus_field_options_for(:questions).include?(attribute)

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized}#{'?' if question}</label>
#{check_box :item, attribute} #{t("Checked if active")}</li>
      HTML
    end

  end

  def typus_date_field(attribute, attribute_humanized)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized}</label>
#{date_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end
  end

  def typus_datetime_field(attribute, attribute_humanized)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized}</label>
#{datetime_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end
  end

  def typus_file_field(attribute, attribute_humanized)

    attribute_display = attribute.split("_file_name").first
    content_type = @item.send("#{attribute_display}_content_type")

    returning(String.new) do |html|

      if @item.respond_to?('preview') && !params[:action].include?('new')

        preview_link = <<-HTML
<small><a href="##{@item.class.name}-#{@item.id}-zoom" id="#{@item.class.name}-#{@item.id}">Preview</a></small>
        HTML

        preview_content = <<-HTML
<div id="#{@item.class.name}-#{@item.id}-zoom">
  #{@item.display}
</div>
        HTML

      end

      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_display.titleize.capitalize} #{preview_link}</label>
      HTML

      html << preview_content unless preview_content.nil?

      html << "#{file_field :item, attribute.split("_file_name").first, :disabled => attribute_disabled?(attribute)}</li>"

    end

  end

  def typus_password_field(attribute, attribute_humanized)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized}</label>
#{password_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute)}</li>
      HTML
    end
  end

  def typus_selector_field(attribute, attribute_humanized)
    returning(String.new) do |html|
      options = []
      @resource[:class].send(attribute).each do |option|
        case option.kind_of?(Array)
        when true
          options << <<-HTML
<option #{'selected' if @item.send(attribute).to_s == option.last.to_s} value="#{option.last}">#{option.first}</option>
          HTML
        else
          options << <<-HTML
<option #{'selected' if @item.send(attribute).to_s == option.to_s} value="#{option}">#{option}</option>
          HTML
        end
      end
      html << <<-HTML
<li><label for=\"item_#{attribute}\">#{attribute_humanized}</label>
<select id="item_#{attribute}" #{attribute_disabled?(attribute) ? 'disabled="disabled"' : ''} name="item[#{attribute}]">
  <option value=""></option>
  #{options.join("\n")}
</select></li>
      HTML
    end
  end

  def typus_text_field(attribute, attribute_humanized)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized}</label>
#{text_area :item, attribute, :class => 'text', :rows => Typus::Configuration.options[:form_rows], :disabled => attribute_disabled?(attribute)}</li>
      HTML
    end
  end

  def typus_time_field(attribute, attribute_humanized)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized}</label>
#{time_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end
  end

  def typus_tree_field(attribute, items = @resource[:class].roots, attribute_virtual = 'parent_id')
    returning(String.new) do |html|
      html << <<-HTML
<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>
<select id="item_#{attribute}" #{attribute_disabled?(attribute) ? 'disabled="disabled"' : ''} name="item[#{attribute}]">
  <option value=""></option>
  #{expand_tree_into_select_field(items, attribute_virtual)}
</select></li>
      HTML
    end
  end

  def typus_string_field(attribute, attribute_humanized)

    # Read only fields.
    if @resource[:class].typus_field_options_for(:read_only).include?(attribute)
      value = 'read_only' if %w( edit ).include?(params[:action])
    end

    # Auto generated fields.
    if @resource[:class].typus_field_options_for(:auto_generated).include?(attribute)
      value = 'auto_generated' if %w( new edit ).include?(params[:action])
    end

    comment = %w( read_only auto_generated ).include?(value) ? (value + " field").titleize : ""

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_humanized} <small>#{comment}</small></label>
#{text_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute) }</li>
      HTML
    end

  end

  def typus_relationships

    @back_to = "/" + ([] << params[:controller] << params[:id]<< params[:action]).compact.join('/')

    returning(String.new) do |html|
      @item_relationships.each do |relationship|
        case @resource[:class].reflect_on_association(relationship.to_sym).macro
        when :has_many
          html << typus_form_has_many(relationship)
        when :has_and_belongs_to_many
          html << typus_form_has_and_belongs_to_many(relationship)
        end
      end
    end

  end

  def typus_form_has_many(field)
    returning(String.new) do |html|
      model_to_relate = model_to_relate = @resource[:class].reflect_on_association(field.to_sym).class_name.constantize
      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to field.titleize, :controller => field}
  <small>#{link_to t("Add new"), :controller => field, :action => 'new', :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id if @current_user.can_perform?(model_to_relate, 'create')}</small>
  </h2>
      HTML
      items = @resource[:class].find(params[:id]).send(field)
      unless items.empty?
        html << build_table(model_to_relate, model_to_relate.typus_fields_for(:relationship), items)
      else
        html << <<-HTML
<div id="flash" class="notice"><p>#{t("There are no {{records}}.", :records => field.titleize.downcase)}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def typus_form_has_and_belongs_to_many(field)
    returning(String.new) do |html|
      model_to_relate = model_to_relate = @resource[:class].reflect_on_association(field.to_sym).class_name.constantize
      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to field.titleize, :controller => field}
  <small>#{link_to t("Add new"), :controller => field, :action => 'new', :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id if @current_user.can_perform?(model_to_relate, 'create')}</small>
  </h2>
      HTML
      items_to_relate = (model_to_relate.find(:all) - @item.send(field))
      unless items_to_relate.empty?
        html << <<-HTML
  #{form_tag :action => 'relate'}
  #{hidden_field :related, :model, :value => model_to_relate}
  <p>#{ select :related, :id, items_to_relate.collect { |f| [f.typus_name, f.id] }.sort_by { |e| e.first } } &nbsp; #{submit_tag "Add", :class => 'button'}</p>
  </form>
        HTML
      end
      items = @resource[:class].find(params[:id]).send(field)
      unless items.empty?
        html << build_table(model_to_relate, model_to_relate.typus_fields_for(:relationship), items)
      else
        html << <<-HTML
  <div id="flash" class="notice"><p>#{t("There are no {{records}}.", :records => field.titleize.downcase)}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def attribute_disabled?(attribute)
    if @resource[:class].accessible_attributes.nil?
      return false
    else
      return !@resource[:class].accessible_attributes.include?(attribute)
    end
  end

  ##
  # Tree builder when model +acts_as_tree+
  #
  def expand_tree_into_select_field(items, attribute)
    returning(String.new) do |html|
      items.each do |item|
        html << %{<option #{"selected" if @item.send(attribute) == item.id} value="#{item.id}">#{"&nbsp;" * item.ancestors.size * 8} &#92;_ #{item.typus_name}</option>\n}
        html << expand_tree_into_select_field(item.children, attribute) if item.has_children?
      end
    end
  end

end