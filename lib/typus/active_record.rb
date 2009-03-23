module Typus

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    ##
    # Return model fields as a OrderedHash
    #
    def model_fields
      hash = ActiveSupport::OrderedHash.new
      columns.map { |u| hash[u.name.to_sym] = u.type.to_sym }
      return hash
    end

    def model_relationships
      hash = ActiveSupport::OrderedHash.new
      reflect_on_all_associations.map { |i| hash[i.name] = i.macro }
      return hash
    end

    ##
    # Form and list fields
    #
    def typus_fields_for(filter)

      fields_with_type = ActiveSupport::OrderedHash.new

      begin
        fields = Typus::Configuration.config[name]['fields'][filter.to_s]
        fields = fields.split(', ').collect { |f| f.to_sym }
      rescue
        return [] if filter == 'list'
        filter = 'list'
        retry
      end

      begin

        fields.each do |field|

          attribute_type = model_fields[field]

          # Custom field_type depending on the attribute name.
          case field.to_s
            when 'parent_id':       attribute_type = :tree
            when /file_name/:       attribute_type = :file
            when /password/:        attribute_type = :password
            when 'position':        attribute_type = :position
          end

          if reflect_on_association(field)
            attribute_type = reflect_on_association(field).macro
          end

          if typus_field_options_for(:selectors).include?(field)
            attribute_type = :selector
          end

          # And finally insert the field and the attribute_type 
          # into the fields_with_type ordered hash.
          fields_with_type[field.to_s] = attribute_type

        end

      rescue
        fields = Typus::Configuration.config[name]['fields']['list'].split(', ')
        retry
      end

      return fields_with_type

    end

    ##
    # Typus sidebar filters.
    #
    def typus_filters

      fields_with_type = ActiveSupport::OrderedHash.new

      data = Typus::Configuration.config[name]['filters']
      return [] unless data
      fields = data.split(', ').collect { |i| i.to_sym }

      fields.each do |field|
        attribute_type = model_fields[field.to_sym]
        if reflect_on_association(field.to_sym)
          attribute_type = reflect_on_association(field.to_sym).macro
        end
        fields_with_type[field.to_s] = attribute_type
      end

      return fields_with_type

    end

    ##
    #  Extended actions for this model on Typus.
    #
    def typus_actions_for(filter)
      Typus::Configuration.config[name]['actions'][filter.to_s].split(', ')
    rescue
      []
    end

    ##
    # Used for +search+, +relationships+
    #
    def typus_defaults_for(filter)
      data = Typus::Configuration.config[name][filter.to_s]
      return (!data.nil?) ? data.split(', ') : []
    end

    ##
    #
    #
    def typus_field_options_for(filter)
      Typus::Configuration.config[name]['fields']['options'][filter.to_s].split(', ').collect { |i| i.to_sym }
    rescue
      []
    end

    ##
    # We should be able to overwrite options by model.
    #
    def typus_options_for(filter)

      data = Typus::Configuration.config[name]
      unless data['options'].nil?
        value = data['options'][filter.to_s] unless data['options'][filter.to_s].nil?
      end

      return (!value.nil?) ? value : Typus::Configuration.options[filter.to_sym]

    end

    ##
    # Used for order_by
    #
    def typus_order_by

      fields = typus_defaults_for(:order_by)
      return "`#{table_name}`.id ASC" if fields.empty?

      order = fields.map do |field|
                (field.include?('-')) ? "`#{table_name}`.#{field.delete('-')} DESC" : "`#{table_name}`.#{field} ASC"
              end

      return order.join(', ')

    end

    ##
    # We are able to define our own booleans.
    #
    def typus_boolean(attribute = :default)

      boolean = Typus::Configuration.config[name]['fields']['options']['booleans'][attribute.to_s] rescue nil
      boolean = 'true, false' if boolean.nil?

      hash = ActiveSupport::OrderedHash.new
      hash[:true] = boolean.split(', ').first.humanize
      hash[:false] = boolean.split(', ').last.humanize

      return hash

    end

    ##
    # We are able to define how to display dates on Typus
    #
    def typus_date_format(attribute = :default)
      date_format = Typus::Configuration.config[name]['fields']['options']['date_formats'][attribute.to_s] rescue nil
      date_format = :db if date_format.nil?
      return date_format.to_sym
    end

    ##
    # We are able to define which template to use to render the attribute 
    # within the form
    #
    def typus_template(attribute)
      template = Typus::Configuration.config[name]['fields']['options']['templates'][attribute.to_s] rescue nil
      return template
    end

    ##
    # Build conditions
    #
    def build_conditions(params)

      conditions, joins = merge_conditions, []

      query_params = params.dup
      %w( action controller ).each { |param| query_params.delete(param) }

      # If a search is performed.
      if query_params[:search]
        search = typus_defaults_for(:search).map do |s|
                   ["LOWER(#{s}) LIKE '%#{query_params[:search]}%'"]
                 end
        conditions = merge_conditions(conditions, search.join(' OR '))
      end

      query_params.each do |key, value|

        filter_type = model_fields[key.to_sym] || model_relationships[key.to_sym]

        ##
        # Sidebar filters:
        #
        #   - Booleans: true, false
        #   - Datetime: today, past_7_days, this_month, this_year
        #   - Integer & String: *_id and "selectors" (P.ej. category_id)
        #
        case filter_type
        when :boolean
          condition = { key => (value == 'true') ? true : false }
          conditions = merge_conditions(conditions, condition)
        when :datetime
          interval = case value
                     when 'today':         Time.today..Time.today.tomorrow
                     when 'past_7_days':   6.days.ago.midnight..Time.today.tomorrow
                     when 'this_month':    Time.today.last_month..Time.today.tomorrow
                     when 'this_year':     Time.today.last_year..Time.today.tomorrow
                     end
          condition = ["#{key} BETWEEN ? AND ?", interval.first, interval.last]
          conditions = merge_conditions(conditions, condition)
        when :integer, :string
          condition = { key => value }
          conditions = merge_conditions(conditions, condition)
        when :has_and_belongs_to_many
          condition = {  key => { :id => value } }
          conditions = merge_conditions(conditions, condition)
          joins << key.to_sym
        end

      end

      return conditions, joins

    end

  end

  module InstanceMethods

    def previous_and_next(condition = {}, klass = self.class)

      previous_conditions = "id < #{id}"
      next_conditions = "id > #{id}"

      if !condition.empty?
        conditions, joins = klass.build_conditions(condition)
        previous_conditions += " AND #{conditions}"
        next_conditions += " AND #{conditions}"
      end

      previous_ = klass.find :first, 
                             :select => [:id], 
                             :order => "id DESC", 
                             :conditions => previous_conditions

      next_ = klass.find :first, 
                         :select => [:id], 
                         :order => "id ASC", 
                         :conditions => next_conditions

      return previous_, next_

    end

    def typus_name
      respond_to?(:name) ? name : "#{self.class}##{id}"
    end

  end

end

ActiveRecord::Base.send :include, Typus
ActiveRecord::Base.send :include, Typus::InstanceMethods