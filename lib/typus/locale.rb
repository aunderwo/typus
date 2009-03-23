module Typus

  module Locale

    def set_locale
      if params[:locale]
        I18n.locale = params[:locale]
        session[:typus_locale] = params[:locale]
        redirect_to :back
      else
        I18n.locale = session[:typus_locale] || Typus.default_locale
      end
    end

  end

end