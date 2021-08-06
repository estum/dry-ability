# frozen_string_literal: true

require "dry/container"
require "dry/ability/f"

module Dry
  module Ability
    class Container < Dry::Container
      MAPPING_NSFN = {
        :subject => F[:string_tpl, "mappings.subject.%s"].to_proc,
        :action  => F[:string_tpl, "mappings.action.%s"].to_proc
      }
      RULES_NSFN = F[:string_tpl, "rules.%s.%s"].to_proc

      # @yieldparam exception
      #   Yields block with an instance of +RuleNotDefault+ exception class
      def resolve_with_mappings(action, subject)
        candidates = key_candidates(action, subject)
        result = []
        candidates.each do |key|
          next unless key?(key)
          result << resolve(key)
        end
        if result.blank?
          exception = RuleNotDefined.new(action: action, subject: subject, candidates: candidates)
          raise exception unless block_given?
          yield(exception)
        else
          result
        end
      end

      def key_candidates(action, subject)
        subject, action = mappings(:subject, subject), mappings(:action, action)
        subject.product(action).map!(&RULES_NSFN)
      end

      def mappings(kind, key)
        F.collect_mappings(key, self, MAPPING_NSFN[kind], &:to_s)
      end
    end
  end
end