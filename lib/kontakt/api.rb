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
        body.is_a?(Hash) && body['error_code'].present?
      end
    end

    class APIError < StandardError
      attr_accessor :vk_error_type

      def initialize(details = {})
        self.vk_error_type = details["type"]
        super("#{vk_error_type}: #{details["message"]}")
      end
    end

    class Client
      REST_API_URL = "https://api.vk.com/method/"

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

      protected

      def make_request(method, specific_params)
        puts "~~ make_request ~~"
        puts method
        puts specific_params
        puts "~~~~~~~~"

        Faraday.new(REST_API_URL + method).get do |request|
          request.params = signed_call_params(method, specific_params)
        end
      rescue Exception => e
        ::Rails.logger.error("Exception: #{e.inspect}")
      end

      def signed_call_params(method, specific_params = {})
        params = specific_params.symbolize_keys

        params.merge!(:v => Kontakt::Config.default.api_version) unless Kontakt::Config.default.api_version.nil?
        params.merge!(:access_token => access_token) if access_token

        puts "~~ signed_call_params ~~"
        puts params
        puts "~~~~~~~~"
        params
      end
    end
  end
end