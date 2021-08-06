# frozen_string_literal: true

require 'active_support/concern'
require 'active_support/core_ext/object/with_options'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/class/attribute'

require 'dry/ability/version'
require 'dry/ability/exceptions'
require "dry/ability/f"
require "dry/ability/t"
require "dry/ability/key"
require 'dry/ability/rules_builder'

module Dry
  # Mixin class with DSL to define abilities
  #
  # @example
  #
  #   class Ability
  #     include Dry::Ability.define -> do
  #       map_subject! :public => %w(Post Like Comment)
  #
  #       map_action!  :read   => %i(index show),
  #                    :create => %i(new),
  #                    :update => %i(edit),
  #                    :crud   => %i(index create read show update destroy),
  #                    :change => %i(update destroy)
  #
  #       can :read, :public
  #       can :
  #
  #     end
  #   end
  module Ability
    # @private
    module DSL
      def define(proc = nil, **options, &block)
        rules = RulesBuilder.new(**options)
        rules.instance_exec(&(proc || block))
        [self, rules.mixin]
      end
    end

    extend ActiveSupport::Concern
    extend DSL

    module ClassMethods
      attr_reader :_container
      alias_method :rules, :_container
    end

    attr_reader :account

    def initialize(account)
      @account = account
    end

    def authorize!(action, subject, message: nil)
      if can?(action, subject)
        subject
      else
        raise AccessDenied.new(message, action, subject)
      end
    end

    def can?(action, subject)
      rules = resolve_rules(action, subject) do
        return false
      end

      rules.reduce(true) do |result, rule|
        result && rule[@account, subject]
      end
    end

    def cannot?(action, subject, *args)
      !can?(action, subject, *args)
    end

    def attributes_for(action, subject)
      rules = resolve_rules(action, subject) do
        return {}
      end
      rules.reduce({}) do |result, rule|
        result.merge!(rule.attributes_for(@account, subject)); result
      end
    end

    def scope_for(action, subject)
      rules = resolve_rules(action, subject) do
        return yield if block_given?
        if subject.respond_to?(:none)
          return subject.none
        else
          raise ArgumentError, "expected subject to be an ActiveRecord::Base class or Relation. given: #{subject}"
        end
      end
      if rules.none?(&:accessible?)
        if block_given?
          return yield
        else
          raise Error, "none of matched rules are provides scope for #{action}, #{subject}, pass block instead"
        end
      end
      rules.map { |rule| rule.scope_for(@account, subject) }.reduce(:merge)
    end

    def resolve_rules(action, subject)
      rules.resolve_with_mappings(action, subject) do |e|
        Rails.logger.warn { e.message }
        block_given? ? yield : nil
      end
    end

    private

    delegate :rules, to: "self.class"
  end
end