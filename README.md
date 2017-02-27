Kontakt
===========

Provides a set of classes, methods, and helpers to ease development of vk.com applications with Rails.

Installation
------------

In order to install Kontakt you should add it to your Gemfile:

    gem 'kontakt'

Usage
-----

**Accessing Current User**

Current Vkontakte user data can be accessed using the ```current_vk_user``` method:

    class UsersController < ApplicationController
      def profile
        @user = User.find_by_social_id(current_vk_user.uid)
      end
    end

This method is also accessible as a view helper.

**Application Configuration**

In order to use Kontakt you should set a default configuration for your Vkontakte application. The config file should be placed at RAILS_ROOT/config/vkontakte.yml

Sample config file:

    development:
      app_id: ...
      app_secret: ...
      service_token: ...
      api_version: 5.52
      namespace: ...
      callback_domain: ...

    test:
      app_id: ...
      app_secret: ...
      service_token: ...
      api_version: 5.52
      namespace: ...
      callback_domain: ...
