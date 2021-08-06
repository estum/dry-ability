# frozen_string_literal: true

require "dry/initializer"
require "dry/ability/t"
require "dry/ability/rule_interface"

module Dry
  module Ability
    class Rule
      include Initializer[undefined: false].define -> do
        param :actions,  T::Actions,  reader: :private
        param :subjects, T::Subjects, reader: :private
        option :inverse, T['bool'],   reader: :private
        option :constraints, T::Hash.map(T['params.symbol'], T['any']), default: -> { {} }
        option :filter,  T::Callable, optional: true
        option :scope,   T::Callable, optional: true
        option :explicit_scope, T['bool'], default: -> { true }
      end

      include RuleInterface

      def call(account, object)
        if filter?
          filter.(account, object)
        else
          @constraints.blank? || run_constraints(account, object, @constraints)
        end ^ @inverse
      end

      def attributes_for(account, object)
        @constraints.blank? ? {} : F[:eval_values, [account, object]][@constraints]
      end

      def scope_for(account, subject)
        relation = if scope?
          @scope.arity > 1 ? @scope[account, subject] : @scope[account]
        else
          T::Queriable[subject].all
        end
        unless @explicit_scope
          attrs = attributes_for(account, subject)
          relation = relation.where(attrs) unless attrs.blank?
        end
        relation
      end

      def filter?
        !@filter.nil?
      end

      def scope?
        !@scope.nil?
      end

      def accessible?
        scope? || !@explicit_scope
      end

      def register_to(_rules)
        unless defined?(@_registered)
          @subjects.each do |subject|
            _rules.namespace(subject) do |_subject|
              @actions.each do |action|
                key = _subject.send(:namespaced, action)
                pred = _rules._container.delete(key)&.call
                rules_or = pred | self if pred
                _subject.register action, (rules_or || self)
              end
            end
          end
          @_registered = true
        end
      end

      def |(other)
        Or.new([self, other])
      end

      class Or
        include Dry::Initializer[undefined: false].define -> do
          param :items, T.Array(T.Instance(Rule))
        end

        include RuleInterface

        def call(account, object)
          items.reduce(false) do |result, rule|
            result || rule[account, object]
          end
        end

        def attributes_for(account, object)
          items.reduce({}) do |result, rule|
            result.deep_merge!(rule.attributes_for(rule, object)); result
          end
        end

        def scope_for(account, subject)
          base_relations = items.map { |rule| rule.scope_for(account, subject) }
          condit = base_relations.map { |r| r.except(:joins) }.reduce(:or)
          merged = base_relations.map { |r| r.except(:where) }.reduce(:merge)
          merged.merge(condit)
        end

        def accessible?
          true
        end

        def |(other)
          self.class.new([*items, other])
        end
      end

      private

      def run_constraints(account, object, dict)
        case object when Class, Symbol
          true
        else
          dict.reduce(true) do |pred, (key, value)|
            pred && call_constraint(account, object, key, value)
          end
        end
      end

      def call_constraint(account, object, key, constraint)
        value = object.public_send(key)
        case constraint
        when Array
          constraint.include?(value)
        when Hash
          run_constraints(account, value, constraint)
        when Proc
          constraint.arity > 1 ? constraint.(account, value) : value == constraint.(account)
        else
          value == constraint
        end
      end
    end
  end
end
