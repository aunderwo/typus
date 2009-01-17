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
      back_to = (request.env['REQUEST_URI'] == '/admin') ? nil : request.env['REQUEST_URI']
      redirect_to typus_login_url(:back_to => back_to)
    end
  end

  ##
  # Return the current user. The important thing here is that if the 
  # roles does not longer exist on the system the user will be logged 
  # off from Typus.
  #
  def set_current_user
    @current_user ||= Typus.user_class.find(session[:typus])
    raise unless Typus::Configuration.roles.keys.include?(@current_user.roles)
  rescue
    flash[:error] = "Error! Typus User or role doesn't exist."
    session[:typus] = nil
    redirect_to typus_login_url
  end

  ##
  # Password generation using numbers and letters.
  #
  def generate_password(length = 8)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    password = ""
    1.upto(length) { |i| password << chars[rand(chars.size - 1)] }
    return password
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
                  "As you're not the admin or the owner of this record you cannot edit it."
                end

              when 'update'

                # current_user cannot change her role.
                if current_user && !(@item.roles == params[:item][:roles])
                  "You can't change your role."
                end

              when 'toggle'

                # Only admin can toggle typus user status, but not herself.
                if @current_user.is_root? && current_user
                  "You can't toggle your status."
                elsif !@current_user.is_root?
                  "You're not allowed to toggle status."
                end

              when 'destroy'

                # Admin can remove anything except herself.
                if @current_user.is_root? && current_user
                  "You can't remove yourself."
                elsif !@current_user.is_root?
                  "You're not allowed to remove Typus Users."
                end

              end

    if message
      flash[:notice] = message
      redirect_to :back rescue redirect_to typus_dashboard_url
    end

  end

  ##
  # This method checks if the user can perform the requested action.
  # It works on models, so its available on the admin_controller.
  #
  def check_if_user_can_perform_action_on_resource

    message = case params[:action]
              when 'index', 'show'
                "#{@current_user.roles.capitalize} can't display items."
              when 'edit', 'update', 'position', 'toggle', 'relate', 'unrelate'
              when 'destroy'
                "#{@current_user.roles.capitalize} can't delete this item."
              else
                "#{@current_user.roles.capitalize} can't perform action. (#{params[:action]})"
              end

    unless @current_user.can_perform?(@resource[:class], params[:action])
      flash[:notice] = message || "#{@current_user.roles.capitalize} can't perform action. (#{params[:action]})"
      redirect_to :back rescue redirect_to typus_dashboard_url
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
      flash[:notice] = "#{@current_user.roles.capitalize} can't go to #{action} on #{controller.humanize.downcase}."
      redirect_to :back rescue redirect_to typus_dashboard_url
    end
  end

end