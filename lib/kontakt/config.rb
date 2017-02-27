module Kontakt
  # Vkontakte application configuration class
  class Config
    attr_accessor :config

    class << self
      # A shortcut to access default configuration stored in RAILS_ROOT/config/vkontakte.yml
      def default
        @@default ||= self.new(load_default_config_from_file)
      end

      def load_default_config_from_file
        config_data = YAML.load(
          ERB.new(
            File.read(::Rails.root.join("config", "vkontakte.yml"))
          ).result
        )[::Rails.env]

        raise NotConfigured.new("Unable to load configuration for #{ ::Rails.env } from config/vkontakte.yml") unless config_data

        config_data
      end
    end

    def initialize(options = {})
      self.config = options.to_options
    end

    # Defining methods for quick access to config values
    %w{app_id app_secret service_token api_version namespace callback_domain}.each do |attribute|
      class_eval %{
        def #{ attribute }
          config[:#{ attribute }]
        end
      }
    end

    # URL of the application canvas page
    def canvas_page_url(protocol)
      "#{ protocol }www.vk.com/app#{ app_id }"
    end

    # Application callback URL
    def callback_url(protocol)
      protocol + callback_domain
    end

    def oauth_client
      @oauth_client ||= Kontakt::Api::Client.new(nil)
    end

    def api_client
      @api_client ||= Kontakt::Api::Client.new(service_token)
    end

    # Fetches application access token
    # Deprecated after 01.04.2017: https://vk.com/dev/service_token
    def app_access_token
      @app_access_token ||= oauth_client.get_app_access_token(config)
    end
  end
end