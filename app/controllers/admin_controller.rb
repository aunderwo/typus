class AdminController < ApplicationController

  layout 'typus'

  include Authentication
  include Typus::Configuration::Reloader

  if Typus::Configuration.options[:ssl]
    include SslRequirement
    ssl_required :index, :new, :create, :edit, :show, :update, :destroy, :toggle, :position, :relate, :unrelate
  end

  before_filter :reload_config_et_roles

  before_filter :require_login
  before_filter :current_user

  before_filter :set_model
  before_filter :find_model, :only => [ :show, :edit, :update, :destroy, :toggle, :position ]

  before_filter :can_perform_action_on_typus_user?, :only => [ :edit, :update, :toggle, :destroy ]
  before_filter :can_perform_action?

  before_filter :set_order, :only => [ :index ]

  before_filter :fields, :only => [ :index ]
  before_filter :form_fields, :only => [ :new, :edit, :create, :update ]

  ##
  # This is the main index of the model. With the filters, conditions 
  # and more. You can get HTML, CSV and XML listings.
  #
  def index

    ##
    # Build the conditions
    #
    conditions = @model.build_conditions(params)

    ##
    # Pagination
    #
    items_count = @model.count(:conditions => conditions)
    items_per_page = Typus::Configuration.options[:per_page].to_i
    @pager = ::Paginator.new(items_count, items_per_page) do |offset, per_page|
      @model.find(:all, 
                  :conditions => conditions, 
                  :order => @order, 
                  :limit => per_page, 
                  :offset => offset)
    end

    @items = @pager.page(params[:page])

    ##
    # Respond with HTML, CSV and XML versions. This feature is only 
    # available on the index as is where we usually need those file 
    # versions.
    #
    respond_to do |format|
      format.html { select_template :index }
      format.csv { generate_csv }
      format.xml  { render :xml => @items.items }
    end

  rescue Exception => error
    error_handler(error)
  end

  ##
  # New item.
  #
  def new

    item_params = params.dup
    %w( action controller model model_id back_to selected ).each do |param|
      item_params.delete(param)
    end

    @item = @model.new(item_params.symbolize_keys)

    select_template :new

  end

  ##
  # Create new records. There's an special case when we create a 
  # record from another record. In this case, after the record is 
  # created we create also the relationship between these models. 
  #
  def create
    @item = @model.new(params[:item])
    if @item.valid?
      if params[:back_to]
        if params[:model] && params[:model_id]
          model_to_relate = params[:model].constantize
          if @item.respond_to?(params[:model].tableize)
            @item.save
            # This is the case of habtm
            @item.send(params[:model].tableize) << model_to_relate.find(params[:model_id])
          else
            # This is the case of a polymorphic relationship.
            model_to_relate.find(params[:model_id]).send(@item.class.name.tableize).create(params[:item])
          end
          flash[:success] = "#{@item.class} successfully assigned to #{params[:model].downcase}."
          redirect_to params[:back_to]
        else
          @item.save
          flash[:success] = "New #{@model.to_s.downcase} created."
          redirect_to "#{params[:back_to]}?#{params[:selected]}=#{@item.id}"
        end
      else
        @item.save
        flash[:success] = "#{@model.to_s.titleize} successfully created."
        if Typus::Configuration.options[:edit_after_create]
          redirect_to :action => 'edit', :id => @item.id
        else
          redirect_to :action => 'index'
        end
      end
    else
      select_template :new
    end
  end

  ##
  # Edit an item.
  #
  def edit
    ##
    # We assign the params passed trough the url
    #
    item_params = params.dup
    %w( action controller model model_id back_to id ).each do |param|
      item_params.delete(param)
    end
    @item.attributes = item_params

    @previous, @next = @item.previous_and_next
    select_template :edit
  end

  ##
  # Show an item.
  #
  def show
    @previous, @next = @item.previous_and_next
    select_template :show
  end

  ##
  # Update an item.
  #
  def update
    if @item.update_attributes(params[:item])
      flash[:success] = "#{@model.humanize} successfully updated."
      if Typus::Configuration.options[:edit_after_create]
        redirect_to :action => 'edit', :id => @item.id
      else
        redirect_to :action => 'index'
      end
    else
      select_template :edit
    end
  end

  ##
  # Destroy an item.
  #
  def destroy
    @item.destroy
    flash[:success] = "#{@model.humanize} successfully removed."
    redirect_to :back
  rescue Exception => error
    error_handler(error, { :params => params.merge(:action => 'index', :id => nil) })
  end

  ##
  # Toggle the status of an item.
  #
  def toggle
    if Typus::Configuration.options[:toggle]
      @item.toggle!(params[:field])
      flash[:success] = "#{@model.humanize} #{params[:field]} changed."
    else
      flash[:warning] = "Toggle is disabled."
    end
    redirect_to :back
  end

  ##
  # Change item position. This only works if acts_as_list is 
  # installed. We can then move items:
  #
  #   params[:go] = 'move_to_top'
  #   params[:go] = 'move_higher'
  #   params[:go] = 'move_lower'
  #   params[:go] = 'move_to_bottom'
  #
  def position
    @item.send(params[:go])
    flash[:success] = "Record moved %s." % params[:go].gsub(/move_/, '').humanize.downcase
    redirect_to :back
  end

  ##
  # Relate a model object to another.
  #
  def relate
    model_to_relate = params[:related][:model].constantize
    @model.find(params[:id]).send(params[:related][:model].tableize) << model_to_relate.find(params[:related][:id])
    flash[:success] = "#{model_to_relate.to_s.titleize} added to #{@model.humanize.downcase}."
    redirect_to :back
  end

  ##
  # Remove relationship between models.
  #
  def unrelate
    model_to_unrelate = params[:model].constantize
    unrelate = model_to_unrelate.find(params[:model_id])
    if @model.find(params[:id]).respond_to?(params[:model].tableize)
      # Unrelate a habtm
      @model.find(params[:id]).send(params[:model].tableize).delete(unrelate)
      flash[:success] = "#{model_to_unrelate.to_s.titleize} removed from #{@model.humanize.downcase}."
    else
      # Unrelate a polymorphic relationship
      @model.find(params[:id]).destroy
      flash[:success] = "#{@model.humanize.titleize} removed from #{model_to_unrelate.to_s.downcase}."
    end
    redirect_to :back
  end

private

  ##
  # Set current model.
  #
  def set_model
    @model_as_resource = params[:controller].split("/").last
    @model = @model_as_resource.to_class
  rescue Exception => error
    error_handler(error)
  end

  ##
  # Set default order on the listings.
  #
  #     @order = "id ASC"
  #
  def set_order
    unless params[:order_by]
      @order = @model.typus_order_by
    else
      @order = "#{params[:order_by]} #{params[:sort_order]}"
    end
  end

  ##
  # Find
  #
  def find_model
    @item = @model.find(params[:id])
  end

  ##
  # Model +fields+
  #
  def fields
    @fields = @model.typus_fields_for(:list)
  end

  ##
  # Model +form_fields+ and +form_fields_externals+
  #
  def form_fields
    @item_fields = @model.typus_fields_for(:form)
    @item_relationships = @model.typus_relationships
  end

  ##
  # Select which template to render.
  #
  def select_template(template, model = @model)
    if File.exists?("#{Rails.root}/app/views/admin/#{model.name.tableize}/#{template}.html.erb")
      render :template => "admin/#{model.name.tableize}/#{template}"
    else
      render :template => "admin/#{template}"
    end
  end

  ##
  # Error handler
  #
  def error_handler(error, redirection = typus_dashboard_url)
    if Rails.env.production?
      flash[:error] = error.message + "(#{@model})"
      redirect_to redirection
    else
      raise error
    end
  end

  def generate_csv

    require 'fastercsv'

    fields = @model.typus_fields_for(:csv).collect { |i| i.first }
    csv_string = FasterCSV.generate do |csv|
      csv << fields
      @items.items.each do |item|
        tmp = []
        fields.each { |f| tmp << item.send(f) }
        csv << tmp
      end
    end

    filename = "#{Time.now.strftime("%Y%m%d")}_#{@model.to_s.tableize}.csv"
    send_data(csv_string,
             :type => 'text/csv; charset=utf-8; header=present',
             :filename => filename)

  rescue LoadError
    render :text => "FasterCSV is not installed."
  end

end