# frozen_string_literal: true

require "concurrent/map"

module Dry
  module Ability
    module Controller
      module DSL
        private def inherited(klass)
          super(klass)
          klass.instance_variable_set(:@_resource_mediators, @_resource_mediators.dup)
          klass.instance_variable_set(:@_cancan_skipper, @_cancan_skipper.dup)
          klass
        end

        # @api private
        def set_resource_mediator_callback(name, **opts)
          callback_options = opts.extract!(:only, :except, :if, :unless, :prepend)
          @_resource_mediators ||= Concurrent::Map.new
          @_resource_mediators.fetch_or_store(name) do
            ResourceMediator.new(name, controller_path, __callee__, **opts).
              tap { |m| before_action m, callback_options }
          end.sequence << __callee__
        end

        # @!method load_and_authorize_resource(*args, **opts)
        alias_method :load_and_authorize_resource, :set_resource_mediator_callback

        # @!method load_resource(*args, **opts)
        #   @see #load_and_authorize_resource
        #   @option opts [Array<String,Symbol>] :only Only applies before filter to given actions.
        #   @option opts [Array<String,Symbol>] :except Does not apply before filter to given actions.
        #   @option opts [Boolean] :prepend Prepend callback
        #   @option opts [Symbol] :through Load this resource through another one.
        #   @option opts [Symbol] :through_association
        #   @option opts [Boolean] :shallow (false) allow this resource to be loaded directly when parent is +nil+
        #   @option opts [Boolean] :singleton (false) singleton resource through a +has_one+ association.
        #   @option opts [Boolean] :parent defaults to +true+ if a resource name is given which does not match the controller.
        #   @option opts [String,Class] :class The class to use for the model (string or constant).
        #   @option opts [String,Symbol] :instance_name The name of the instance variable to load the resource into.
        #   @option opts [Symbol] :find_by will use find_by(permalink: params[:id])
        #   @option opts [Symbol] :id_param Find using a param key other than :id. For example:
        #   @option opts [Array<Symbol>] :collection External actions as resource collection
        #   @option opts [Array<Symbol>] :new External actions as new resource
        alias_method :load_resource, :set_resource_mediator_callback

        # @!method authorize_resource(*args, **opts)
        #   @see #load_and_authorize_resource
        #   @option opts [Array<String,Symbol>] :only Only applies before filter to given actions.
        #   @option opts [Array<String,Symbol>] :except Does not apply before filter to given actions.
        #   @option opts [Boolean] :prepend Prepend callback
        #   @option opts [Boolean] :singleton (false) singleton resource through a +has_one+ association.
        #   @option opts [Boolean] :parent (true)
        #   @option opts [String,Class] :class The class to use for the model (string or constant).
        #   @option opts [String,Symbol] :instance_name The name of the instance variable to load the resource into.
        #   @option opts [Symbol] :through Authorize conditions on this parent resource when instance isn't available.
        alias_method :authorize_resource, :set_resource_mediator_callback

        undef_method :set_resource_mediator_callback

        # Skip both the loading and authorization behavior of CanCan for this given controller. This is primarily
        # useful to skip the behavior of a superclass. You can pass :only and :except options to specify which actions
        # to skip the effects on. It will apply to all actions by default.
        #
        #   class ProjectsController < SomeOtherController
        #     skip_load_and_authorize_resource :only => :index
        #   end
        #
        # You can also pass the resource name as the first argument to skip that resource.
        def skip_load_and_authorize_resource(*args)
          skip_load_resource(*args)
          skip_authorize_resource(*args)
        end

        # Skip the loading behavior of CanCan. This is useful when using +load_and_authorize_resource+ but want to
        # only do authorization on certain actions. You can pass :only and :except options to specify which actions to
        # skip the effects on. It will apply to all actions by default.
        #
        #   class ProjectsController < ApplicationController
        #     load_and_authorize_resource
        #     skip_load_resource :only => :index
        #   end
        #
        # You can also pass the resource name as the first argument to skip that resource.
        def skip_load_resource(name, **options)
          cancan_skipper[:load][name] = options
        end

        # Skip the authorization behavior of CanCan. This is useful when using +load_and_authorize_resource+ but want to
        # only do loading on certain actions. You can pass :only and :except options to specify which actions to
        # skip the effects on. It will apply to all actions by default.
        #
        #   class ProjectsController < ApplicationController
        #     load_and_authorize_resource
        #     skip_authorize_resource :only => :index
        #   end
        #
        # You can also pass the resource name as the first argument to skip that resource.
        def skip_authorize_resource(name, **options)
          cancan_skipper[:authorize][name] = options
        end

        # Add this to a controller to ensure it performs authorization through +authorized+! or +authorize_resource+ call.
        # If neither of these authorization methods are called,
        # a CanCan::AuthorizationNotPerformed exception will be raised.
        # This is normally added to the ApplicationController to ensure all controller actions do authorization.
        #
        #   class ApplicationController < ActionController::Base
        #     check_authorization
        #   end
        #
        # See skip_authorization_check to bypass this check on specific controller actions.
        #
        # Options:
        # [:+only+]
        #   Only applies to given actions.
        #
        # [:+except+]
        #   Does not apply to given actions.
        #
        # [:+if+]
        #   Supply the name of a controller method to be called.
        #   The authorization check only takes place if this returns true.
        #
        #     check_authorization :if => :admin_controller?
        #
        # [:+unless+]
        #   Supply the name of a controller method to be called.
        #   The authorization check only takes place if this returns false.
        #
        #     check_authorization :unless => :devise_controller?
        #
        def check_authorization(**options)
          after_action(**options) do |controller|
            next if controller.instance_variable_defined?(:@_authorized)
            raise AuthorizationNotPerformed,
                  'This action failed the check_authorization because it does not authorize_resource. '\
                  'Add skip_authorization_check to bypass this check.'
          end
        end

        # Call this in the class of a controller to skip the check_authorization behavior on the actions.
        #
        #   class HomeController < ApplicationController
        #     skip_authorization_check :only => :index
        #   end
        #
        # Any arguments are passed to the +before_action+ it triggers.
        def skip_authorization_check(*args)
          before_action(*args) do |controller|
            controller.instance_variable_set(:@_authorized, true)
          end
        end

        def cancan_skipper
          @_cancan_skipper ||= { authorize: {}, load: {} }
        end
      end
    end
  end
end
