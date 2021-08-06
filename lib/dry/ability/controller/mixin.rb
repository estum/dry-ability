# frozen_string_literal: true

module Dry
  module Ability
    module Controller
      module Mixin
        extend ActiveSupport::Concern

        included do
          class_attribute :ability_class, instance_accessor: false
          helper_method :can?, :cannot?, :current_ability if respond_to? :helper_method
        end

        # Raises a Dry::Ability::AccessDenied exception if the current_ability cannot
        # perform the given action. This is usually called in a controller action or
        # before filter to perform the authorization.
        #
        #   def show
        #     @article = Article.find(params[:id])
        #     authorize! :read, @article
        #   end
        #
        # A :message option can be passed to specify a different message.
        #
        #   authorize! :read, @article, :message => "Not authorized to read #{@article.name}"
        #
        # You can also use I18n to customize the message. Action aliases defined in Ability work here.
        #
        #   en:
        #     unauthorized:
        #       manage:
        #         all: "Not authorized to %{action} %{subject}."
        #         user: "Not allowed to manage other user accounts."
        #       update:
        #         project: "Not allowed to update this project."
        #
        # You can rescue from the exception in the controller to customize how unauthorized
        # access is displayed to the user.
        #
        #   class ApplicationController < ActionController::Base
        #     rescue_from CanCan::AccessDenied do |exception|
        #       redirect_to root_url, :alert => exception.message
        #     end
        #   end
        #
        # See the CanCan::AccessDenied exception for more details on working with the exception.
        #
        # See the load_and_authorize_resource method to automatically add the authorize! behavior
        # to the default RESTful actions.
        def authorize!(*args)
          @_authorized = true
          current_ability.authorize!(*args)
        end

        # Creates and returns the current user's ability and caches it. If you
        # want to override how the Ability is defined then this is the place.
        # Just define the method in the controller to change behavior.
        #
        #   def current_ability
        #     # instead of Ability.new(current_user)
        #     @current_ability ||= UserAbility.new(current_account)
        #   end
        #
        # Notice it is important to cache the ability object so it is not
        # recreated every time.
        def current_ability
          @current_ability ||= ability_class.new(current_user)
        end

        # @!method can?(*args)
        #   @see Dry::Ability::Mixin#can?
        delegate :can?, to: :current_ability

        # @!method cannot?(*args)
        #   @see Dry::Ability::Mixin#cannot?
        delegate :cannot?, to: :current_ability
      end
    end
  end
end