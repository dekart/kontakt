require 'faraday'

module Kontakt
  module Api
    class Response
      attr_reader :status, :body, :headers

      def initialize(status, body, headers)
        @status  = status
        @body    = body
        @headers = headers
      end

      def error?
        body.is_a?(Hash) && body['error'].present?
      end
    end

    class APIError < StandardError
      attr_accessor :vk_error_type

      def initialize(details = {})
        self.vk_error_type = details["error_code"]
        super("#{vk_error_type}: #{details["error_msg"]}")
      end
    end

    class Client
      REST_API_URL = "https://api.vk.com/method/"
      OAUTH_URL = "https://oauth.vk.com/access_token"

      attr_accessor :access_token

      def initialize(access_token = nil)
        self.access_token = access_token
      end

      def call(method, specific_params = {})
        result = make_request(method, specific_params)

        raise APIError.new({"type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}"}) if result.status >= 500

        body = begin
          JSON.parse(result.body.to_s)
        rescue Exception => e
          result.body.to_s.gsub(/\"/, "")
        end

        Kontakt::Api::Response.new(result.status.to_i, body, result.headers)
      end

      def get_app_access_token(config)
        result = make_oauth_request(config)

        raise APIError.new({"type" => "HTTP #{result.status.to_s}", "message" => "Response body: #{result.body}"}) if result.status >= 500

        body = begin
          JSON.parse(result.body.to_s)
        rescue Exception => e
          result.body.to_s.gsub(/\"/, "")
        end

        body["access_token"] unless body['error'].present?
      end

      protected

      def make_request(method, specific_params)
        Faraday.new(REST_API_URL + method).get do |request|
          request.params = signed_call_params(method, specific_params)
        end
      rescue Exception => e
        ::Rails.logger.error("Exception: #{e.inspect}")
      end

      def make_oauth_request(params)
        params.symbolize_keys!

        Faraday.new(OAUTH_URL).get do |request|
          request.params = {
            :client_id     => params[:app_id],
            :client_secret => params[:app_secret],
            :v             => params[:api_version],
            :grant_type    => "client_credentials"
          }
        end
      rescue Exception => e
        ::Rails.logger.error("Exception: #{e.inspect}")
      end

      def signed_call_params(method, specific_params = {})
        params = specific_params.symbolize_keys

        params.merge!(:v => Kontakt::Config.default.api_version) unless Kontakt::Config.default.api_version.nil?
        params.merge!(:access_token  => access_token) if access_token
        params.merge!(:client_secret => Kontakt::Config.default.app_secret) if method.split('.').first == 'secure'

        params
      end
    end
  end
end