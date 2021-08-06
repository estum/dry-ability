# frozen_string_literal: true

require "dry/initializer"
require "dry/ability/t"
require "dry/ability/f"
require "dry/ability/rule"
require "dry/ability/container"

module Dry
  module Ability
    # Creates a container with ability rules and provides DSL to define them.
    class RulesBuilder
      include Initializer[undefined: false].define -> do
        option :_container, T.Instance(Container), default: proc { Container.new }, optional: true
      end

      # Registers mappings
      #
      # @example
      #
      #   map :action,  :read   => %i(index show)
      #   map :subject, :public => %w(Post Like Comment)
      #
      def map(kind, dict)
        kind = T::ActionOrSubject[kind]
        dict = T::RulesMapping[dict]

        @_container.namespace(:mappings) do |_mappings|
          _mappings.namespace(kind) do |_action_or_subject|
            dict.each do |mapped, list|
              list.sort.each do |original|
                key = _action_or_subject.send(:namespaced, original)
                pred = Array.wrap(@_container._container.delete(key)&.call)
                pred << mapped unless pred.include?(mapped)
                _action_or_subject.register(original, pred)
              end
            end
          end
        end
      end

      # Shorthand of <tt>map :action, dict</tt>
      def map_action(dict)
        map :action, dict
      end

      # Shorthand of <tt>map :subject, dict</tt>
      #
      # @exmaple
      #
      #   map_subject :public => %w(Post Like Comment)
      def map_subject(dict)
        map :subject, dict
      end

      # Registers rule in the calculated key
      #
      # @example
      #
      #   can :read, :public
      def can(actions, subjects, filter: nil, scope: nil, inverse: false, explicit_scope: true, **constraints, &block)
        @_container.namespace(:rules) do |_rules|
          Rule.new(actions, subjects,
            constraints: constraints,
            filter:      (filter || block&.to_proc),
            scope:       scope,
            inverse:     inverse,
            explicit_scope: explicit_scope
          ).register_to(_rules)
        end
      end

      # @see #can(*args, **options, &block)
      def cannot(*args, **options, &block)
        can(*args, **options, inverse: true, &block)
      end

      # Generates module, which, after being included into a class, registers singleton
      # instance variable <tt>@_container</tt> as reference to the composed container of rules.
      def mixin
        @mixin ||= Module.new.tap do |mod|
          container = @_container.freeze
          mod.define_singleton_method :included do |base|
            base.instance_variable_set(:@_container, container)
            super(base)
          end
          mod
        end
      end
    end
  end
end
