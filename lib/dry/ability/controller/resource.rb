# frozen_string_literal: true

require "dry/initializer"
require "dry/ability/t"

module Dry
  module Ability
    module Controller
      # @private
      class Resource
        include Initializer[undefined: false].define -> do
          param :mediator,   T.Instance(ResourceMediator)
          param :controller, T.Instance(Controller::Mixin)

          option :action_name,     T['params.symbol'], default: proc { @controller.action_name.to_sym }
          option :controller_name, T['params.symbol'], default: proc { @controller.controller_name.to_sym }
          option :is_member,       T['bool'],          default: proc { @mediator.member_action?(action_name, params) }
          option :is_collection,   T['bool'],          default: proc { @mediator.collection_action?(action_name) }
        end

        alias_method :member_action?, :is_member
        alias_method :collection_action?, :is_collection

        delegate :params, to: :controller
        delegate :name, to: :mediator
        delegate_missing_to :mediator

        def call
          @controller.instance_variable_set(:@_ability_resource, self)
          retval = nil
          @mediator.sequence.each do |sym|
            retval = public_send(sym)
          end
          retval
        end

        def load_and_authorize_resource
          load_resource
          authorize_resource
        end

        def load_resource
          return if skip?(:load)
          if load_instance?
            self.resource_instance ||= load_resource_instance
          elsif collection_action?
            self.collection_instance ||= load_collection
          end
        end

        def authorize_resource
          return if skip?(:authorize)
          @controller.authorize!(authorization_action, resource_instance || resource_class_with_parent)
        end

        def parent?
          @mediator.parent.nil? ? @mediator.collection_name != controller_name.to_sym : @mediator.parent?
        end

        def skip?(behavior)
          options = @controller.class.cancan_skipper.dig(behavior, name)
          return false if options.nil?
          options.blank? &&
            options[:except] && !action_exists_in?(options[:except]) ||
            action_exists_in?(options[:only])
        end

        def load_resource_instance
          raise NotImplementedError
        end

        def resource_base
          raise NotImplementedError
        end

        def load_instance?
          parent? || member_action?
        end

        # def load_collection?
        #   collection_action?
        #   # current_ability.has_scope?(authorization_action, resource_class) || resource_base.respond_to?(:accessible_by)
        # end

        def load_collection
          current_ability.scope_for(authorization_action, resource_class) do
            resource_base.accessible_by(current_ability, authorization_action)
          end
        end

        def assign_attributes(resource)
          resource.send(:"#{parent_name}=", parent_resource) if singleton? && parent_resource
          initial_attributes.each do |attr_name, value|
            resource.send(:"#{attr_name}=", value)
          end
          resource
        end

        def initial_attributes
          current_ability.attributes_for(@action_name, resource_class).delete_if do |key, _|
            resource_params && resource_params.include?(key)
          end
        end

        def authorization_action
          parent? ? @mediator.parent_action : @action_name
        end

        def id_param
          params[@mediator.id_param_key] if params.key?(@mediator.id_param_key)
        end

        # Returns the class used for this resource. This can be overriden by the :class option.
        # If +false+ is passed in it will use the resource name as a symbol in which case it should
        # only be used for authorization, not loading since there's no class to load through.
        def resource_class
          case class_name
          when false then
            name.to_sym
          when String then
            class_name.constantize
          else
            raise ArgumentError, "unexpected class_name: #{class_name}"
          end
        end

        def resource_class_with_parent
          parent_resource ? { parent_resource => resource_class } : resource_class
        end

        def resource_instance=(instance)
          @controller.instance_variable_set(:"@#{instance_name}", instance)
        end

        def resource_instance
          @controller.instance_variable_get(:"@#{instance_name}") if load_instance?
        end

        def collection_instance=(instance)
          @controller.instance_variable_set(:"@#{collection_name}", instance)
        end

        def collection_instance
          @controller.instance_variable_get(:"@#{collection_name}")
        end

        def parent_name
          return @parent_name if defined?(@parent_name)
          @parent_name = @mediator.through unless parent_resource.nil?
        end

        # The object to load this resource through.
        def parent_resource
          return @parent_resource if defined?(@parent_resource)
          @parent_resource = if @mediator.through
            if @controller.instance_variable_defined? :"@#{@mediator.through}"
              @controller.instance_variable_get(:"@#{@mediator.through}")
            elsif @controller.respond_to?(@mediator.through, true)
              @controller.send(@mediator.through)
            end
          end
        end

        def current_ability
          @controller.send(:current_ability)
        end

        def resource_params
          if parameters_require_sanitizing? && params_method.present?
            case params_method
            when Symbol then
              @controller.send(params_method)
            when String then
              @controller.instance_eval(params_method)
            when Proc then
              params_method.call(@controller)
            end
          else
            resource_params_by_namespaced_name
          end
        end

        def parameters_require_sanitizing?
          @mediator.save_actions.include?(@action_name) || resource_params_by_namespaced_name.present?
        end

        def resource_params_by_namespaced_name
          return @resource_params_by_namespaced_name if defined?(@resource_params_by_namespaced_name)
          @resource_params_by_namespaced_name =
            if params.key?(@mediator.instance_name)
              params[@mediator.instance_name]
            elsif params.key?(key = extract_key(@mediator.class_name))
              params[key]
            else
              params[name]
            end
        end

        def params_method
          @params_method ||= @mediator.params_method || begin
            [:"#{@action_name}_params", :"#{name}_params", :resource_params].
              detect { |method| @controller.respond_to?(method, true) }
          end
        end

        private

        def action_exists_in?(options)
          Array.wrap(options).include?(@controller.action_name.to_sym)
        end

        def extract_key(value)
          value.to_s.underscore.tr(?/, ?_)
        end
      end
    end
  end
end
