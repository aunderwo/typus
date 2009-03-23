module Authentication

protected

  ##
  # Require login checks if the user is logged on Typus, otherwise 
  # is sent to the login page with a :back_to param to return where 
  # she tried to go.
  #
  # Use this for demo!
  #
  #     session[:typus] = Typus.user_class.find(:first)
  #
  def require_login
    if session[:typus]
      set_current_user
    else
      back_to = (request.env['REQUEST_URI'] == "/#{Typus::Configuration.options[:path_prefix]}") ? nil : request.env['REQUEST_URI']
      redirect_to admin_sign_in_path(:back_to => back_to)
    end
  end

  ##
  # Return the current user. The important thing here is that if the 
  # roles does not longer exist on the system the user will be logged 
  # off from Typus.
  #
  def set_current_user

    @current_user = Typus.user_class.find(session[:typus])

    unless Typus::Configuration.roles.keys.include?(@current_user.roles)
      message = t("Typus user or role no longer exist.", :default => "Typus user or role no longer exist.")
      raise
    end

    unless @current_user.status
      back_to = (request.env['REQUEST_URI'] == "/#{Typus::Configuration.options[:path_prefix]}") ? nil : request.env['REQUEST_URI']
      message = t("Your typus user has been disabled.", :default => "Your typus user has been disabled.")
      raise
    end

  rescue
    flash[:notice] = message
    session[:typus] = nil
    redirect_to admin_sign_in_path(:back_to => back_to)
  end

  ##
  # Password generation using numbers and letters.
  #
  def generate_password(length = 8)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    return Array.new(length) { chars.rand }.join
  end

  ##
  # Action is available on:
  #
  #     edit, update, toggle and destroy
  #
  def check_if_user_can_perform_action_on_user

    return unless @item.kind_of?(Typus.user_class)

    current_user = (@current_user == @item)

    message = case params[:action]
              when 'edit'

                # Only admin and owner of Typus User can edit.
                if !@current_user.is_root? && !current_user
                  t("As you're not the admin or the owner of this record you cannot edit it.")
                end

              when 'update'

                # current_user cannot change her role.
                if current_user && !(@item.roles == params[:item][:roles])
                  t("You can't change your role.")
                end

              when 'toggle'

                # Only admin can toggle typus user status, but not herself.
                if @current_user.is_root? && current_user
                  t("You can't toggle your status.")
                elsif !@current_user.is_root?
                  t("You're not allowed to toggle status.")
                end

              when 'destroy'

                # Admin can remove anything except herself.
                if @current_user.is_root? && current_user
                  t("You can't remove yourself.")
                elsif !@current_user.is_root?
                  t("You're not allowed to remove Typus Users.")
                end

              end

    if message
      flash[:notice] = message
      redirect_to :back rescue redirect_to admin_dashboard_path
    end

  end

  ##
  # This method checks if the user can perform the requested action.
  # It works on models, so its available on the admin_controller.
  #
  def check_if_user_can_perform_action_on_resource

    message = case params[:action]
              when 'index', 'show'
                t("{{current_user_role}} can't display items", :current_user_role => @current_user.roles.capitalize)
              when 'edit', 'update', 'position', 'toggle', 'relate', 'unrelate'
              when 'destroy'
                t("{{current_user_role}} can't delete this item", :current_user_role => @current_user.roles.capitalize )
              else
                t("{{current_user_role}} can't perform action ({{action}})", :current_user_role => @current_user.roles.capitalize, :action => params[:action] )
              end

    unless @current_user.can_perform?(@resource[:class], params[:action])
      flash[:notice] = message || t("{{current_user_role}} can't perform action. ({{action}})", :current_user_role => @current_user.roles.capitalize, :action => params[:action] )
      redirect_to :back rescue redirect_to admin_dashboard_path
    end

  end

  ##
  # This method checks if the user can perform the requested action.
  # It works on resources, which are not models, so its available on 
  # the typus_controller.
  #
  def check_if_user_can_perform_action_on_resource_without_model
    controller = params[:controller].split('/').last
    action = params[:action]
    unless @current_user.can_perform?(controller.camelize, action, { :special => true })
      flash[:notice] = t("{{current_user_role}} can't go to {{action}} on {{controller}}", :current_user_role => @current_user.roles.capitalize, :action => action, :controller => controller.humanize.downcase)
      redirect_to :back rescue redirect_to admin_dashboard_path
    end
  end

end