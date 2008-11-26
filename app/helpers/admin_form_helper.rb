module AdminFormHelper

  ##
  # All helpers related to form.
  #

  def build_form(fields = @item_fields)
    returning(String.new) do |html|
      html << "#{error_messages_for :item, :header_tag => "h3"}"
      html << "<ul>"
      fields.each do |field|
        case field.last
        when "boolean":         html << typus_boolean_field(field.first, field.last)
        when "datetime":        html << typus_datetime_field(field.first, field.last)
        when "date":            html << typus_date_field(field.first, field.last)
        when "text":            html << typus_text_field(field.first, field.last)
        when "file":            html << typus_file_field(field.first, field.last)
        when "password":        html << typus_password_field(field.first, field.last)
        when "selector":        html << typus_selector_field(field.first, field.last)
        when "collection":      html << typus_collection_field(field.first, field.last)
        when "tree":            html << typus_tree_field(field.first, field.last)
        else
          html << typus_string_field(field.first, field.last)
        end
      end
      html << "</ul>"
    end
  end

  def typus_tree_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>
<select id="item_#{attribute}" name="item[#{attribute}]" <%= attribute_disabled?(attribute) ? 'disabled="disabled"' : '' %>>>
  <option value=""></option>
  #{expand_tree_into_select_field(@item.class.top)}
</select></li>
      HTML
    end
  end

  def typus_datetime_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{datetime_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end
  end

    def typus_date_field(attribute, value)
      returning(String.new) do |html|
        html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{date_select :item, attribute, { :minute_step => Typus::Configuration.options[:minute_step] }, {:disabled => attribute_disabled?(attribute)}}</li>
        HTML
      end
    end

  def typus_text_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{text_area :item, attribute, :class => 'text', :rows => Typus::Configuration.options[:form_rows], :disabled => attribute_disabled?(attribute)}</li>
      HTML
    end
  end

  def typus_selector_field(attribute, value)
    returning(String.new) do |html|
      options = ""
      @model.send(attribute).each do |option|
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
<li><label for=\"item_#{attribute}\">#{attribute.titleize.capitalize}</label>
<select id="item_#{attribute}" name="item[#{attribute}]" <%= attribute_disabled?(attribute) ? 'disabled="disabled"' : '' %>>
  <option value="">Select an option</option>
  #{options}
</select></li>
      HTML
    end
  end

  def typus_collection_field(attribute, value)

    back_to = "/" + ([] << params[:controller] << params[:id]<< params[:action]).compact.join('/')
    related = @model.reflect_on_association(attribute.split("_id").first.to_sym).class_name.constantize
    
    
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize} <small>#{link_to "Add new", { :controller => attribute.titleize.tableize, :action => 'new', :back_to => back_to, :selected => attribute }, :confirm => "Are you sure you want to leave this page?\nAny unsaved data will be lost." }</small></label>
#{select :item, attribute, related.find(:all).collect { |p| [p.typus_name, p.id] }.sort_by { |e| e.first },{:prompt => "Select a #{related.name.downcase}"},{:disabled => attribute_disabled?(attribute)}}</li>
      HTML
    end

  end

  def typus_string_field(attribute, value)

    # Read only fields.
    if @model.typus_field_options_for(:read_only).include?(attribute)
      value = 'read_only' if %w( edit ).include?(params[:action])
    end

    # Auto generated fields.
    if @model.typus_field_options_for(:auto_generated).include?(attribute)
      value = 'auto_generated' if %w( new edit ).include?(params[:action])
    end

    comment = %w( read_only auto_generated ).include?(value) ? (value + " field").titleize : ""

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize} <small>#{comment}</small></label>
#{text_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute) }</li>
      HTML
    end

  end

  def typus_password_field(attribute, value)
    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}</label>
#{password_field :item, attribute, :class => 'text', :disabled => attribute_disabled?(attribute)}</li>
      HTML
    end
  end

  def typus_boolean_field(attribute, value)

    question = true if @model.typus_field_options_for(:questions).include?(attribute)

    returning(String.new) do |html|
      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute.titleize.capitalize}#{'?' if question}</label>
#{check_box :item, attribute} Checked if active</li>
      HTML
    end

  end

  def typus_file_field(attribute, value)

    attribute_display = attribute.split("_file_name").first
    content_type = @item.send("#{attribute_display}_content_type")

    returning(String.new) do |html|

      html << <<-HTML
<li><label for="item_#{attribute}">#{attribute_display.titleize.capitalize}</label>
      HTML

      case content_type
      when /image/
        html << "#{link_to image_tag(@item.send(attribute_display).url(:thumb)), @item.send(attribute_display).url, :style => "border: 1px solid #D3D3D3;"}<br /><br />"
      when /pdf|flv|quicktime/
        html << "<p>No preview available. (#{content_type.split('/').last})</p>"
      end

      html << "#{file_field :item, attribute.split("_file_name").first,:disabled => attribute_disabled?(attribute) }</li>"

    end

  end

  def typus_form_has_many

    back_to = "/" + ([] << params[:controller] << params[:id]<< params[:action]).compact.join('/')

    returning(String.new) do |html|

      @item_has_many.each do |field|
        html << <<-HTML
<div class="box_relationships">
  <h2>
  #{link_to field.titleize, :controller => field}
  <small>#{link_to "Add new", :controller => field, :action => 'new', :back_to => back_to, :model => @model, :model_id => @item.id}</small>
  </h2>
        HTML
        @items = @model.find(params[:id]).send(field)
        unless @items.empty?
          html << build_table(@items[0].class, 'relationship', @items)
        else
          html << <<-HTML
  <div id="flash" class="notice"><p>There are no #{field.titleize.downcase}.</p></div>
          HTML
        end
        html << <<-HTML
</div>
        HTML
      end
    end
  end

  def typus_form_has_and_belongs_to_many

    back_to = "/" + ([] << params[:controller] << params[:id]<< params[:action]).compact.join('/')

    returning(String.new) do |html|
      @item_has_and_belongs_to_many.each do |field|
        model_to_relate = field.singularize.camelize.constantize
        html << <<-HTML
<div class="box_relationships">
  <h2>
  #{link_to field.titleize, :controller => field}
  <small>#{link_to "Add new", :controller => field, :action => 'new', :back_to => back_to, :model => @model, :model_id => @item.id}</small>
  </h2>
        HTML
        items_to_relate = (model_to_relate.find(:all) - @item.send(field))
        unless items_to_relate.empty?
          html << <<-HTML
  #{form_tag :action => 'relate'}
  #{hidden_field :related, :model, :value => field.modelize}
  <p>#{ select :related, :id, items_to_relate.collect { |f| [f.typus_name, f.id] }.sort_by { |e| e.first } } &nbsp; #{submit_tag "Add", :class => 'button'}</form></p>
          HTML
        end
        current_model = @model.name.singularize.camelize.constantize
        @items = current_model.find(params[:id]).send(field)
        unless @items.empty?
          html << build_table(field.modelize, 'relationship')
        else
          html << <<-HTML
  <div id="flash" class="notice"><p>There are no #{field.titleize.downcase}.</p></div>
          HTML
        end
        html << <<-HTML
</div>
        HTML
      end
    end

  end
  
  def attribute_disabled?(attribute)
    if @model.accessible_attributes.nil?
      return false
    else
      return !@model.accessible_attributes.include?(attribute)
    end
  end

  ##
  # Tree when +acts_as_tree+
  #
  def expand_tree_into_select_field(categories)
    returning(String.new) do |html|
      categories.each do |category|
        html << %{<option #{"selected" if @item.parent_id == category.id} value="#{category.id}">#{"-" * category.ancestors.size} #{category.name}</option>}
        html << expand_tree_into_select_field(category.children) if category.has_children?
      end
    end
  end

end