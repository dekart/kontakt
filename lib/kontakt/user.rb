module Kontakt
  class User
    class UnsupportedAlgorithm < StandardError; end
    class InvalidSignature < StandardError; end

    class << self
      # Creates an instance of Kontakt::User using application config and request parameters
      def from_vk_params(config, params)
        params = decrypt(config, params) if params.is_a?(String)

        return unless params && params['viewer_id'] && signature_valid?(config, params)

        new(params)
      end

      def decrypt(config, encrypted_params)
        encryptor = ActiveSupport::MessageEncryptor.new("secret_key_#{config.app_id}_#{config.app_secret}")

        encryptor.decrypt_and_verify(encrypted_params)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
        ::Rails.logger.error "\nError while decoding vkontakte params: \"#{ encrypted_params }\""

        nil
      end

      def signature_valid?(config, params)
        !params['auth_key'].blank? && params['auth_key'] == auth_key(config, params)
      end

      def auth_key(config, params)
        Digest::MD5.hexdigest(
          [config.app_id, params['viewer_id'], config.app_secret].join('_')
        )
      end
    end

    def initialize(options = {})
      @options = options
    end

    def authenticated?
      !sid.blank?
    end

    def uid
      @options['viewer_id'].to_i
    end

    def session_key
      @options['sid']
    end

    def session_secret_key
      @options['secret']
    end

    def access_token
      @options['access_token']
    end

    def referrer
      @options['referrer']
    end

    # Vkontakte API client instantiated with user's session key
    def api_client
      @api_client ||= Kontakt::Api::Client.new(session_key, session_secret_key)
    end
  end
end
