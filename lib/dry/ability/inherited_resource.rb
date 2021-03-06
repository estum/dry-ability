# frozen_string_literal: true

require "dry/ability/controller/resource"

module Dry
  module Ability
    # For use with Inherited Resources
    class InheritedResource < Controller::Resource # :nodoc:
      def load_resource_instance
        if parent?
          @controller.send :association_chain
          @controller.instance_variable_get(:"@#{instance_name}")
        elsif new_actions.include?(@action_name)
          resource = @controller.send :build_resource
          assign_attributes(resource)
        else
          @controller.send :resource
        end
      end

      def resource_base
        @controller.send :end_of_association_chain
      end
    end
  end
end
