# frozen_string_literal: true

module Dry
  module Ability
    module RuleInterface
      def call(account, object)
        raise NotImplementedError
      end

      def [](account, object)
        call(account, object)
      end

      def |(other)
        raise NotImplementedError
      end

      def attributes_for(account)
        raise NotImplementedError
      end

      def scope_for(account)
        raise NotImplementedError
      end
    end
  end
end
