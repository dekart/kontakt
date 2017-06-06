module Kontakt
  module Rails
    module Helpers
      module JavascriptHelper
        # A helper to integrate Vkontakte JS Api to the current page. Generates a
        # JavaScript code that initializes Javascript client for the current application.
        #
        # @param &block   A block of JS code to be inserted in addition to client initialization code.
        def vk_connect_js(&block)
          if vk_mobile?
            vk_mobile_connect_js(&block)
          else
            vk_iframe_conect_js(&block)
          end
        end

        def vk_iframe_conect_js(&block)
          extra_js = capture(&block) if block_given?

          init_js = <<-JAVASCRIPT
            VK.init(
              function() {
                #{extra_js}
              },
              function(error) {
                console.log('Error initializing VK');
                console.log(error);
              },
              '5.52'
            );
          JAVASCRIPT

          js_url = "//vk.com/js/api/xd_connection.js?2"

          js = <<-CODE
            <script src="#{ js_url }" type="text/javascript"></script>
          CODE

          js << <<-CODE
            <script type="text/javascript">
              if(typeof VK !== 'undefined') {
                #{init_js}
              }
            </script>
          CODE

          js = js.html_safe

          if block_given? && ::Rails::VERSION::STRING.to_i < 3
            concat(js)
          else
            js
          end
        end

        def vk_mobile_connect_js(&block)
          extra_js = capture(&block) if block_given?

          init_js = <<-JAVASCRIPT
            VK.init(
              function() {
                #{extra_js}
              },
              function(error) {
                console.log('Error initializing VK');
                console.log(error);
              },
              '5.60'
            );
          JAVASCRIPT

          #js_url = "//vk.com/js/api/mobile_sdk.js"
          # в mobile_sdk баг, так что загружаем исправленную версию из нашего проекта
          js_url = "/assets/mobile_sdk.js"

          js = <<-CODE
            <script src="#{ js_url }" type="text/javascript"></script>
          CODE

          js << <<-CODE
            <script type="text/javascript">
              if(typeof VK !== 'undefined') {
                #{init_js}
              }
            </script>
          CODE

          js = js.html_safe

          if block_given? && ::Rails::VERSION::STRING.to_i < 3
            concat(js)
          else
            js
          end
        end
      end
    end
  end
end
