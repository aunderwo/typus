class << ActionController::Routing::Routes;self;end.class_eval do
  define_method :clear!, lambda {}
end

ActionController::Routing::Routes.draw do |map|

  map.with_options :controller => 'typus', :path_prefix => Typus::Configuration.options[:prefix] do |i|
    i.typus_dashboard '', :action => 'dashboard'
    i.typus_overview 'overview', :action => 'overview'
    i.typus_login 'login', :action => 'login'
    i.typus_logout 'logout', :action => 'logout'
    i.typus_setup 'setup', :action => 'setup'
    i.typus_recover_password 'recover_password', :action => 'recover_password'
    i.typus_reset_password 'reset_password', :action => 'reset_password'
  end

  map.namespace :admin do |admin|
    Typus.models.each do |m|
      collection = {}
      m.typus_actions_for(:index).each { |a| collection[a] = :any }
      member = { :position => :any, :toggle => :any, :relate => :any, :unrelate => :any }
      m.typus_actions_for(:edit).each { |a| member[a] = :any }
      admin.resources m.tableize, :collection => collection, :member => member, :path_prefix => Typus::Configuration.options[:prefix]
    end
  end

end