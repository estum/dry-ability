# frozen_string_literal: true

require "dry/types"

module Dry
  module Ability
    # T is for Types
    module T
      extend Types::BuilderMethods

      def self.[](*args, &block)
        Types[*args, &block]
      end

      def self.Key(input)
        case input
        when String, Symbol, Module, Class; input.to_s
        else Key(input.class)
        end
      end

      def self.WrappedArray(type)
        Array(type) << ArrayWrap
      end

      ArrayWrap       = Array.method(:wrap)

      CoercKey        = Types['string'] << method(:Key)

      Actions         = WrappedArray(Types['params.symbol'])

      Subjects        = WrappedArray(CoercKey)

      Hash            = Types['hash']

      ActionOrSubject = Types['symbol'].enum(:action, :subject)

      RulesMapping    = Hash.map(CoercKey, Subjects)

      Callable        = Interface(:call)

      Queriable       = Interface(:where)
    end
  end
end
