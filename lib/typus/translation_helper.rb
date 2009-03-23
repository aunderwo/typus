require 'action_view/helpers/tag_helper'

module ActionView

  module Helpers

    module TranslationHelper

      def translate(key, options = {})
        options[:raise] = true
        I18n.translate(key, options)
      rescue I18n::MissingTranslationData => e
        key
      end

      alias :t :translate

    end

  end

end