require 'kontakt/rails/helpers/url_helper'

module Kontakt
  module Rails
    module Controller
      module UrlRewriting
        include Kontakt::Rails::Helpers::UrlHelper

        def self.included(base)
          base.class_eval do
            helper_method(:vk_canvas_page_url, :vk_callback_url)
          end
        end

        protected

        # A helper to generate an URL of the application canvas page URL
        #
        # @param protocol A request protocol, should be either 'http://' or 'https://'.
        #                 Defaults to current protocol.
        def vk_canvas_page_url(protocol = nil)
          kontakt.canvas_page_url(protocol || request.protocol)
        end

        # A helper to generate an application callback URL
        #
        # @param protocol A request protocol, should be either 'http://' or 'https://'.
        #                 Defaults to current protocol.
        def vk_callback_url(protocol = nil)
          kontakt.callback_url(protocol || request.protocol)
        end
      end
    end
  end
end
