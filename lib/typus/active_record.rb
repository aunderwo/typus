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
    #   class Post < ActiveRecord::Base
    #
    #     def self.admin_fields_for_list
    #       [ :title, :category_id, :status ]
    #     end
    #
    #     def self.admin_fields_for_form
    #       [ :title, :body, :excerpt, :category_id, :status ]
    #     end
    #
    #   end
    #
    def typus_fields_for(filter)

      fields_with_type = ActiveSupport::OrderedHash.new

      begin
        if self.respond_to?("admin_fields_for_#{filter}")
          fields = self.send("admin_fields_for_#{filter}")
        else
          fields = Typus::Configuration.config[self.name]['fields'][filter.to_s]
          fields = fields.split(', ').collect { |f| f.to_sym }
        end
      rescue
        filter = 'list'
        retry
      end

      begin

        fields.each do |field|

          attribute_type = self.model_fields[field]

          # Custom field_type depending on the attribute name.
          case field.to_s
            when 'parent_id':       attribute_type = :tree
            when /file_name/:       attribute_type = :file
            when /password/:        attribute_type = :password
            when 'position':        attribute_type = :position
          end

          if self.reflect_on_association(field)
            attribute_type = self.reflect_on_association(field).macro
          end

          if self.typus_field_options_for(:selectors).include?(field)
            attribute_type = :selector
          end

          # And finally insert the field and the attribute_type 
          # into the fields_with_type ordered hash.
          fields_with_type[field.to_s] = attribute_type

        end

      rescue
        fields = Typus::Configuration.config[self.name]['fields']['list'].split(', ')
        retry
      end

      return fields_with_type

    end

    ##
    # Typus sidebar filters.
    #
    #   class Post < ActiveRecord::Base
    #
    #     def self.admin_filters
    #       [ :created_at, :status ]
    #     end
    #
    #   end
    #
    def typus_filters

      fields_with_type = ActiveSupport::OrderedHash.new

      if self.respond_to?('admin_filters')
        fields = self.admin_filters
      else
        return [] unless Typus::Configuration.config[self.name]['filters']
        fields = Typus::Configuration.config[self.name]['filters'].split(', ').collect { |i| i.to_sym }
      end

      fields.each do |field|
        attribute_type = self.model_fields[field.to_sym]
        if self.reflect_on_association(field.to_sym)
          attribute_type = self.reflect_on_association(field.to_sym).macro
        end
        fields_with_type[field.to_s] = attribute_type
      end

      return fields_with_type

    end

    ##
    #  Extended actions for this model on Typus.
    #
    #    class Post < ActiveRecord::Base
    #
    #      def self.admin_actions_for_index
    #        [ :rebuild_all ]
    #      end
    #
    #      def self.admin_actions_for_edit
    #        [ :rebuild, :notify ]
    #      end
    #
    #    end
    #
    def typus_actions_for(filter)
      if self.respond_to?("admin_actions_for_#{filter}")
        self.send("admin_actions_for_#{filter}").map { |a| a.to_s }
      else
        Typus::Configuration.config[self.name]['actions'][filter.to_s].split(', ') rescue []
      end
    end

    ##
    # Used for +search+.
    #
    #   class Post < ActiveRecord::Base
    #
    #     def self.admin_search
    #       [ 'title', 'details' ]
    #     end
    #
    #   end
    #
    def typus_defaults_for(filter)
      if self.respond_to?("admin_#{filter}")
        self.send("admin_#{filter}")
      else
        Typus::Configuration.config[self.name][filter.to_s].split(', ') rescue []
      end
    end

    ##
    #
    #
    def typus_field_options_for(filter)
      Typus::Configuration.config[self.name]['fields']['options'][filter.to_s].split(', ').collect { |i| i.to_sym } rescue []
    end

    ##
    # Used for +relationships+
    #
    def typus_relationships
      Typus::Configuration.config[self.name]['relationships'].split(', ') rescue []
    end

    ##
    # Used for order_by
    #
    #   class Post < ActiveRecord::Base
    #
    #     def self.admin_order_by
    #       [ '-created_at', 'name' ]
    #     end
    #
    #   end
    #
    def typus_order_by

      order = []

      begin
        fields = self.send("admin_order_by").map { |a| a.to_s }
      rescue
        return "`#{self.table_name}`.id ASC" unless Typus::Configuration.config[self.name]['order_by']
        fields = Typus::Configuration.config[self.name]['order_by'].split(', ')
      end

      fields.each do |field|
        order_by = (field.include?("-")) ? "`#{self.table_name}`.#{field.delete('-')} DESC" : "`#{self.table_name}`.#{field} ASC"
        order << order_by
      end

      return order.join(', ')

    end

    ##
    # We are able to define our own booleans.
    #
    def typus_boolean(attribute = 'default')
      boolean = Typus::Configuration.config[self.name]['fields']['options']['booleans'][attribute] rescue nil
      boolean = "true, false" if boolean.nil?
      return { :true => boolean.split(', ').first.humanize, 
               :false => boolean.split(', ').last.humanize }
    end

    ##
    # We are able to define how to display dates on Typus
    #
    def typus_date_format(attribute = 'default')
      date_format = Typus::Configuration.config[self.name]['fields']['options']['date_formats'][attribute] rescue nil
      date_format = :db if date_format.nil?
      return date_format.to_sym
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
        search = []
        self.typus_defaults_for(:search).each do |s|
          search << ["LOWER(#{s}) LIKE '%#{query_params[:search]}%'"]
        end
        conditions = merge_conditions(conditions, search.join(' OR '))
      end

      query_params.each do |key, value|

        filter_type = self.model_fields[key.to_sym] || self.model_relationships[key.to_sym]

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

    def previous_and_next(condition = {})

      conditions = if condition.empty?
                     "id < #{self.id}"
                   else
                     self.class.build_conditions(condition) \
                     << " AND id != #{self.id}"
                   end

      previous_ = self.class.find :first, 
                                  :select => [:id], 
                                  :order => "id DESC", 
                                  :conditions => conditions

      conditions = if condition.empty?
                     "id > #{self.id}"
                   else
                     self.class.build_conditions(condition) \
                     << " AND id != #{self.id}"
                   end

      next_ = self.class.find :first, 
                              :select => [:id], 
                              :order => "id ASC", 
                              :conditions => conditions

      return previous_, next_

    end

    ##
    # Used by acts_as_tree to detect children.
    #
    def has_children?
      children.size > 0
    end

    ##
    #
    #
    def typus_name
      respond_to?(:name) ? name : "#{self.class}##{id}"
    end

  end

end

ActiveRecord::Base.send :include, Typus
ActiveRecord::Base.send :include, Typus::InstanceMethods