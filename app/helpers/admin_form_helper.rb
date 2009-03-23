module AdminFormHelper

  ##
  # All helpers related to form.
  #

  def build_form(fields)

    options = { :start_year => @resource[:class].typus_options_for(:start_year), 
                :end_year => @resource[:class].typus_options_for(:end_year), 
                :minute_step => @resource[:class].typus_options_for(:minute_step) }

    returning(String.new) do |html|
      html << (error_messages_for :item, :header_tag => 'h3')
      html << '<ul>'
      fields.each do |key, value|
        if template = @resource[:class].typus_template(key)
          html << typus_template_field(key, template, options)
          next
        end
        case value
        when :belongs_to:      html << typus_belongs_to_field(key)
        when :boolean:         html << typus_boolean_field(key)
        when :date:            html << typus_date_field(key, options)
        when :datetime:        html << typus_datetime_field(key, options)
        when :file:            html << typus_file_field(key)
        when :password:        html << typus_password_field(key)
        when :selector:        html << typus_selector_field(key)
        when :text:            html << typus_text_field(key)
        when :time:            html << typus_time_field(key, options)
        when :tree:            html << typus_tree_field(key)
        else
          html << typus_string_field(key)
        end
      end
      html << '</ul>'
    end
  end

  def typus_belongs_to_field(attribute, klass = @resource[:class])

    ##
    # We only can pass parameters to 'new' and 'edit', so this hack makes
    # the work to replace the current action.
    #
    params[:action] = (params[:action] == 'create') ? 'new' : params[:action]

    back_to = [ Typus::Configuration.options[:path_prefix], 
                params[:controller].split('/').last, 
                params[:id], 
                params[:action] ]

    back_to = "/#{back_to.compact.join('/')}"

    related = klass.reflect_on_association(attribute.to_sym).class_name.constantize
    related_fk = klass.reflect_on_association(attribute.to_sym).primary_key_name

    message = [ I18n.t("Are you sure you want to leave this page?"),
                I18n.t("If you have made any changes to the fields without clicking the Save/Update entry button, your changes will be lost."),
                I18n.t("Click OK to continue, or click Cancel to stay on this page.") ]

    returning(String.new) do |html|

      if related.respond_to?(:roots)
        html << typus_tree_field(related_fk, related.roots, related_fk)
      else
        html << <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(related_fk.humanize, :default => related_fk.humanize)}
    <small>#{link_to I18n.t("Add new"), { :controller => related.class_name.tableize, :action => 'new', :back_to => back_to, :selected => related_fk }, :confirm => message.join("\n\n") if @current_user.can_perform?(related, 'create')}</small>
    </label>
#{select :item, related_fk, related.find(:all, :order => related.typus_order_by).collect { |p| [p.typus_name, p.id] }, { :include_blank => true }, { :disabled => attribute_disabled?(attribute, klass) } }</li>
        HTML
      end

    end

  end

  def typus_boolean_field(attribute, klass = @resource[:class])

    question = true if klass.typus_field_options_for(:questions).include?(attribute)

    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}#{'?' if question}</label>
#{check_box :item, attribute} #{I18n.t("Checked if active", :default => "Checked if active")}</li>
    HTML

  end

  def typus_date_field(attribute, options, klass = @resource[:class])
    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}</label>
#{date_select :item, attribute, options, { :disabled => attribute_disabled?(attribute, klass)} }</li>
    HTML
  end

  def typus_datetime_field(attribute, options, klass = @resource[:class])
    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}</label>
#{datetime_select :item, attribute, options, {:disabled => attribute_disabled?(attribute, klass)}}</li>
    HTML
  end

  def typus_file_field(attribute, klass = @resource[:class])

    attribute_display = attribute.split('_file_name').first

    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute_display.humanize, :default => attribute_display.humanize)}</label>
#{file_field :item, attribute.split("_file_name").first, :disabled => attribute_disabled?(attribute, klass)}</li>
    HTML

  end

  def typus_password_field(attribute, klass = @resource[:class])
    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}</label>
#{password_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute, klass)}</li>
    HTML
  end

  def typus_selector_field(attribute)
    returning(String.new) do |html|
      options = []
      @resource[:class].send(attribute).each do |option|
        case option.kind_of?(Array)
        when true
          selected = (@item.send(attribute).to_s == option.last.to_s) ? 'selected' : ''
          options << "<option #{selected} value=\"#{option.last}\">#{option.first}</option>"
        else
          selected = (@item.send(attribute).to_s == option.to_s) ? 'selected' : ''
          options << "<option #{selected} value=\"#{option}\">#{option}</option>"
        end
      end
      html << <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}</label>
<select id="item_#{attribute}" #{attribute_disabled?(attribute) ? 'disabled="disabled"' : ''} name="item[#{attribute}]">
<option value=""></option>
#{options.join("\n")}
</select></li>
      HTML
    end
  end

  def typus_text_field(attribute, klass = @resource[:class])
    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}</label>
#{text_area :item, attribute, :class => 'text', :rows => klass.typus_options_for(:form_rows), :disabled => attribute_disabled?(attribute, klass)}</li>
    HTML
  end

  def typus_time_field(attribute, options, klass = @resource[:class])
    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}</label>
#{time_select :item, attribute, options, {:disabled => attribute_disabled?(attribute, klass)}}</li>
    HTML
  end

  def typus_tree_field(attribute, items = @resource[:class].roots, attribute_virtual = 'parent_id')
    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)}</label>
<select id="item_#{attribute}" #{attribute_disabled?(attribute) ? 'disabled="disabled"' : ''} name="item[#{attribute}]">
  <option value=""></option>
  #{expand_tree_into_select_field(items, attribute_virtual)}
</select></li>
    HTML
  end

  def typus_string_field(attribute, klass = @resource[:class])

    # Read only fields.
    if klass.typus_field_options_for(:read_only).include?(attribute)
      value = 'read_only' if %w( edit ).include?(params[:action])
    end

    # Auto generated fields.
    if klass.typus_field_options_for(:auto_generated).include?(attribute)
      value = 'auto_generated' if %w( new edit ).include?(params[:action])
    end

    comment = %w( read_only auto_generated ).include?(value) ? (value + ' field').titleize : ''

    <<-HTML
<li><label for="item_#{attribute}">#{I18n.t(attribute.humanize, :default => attribute.humanize)} <small>#{comment}</small></label>
#{text_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute, klass) }</li>
    HTML

  end

  def typus_relationships

    back_to = [ Typus::Configuration.options[:path_prefix], 
                params[:controller].split('/').last, 
                params[:id], 
                params[:action] ]

    @back_to = "/#{back_to.compact.join('/')}"

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
      model_to_relate = @resource[:class].reflect_on_association(field.to_sym).class_name.constantize
      model_to_relate_as_resource = model_to_relate.name.tableize
      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to I18n.t(field.titleize, :default => field.titleize), :controller => field}
  <small>#{link_to I18n.t("Add new", :default => "Add new"), :controller => field, :action => 'new', :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id if @current_user.can_perform?(model_to_relate, 'create')}</small>
  </h2>
      HTML
      items = @resource[:class].find(params[:id]).send(field)
      unless items.empty?
        options = { :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id }
        html << build_list(model_to_relate, 
                           model_to_relate.typus_fields_for(:relationship), 
                           items, 
                           model_to_relate_as_resource, 
                           options)
      else
        html << <<-HTML
  <div id="flash" class="notice"><p>#{I18n.t("There are no {{records}}.", :records => I18n.t(field.titleize.downcase, :default => field.titleize.downcase), :default => "There are no {{records}}.")}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def typus_form_has_and_belongs_to_many(field)
    returning(String.new) do |html|
      model_to_relate = @resource[:class].reflect_on_association(field.to_sym).class_name.constantize
      model_to_relate_as_resource = model_to_relate.name.tableize
      html << <<-HTML
<a name="#{field}"></a>
<div class="box_relationships">
  <h2>
  #{link_to I18n.t(field.titleize, :default => field.titleize), :controller => field}
  <small>#{link_to I18n.t("Add new", :default => "Add new"), :controller => field, :action => 'new', :back_to => @back_to, :resource => @resource[:self], :resource_id => @item.id if @current_user.can_perform?(model_to_relate, 'create')}</small>
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
        html << build_list(model_to_relate, model_to_relate.typus_fields_for(:relationship), items, model_to_relate_as_resource)
      else
        html << <<-HTML
  <div id="flash" class="notice"><p>#{I18n.t("There are no {{records}}.", :records => I18n.t(field.titleize.downcase, :default => field.titleize.downcase), :default => "There are no {{records}}.")}</p></div>
        HTML
      end
      html << <<-HTML
</div>
      HTML
    end
  end

  def typus_template_field(attribute, template, options = {})
    folder = Typus::Configuration.options[:templates_folder]
    template_name = File.join(folder, template)

    output = render(:partial => template_name, :locals => { :resource => @resource, :attribute => attribute, :options => options } )
    output || "#{attribute}: Can not find the template '#{template}'"
  end

  def attribute_disabled?(attribute, klass = @resource[:class])
    accessible = klass.accessible_attributes
    return accessible.nil? ? false : !accessible.include?(attribute)
  end

  ##
  # Tree builder when model +acts_as_tree+
  #
  def expand_tree_into_select_field(items, attribute)
    returning(String.new) do |html|
      items.each do |item|
        html << %{<option #{"selected" if @item.send(attribute) == item.id} value="#{item.id}">#{"&nbsp;" * item.ancestors.size * 8} &#92;_ #{item.typus_name}</option>\n}
        html << expand_tree_into_select_field(item.children, attribute) unless item.children.empty?
      end
    end
  end

end