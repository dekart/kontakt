module Kontakt
  class Engine < ::Rails::Engine
    initializer "kontakt.middleware" do |app|
      app.middleware.insert_before(Rack::Head, Kontakt::Middleware)
    end

    initializer "kontakt.controller_extension" do
      ActiveSupport.on_load :action_controller do
        ActionController::Base.send(:include, Kontakt::Rails::Controller)
      end
    end
  end
end
