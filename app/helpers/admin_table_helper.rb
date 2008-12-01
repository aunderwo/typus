module AdminTableHelper

  ##
  # All helpers related to table.
  #
  def build_table(model = @model, fields = 'list', items = @items)

    returning(String.new) do |html|

      html << "<table>"

      html << typus_table_header(model, fields)

      items.each do |item|

        html << "<tr class=\"#{cycle('even', 'odd')}\" id=\"item_#{item.id}\">"

        model.typus_fields_for(fields).each do |column|
          case column[1]
          when "boolean":           html << typus_table_boolean_field(item, column)
          when "datetime", "date":  html << typus_table_datetime_field(item, column)
          when "collection":        html << typus_table_collection_field(item, column)
          when "tree":              html << typus_table_tree_field(item, column)
          when "position":          html << typus_table_position_field(item, column)
          else
            html << typus_table_string_field(item, column, fields)
          end
        end

      ##
      # This controls the action to perform. If we are on a model list we 
      # will remove the entry, but if we inside a model we will remove the 
      # relationship between the models.
      #
      # Only shown is the user can destroy items.
      #

      if @current_user.can_perform?(model, 'delete')

        case params[:action]
        when 'index'
          perform = link_to image_tag("admin/trash.gif"), { :controller => "admin/#{model.name.tableize}", 
                                                            :action => 'destroy', 
                                                            :id => item.id }, 
                                                            :confirm => "Remove entry?", 
                                                            :method => :delete
        else
          perform = link_to image_tag("admin/trash.gif"), { :controller => "admin/#{model.name.tableize}", 
                                                            :action => "unrelate", 
                                                            :id => item.id, 
                                                            :model => @model, 
                                                            :model_id => params[:id] }, 
                                                            :confirm => "Remove #{model.humanize.singularize.downcase} \"#{item.typus_name}\" from #{@model.name}?"
        end

      end

      html << "<td width=\"10px\">#{perform}</td>\n</tr>"

    end

      html << "</table>"

    end

  end

  ##
  # Header of the table
  #
  def typus_table_header(model, fields)
    returning(String.new) do |html|
      html << "<tr>"
      model.typus_fields_for(fields).map(&:first).each do |field|
        order_by = field
        sort_order = (params[:sort_order] == 'asc') ? 'desc' : 'asc'
        if model.model_fields.map(&:first).include?(field) && params[:action] == 'index'
          html << "<th>#{link_to "<div class=\"#{sort_order}\">#{field.titleize.capitalize}</div>", { :params => params.merge(:order_by => order_by, :sort_order => sort_order) }}</th>"
        else
          html << "<th>#{field.titleize.capitalize}</th>"
        end
      end
      html << "<th>&nbsp;</th>\n</tr>"
    end
  end

  def typus_table_collection_field(item, column)
    "<td>#{link_to item.send(column[0].split('_id').first).typus_name, :controller => "admin/#{column[0].split("_id").first.pluralize}", :action => "edit", :id => item.send(column[0])}</td>"
  rescue
    "<td></td>"
  end

  ##
  # When detection of the attributes is made a default attribute 
  # type is set. From the string_field we display other content 
  # types.
  #
  def typus_table_string_field(item, column, fields)
    returning(String.new) do |html|
      if item.class.typus_fields_for(fields).first == column
        html << <<-HTML
<td>#{link_to item.send(column[0]) || "", :controller => "admin/#{item.class.name.tableize}", :action => 'edit', :id => item.id}
<br /><small>#{"Custom actions go here, but only if exist." if Typus::Configuration.options[:actions_on_table]}</small></td>
        HTML
      else
        if item.send(column[0]).kind_of?(Array)
          html << <<-HTML
<td>#{item.send(column[0]).map { |i| i.typus_name }.join(', ')}</td>
          HTML
        else
          html << <<-HTML
<td>#{item.send(column[0])}</td>
          HTML
        end
      end
    end
  end

  def typus_table_tree_field(item, column)
    returning(String.new) do |html|
      html << <<-HTML
<td>#{item.parent.typus_name if item.parent}</td>
      HTML
    end
  end

  def typus_table_position_field(item, column)
    returning(String.new) do |html|
      html_position = []
      [["Up", "move_higher"], ["Down", "move_lower"]].each do |position|
        html_position << <<-HTML
#{link_to position.first, :params => params.merge(:controller => "admin/#{item.class.name.tableize}", :action => 'position', :id => item.id, :go => position.last)}
        HTML
      end
      html << <<-HTML
<td>#{html_position.join('/ ')}</td>
      HTML
    end
  end

  def typus_table_datetime_field(item, column)
    returning(String.new) do |html|
      html << <<-HTML
<td>#{!item.send(column[0]).nil? ? item.send(column[0]).to_s(:db) : 'nil'}</td>
      HTML
    end
  end

  def typus_table_boolean_field(item, column)

    unless item.send(column[0]).nil?
      image = "admin/status_#{item.send(column[0])}.gif"
    else
      ##
      # If the column is null we show the false icon.
      #
      image = "admin/status_false.gif"
    end

    returning(String.new) do |html|

      if Typus::Configuration.options[:toggle]
        html << <<-HTML
<td width="20px" align="center">
  #{link_to image_tag(image), {:params => params.merge(:controller => "admin/#{item.class.name.tableize}", :action => 'toggle', :field => column[0], :id => item.id)} , :confirm => "Change #{column[0]}?"}
</td>
        HTML
      else
        html << <<-HTML
<td width="20px" align="center">#{image}</td>
        HTML
      end

    end

  end

end