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
      REST_API_URL = "https://api.vk.com/method"

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

      def signed_call_params(method, specific_params = {})
        params = specific_params.symbolize_keys

        params.merge!(:api_version => Kontakt::Config.default.api_version) unless Kontakt::Config.default.api_version.nil?
        params.merge!(:access_token => access_token) if access_token

        puts "~~ signed_call_params ~~"
        puts params
        puts "~~~~~~~~"
        params
        #params = {
        #  :method          => method,
        #  :format          => 'json'
        #}.merge(specific_params.symbolize_keys)
      end

      protected

      def connection(token)
        Faraday.new(REST_API_URL) do |connect|
          connect.request :oath2, token unless token.nil?
          connect.request :multipart
          connect.request :url_encoded
        end
      end

      def make_request(method, specific_params)
        method_name = specific_params.delete(:method_name)

        puts "~~ make_request ~~"
        puts method
        puts method_name
        puts specific_params
        puts "~~~~~~~~"

        connection(token).send(
          method, method_name, signed_call_params(method, specific_params)
        )
        #connection(token).get do |request|
        #  request.params = signed_call_params(method, specific_params)
        #end
      rescue Exception => e
        ::Rails.logger.error("Exception: #{e.inspect}")
      end

    end
  end
end