class TypusController < ApplicationController

  layout :select_layout

  include Authentication
  include Typus::Configuration::Reloader
  include Typus::Locale

  if Typus::Configuration.options[:ssl]
    include SslRequirement
    ssl_required :sign_in, :sign_out, 
                 :dashboard, 
                 :recover_password, :reset_password
  end

  filter_parameter_logging :password

  before_filter :set_locale

  before_filter :reload_config_et_roles
  before_filter :require_login, 
                :except => [ :sign_up, :sign_in, :sign_out, 
                             :recover_password, :reset_password, 
                             :quick_edit ]

  before_filter :check_if_user_can_perform_action_on_resource_without_model, 
                :except => [ :sign_up, :sign_in, :sign_out, 
                             :dashboard, 
                             :recover_password, :reset_password, 
                             :quick_edit, :set_locale ]

  before_filter :recover_password_disabled?, 
                :only => [ :recover_password, :reset_password ]

  ##
  # Application Dashboard
  #
  def dashboard
    flash[:notice] = t("There are not defined applications in config/typus/*.yml.") if Typus.applications.empty?
  end

  ##
  # Login
  #
  def sign_in

    redirect_to admin_sign_up_path and return if Typus.user_class.count.zero?

    if request.post?
      user = Typus.user_class.authenticate(params[:user][:email], params[:user][:password])
      if user
        session[:typus] = user.id
        redirect_to params[:back_to] || admin_dashboard_path
      else
        flash[:error] = t("The Email and/or Password you entered is invalid.")
        redirect_to admin_sign_in_path
      end
    end

  end

  ##
  # Logout and redirect to +admin_login+.
  #
  def sign_out
    session[:typus] = nil
    redirect_to admin_sign_in_path
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
        redirect_to admin_sign_in_path
      else
        redirect_to admin_recover_password_path
      end
    end
  end

  ##
  # Available if Typus::Configuration.options[:recover_password] is
  # enabled. Enabled by default.
  #
  def reset_password
    @user = Typus.user_class.find_by_token!(params[:token])
    if request.post?
      if @user.update_attributes(params[:user])
        flash[:success] = t("You can login with your new password.")
        redirect_to admin_sign_in_path
      else
        flash[:error] = t("Passwords don't match.")
        redirect_to admin_reset_password_path, :token => params[:token]
      end
    end
  end

  def sign_up

    redirect_to admin_sign_in_path and return unless Typus.user_class.count.zero?

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
        redirect_to admin_dashboard_path
      else
        flash[:error] = t("That doesn't seem like a valid email address.")
        redirect_to admin_sign_up_path
      end

    else

      flash[:notice] = t("Enter your email below to create the first user.")

    end

  end

  def quick_edit

    render :text => '' and return unless session[:typus]

    url = url_for :controller => "admin/#{params[:resource]}", 
                  :action => 'edit', 
                  :id => params[:id]

    @content = <<-HTML
var links = '';
links += '<div id="quick_edit">';
links += '<a href=\"#{url}\">#{params[:message]}</a>';
links += '</div>';
links += '<style type="text/css">';
links += '<!--';
links += '#quick_edit { font-size: 11px; float: right; position: fixed; right: 0px; background: #{params[:color]}; margin: 5px; padding: 3px 5px; }';
links += '#quick_edit a { color: #FFF; font-weight: bold; }'
links += '-->';
links += '</style>';
document.write(links);
      HTML

    render :text => @content

  end

private

  def recover_password_disabled?
    redirect_to admin_sign_in_path unless Typus::Configuration.options[:recover_password]
  end

  def select_layout
    [ 'sign_up', 'sign_in', 'sign_out', 'recover_password', 'reset_password' ].include?(action_name) ? 'typus' : 'admin'
  end

end