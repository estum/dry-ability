# frozen_string_literal: true

require "dry/ability/resource_mediator"
require "dry/ability/controller/mixin"
require "dry/ability/controller/dsl"
require "dry/ability/controller_resource"
require "dry/ability/inherited_resource" if defined?(::InheritedResources)

module Dry
  module Ability
    module Controller
      extend ActiveSupport::Concern

      include Controller::Mixin

      module ClassMethods
        include Controller::DSL
      end
    end
  end
end