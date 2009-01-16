class TypusController < ApplicationController

  include Authentication
  include Typus::Configuration::Reloader

  if Typus::Configuration.options[:ssl]
    include SslRequirement
    ssl_required :dashboard, :login, :logout, :recover_password, :reset_password
  end

  filter_parameter_logging :password

  before_filter :reload_config_et_roles
  before_filter :require_login, :except => [ :login, :logout, :recover_password, :reset_password, :setup ]

  before_filter :check_if_user_can_perform_action_on_resource_without_model, :except => [ :dashboard, :login, :logout, :recover_password, :reset_password, :setup ]

  before_filter :recover_password_disabled?, :only => [ :recover_password, :reset_password ]

  ##
  # Application Dashboard
  #
  def dashboard
    flash[:notice] = t("There are not defined applications in config/typus/*.yml.") if Typus.applications.empty?
  end

  ##
  # Login
  #
  def login

    redirect_to :action => 'setup' and return if Typus.user_class.count.zero?

    if request.post?
      user = Typus.user_class.authenticate(params[:user][:email], params[:user][:password])
      if user
        session[:typus] = user.id
        redirect_to params[:back_to] || typus_dashboard_url
      else
        flash[:error] = t("The Email and/or Password you entered is invalid.")
        redirect_to typus_login_url
      end
    else
      render :layout => 'typus_login'
    end

  end

  ##
  # Logout and redirect to +typus_login+.
  #
  def logout
    session[:typus] = nil
    redirect_to typus_login_url
  end

  ##
  # Email password when lost
  #
  def recover_password
    if request.post?
      user = Typus.user_class.find_by_email(params[:user][:email])
      if user
        ActionMailer::Base.default_url_options[:host] = request.host_with_port
        TypusMailer.deliver_reset_password_link(user)
        flash[:success] = t("Password recovery link sent to your email.")
        redirect_to typus_login_url
      else
        redirect_to typus_recover_password_url
      end
    else
      render :layout => 'typus_login'
    end
  end

  ##
  # Available if Typus::Configuration.options[:recover_password] is
  # enabled. Enabled by default.
  #
  def reset_password
    if request.post?
      user = Typus.user_class.find_by_token(params[:user][:token])
      if user.update_attributes(params[:user])
        flash[:success] = t("You can login with your new password.")
        redirect_to typus_login_url
      else
        flash[:error] = t("Passwords don't match.")
        redirect_to :action => 'reset_password', :token => params[:user][:token]
      end
    else
      if Typus.user_class.find_by_token(params[:token])
        render :layout => 'typus_login'
      else
        render :text => t("A valid token is required.")
      end
    end
  end

  def setup

    redirect_to :action => 'login' and return unless Typus.user_class.count.zero?

    if request.post?

      password = generate_password

      user = Typus.user_class.new :email => params[:user][:email], 
                                  :password => password, 
                                  :password_confirmation => password, 
                                  :roles => Typus::Configuration.options[:root], 
                                  :status => true

      if user.save
        session[:typus] = user.id
        flash[:notice] = t("Your new password is '{{password}}'.", :password => password)
        redirect_to :action => 'dashboard'
      else
        flash[:error] = t("Yay! That doesn't seem like a valid email address.")
        redirect_to :action => 'setup'
      end

    else

      flash[:success] = t("Welcome! Write your email to create the first user.")
      render :layout => 'typus_login'

    end

  end

  def overview
  end

private

  def recover_password_disabled?
    redirect_to typus_login_url unless Typus::Configuration.options[:recover_password]
  end

end