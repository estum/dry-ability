# frozen_string_literal: true

require "dry/ability/controller/resource"

module Dry
  module Ability
    # Handle the load and authorization controller logic
    # so we don't clutter up all controllers with non-interface methods.
    # This class is used internally, so you do not need to call methods directly on it.
    class ControllerResource < Controller::Resource
      def load_resource_instance
        if !parent? && @mediator.new_actions.include?(@action_name)
          build_resource
        elsif @mediator.id_param_key || @mediator.singleton?
          find_resource
        end
      end

      def build_resource
        resource = resource_base.new(resource_params || {})
        assign_attributes(resource)
      end

      def find_resource
        if singleton? && parent_resource.respond_to?(name)
          parent_resource.public_send(name)
        elsif find_by.present?
          if resource_base.respond_to? find_by
            resource_base.public_send(find_by, id_param)
          else
            resource_base.find_by(find_by => id_param)
          end
        else
          resource_base.find(id_param)
        end
      end

      # The object that methods (such as "find", "new" or "build") are called on.
      # If the :through option is passed it will go through an association on that instance.
      # If the :shallow option is passed it will use the resource_class if there's no parent
      # If the :singleton option is passed it won't use the association because it needs to be handled later.
      def resource_base
        if @mediator.through
          resource_base_through
        else
          resource_class
        end
      end

      def resource_base_through
        if parent_resource
          @mediator.singleton? ? resource_class : parent_resource.public_send(@mediator.through_association)
        elsif @mediator.shallow?
          resource_class
        else
          # maybe this should be a record not found error instead?
          raise AccessDenied.new(nil, authorization_action, resource_class)
        end
      end
    end
  end
end