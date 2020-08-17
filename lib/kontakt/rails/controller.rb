require 'kontakt/rails/controller/url_rewriting'
require 'kontakt/rails/controller/redirects'

module Kontakt
  module Rails

    # Rails application controller extension
    module Controller
      def self.included(base)
        base.class_eval do
          include Kontakt::Rails::Controller::UrlRewriting
          include Kontakt::Rails::Controller::Redirects

          helper_method(:kontakt, :vk_params, :vk_signed_params, :params_without_vk_data,
            :current_vk_user, :vk_canvas?, :vk_mobile?
          )

          helper Kontakt::Rails::Helpers
        end
      end

      protected

      KONTAKT_PARAM_NAMES = %w{api_url api_id user_id sid secret group_id viewer_id viewer_type is_app_user is_secure
        auth_key language parent_language api_result api_settings access_token hash lc_name
        ad_info ads_app_id api_script}

      RAILS_PARAMS = %w{controller action}

      # Accessor to current application config. Override it in your controller
      # if you need multi-application support or per-request configuration selection.
      def kontakt
        Kontakt::Config.default
      end

      # A hash of params passed to this action, excluding secure information passed by Vkontakte
      def params_without_vk_data
        params.except(*KONTAKT_PARAM_NAMES)
      end

      # params coming directly from Vkontakte
      def vk_params
        params.except(*RAILS_PARAMS)
      end

      # encrypted vkontakte params
      def vk_signed_params
        if vk_params['access_token'].present?
          encrypt_params(vk_params)
        else
          request.env["HTTP_SIGNED_PARAMS"] || request.params['signed_params'] || flash[:signed_params]
        end
      end

      # Accessor to current vkontakte user. Returns instance of Kontakt::User
      def current_vk_user
        @current_vk_user ||= fetch_current_vk_user
      end

      # Did the request come from canvas app
      def vk_canvas?
        vk_params['access_token'].present? || request.env['HTTP_SIGNED_PARAMS'].present? || flash[:signed_params].present?
      end

      def vk_mobile?
        params[:platform] != "web"
      end

      private

      def fetch_current_vk_user
        Kontakt::User.from_vk_params(kontakt, vk_params['access_token'].present? ? vk_params : vk_signed_params)
      end

      def encrypt_params(params)
        encryptor = ActiveSupport::MessageEncryptor.new("secret_key_#{kontakt.app_id}_#{kontakt.app_secret}"[0..31])

        encryptor.encrypt_and_sign(params)
      end

      def decrypt_params(encrypted_params)
        encryptor = ActiveSupport::MessageEncryptor.new("secret_key_#{kontakt.app_id}_#{kontakt.app_secret}"[0..31])

        encryptor.decrypt_and_verify(encrypted_params)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end
    end
  end
end
