# frozen_string_literal: true

require "dry/transformer/recursion"
require "dry/transformer/hash"

module Dry
  module Ability
    module F
      extend Transformer::Registry

      import :array_recursion, from: Transformer::Recursion
      import :eval_values, from: Transformer::HashTransformations

      key_or_to_s = T::CoercKey | T['coercible.string']
      register :coerc_key, Transformer::Function.new(key_or_to_s.to_proc)

      # def self.to_mapping_key(key, *namespaces)
      #   *namespaces, key = key if key.is_a?(Array)
      #   coerced = coerc_key(key)
      #   namespaces.blank ? coerced : "#{namespaces * ?.}.#{coerced}"
      # end
      #
      # def self.ns_path(*namespaces)
      #   namespaces.flatten!
      #   namespaces.blank? ? nil : namespaces.join(?.)
      # end

      def self.get_mapping(key, container, nsfn, &block)
        key = Key.new(key, nsfn)
        yield(key) if block_given?
        if container.key?(key.nsed)
          Array.wrap(container[key.nsed]).flat_map do |mapped|
            get_mapping(mapped, container, nsfn, &block)
          end
        else
          key.to_s
        end
      end

      def self.collect_mappings(key, container, nsfn)
        list = Set.new
        get_mapping(key, container, nsfn) do |key|
          key = yield(key) if block_given?
          list << key
        end
        list.to_a
      end

      def self.string_tpl(*args, pattern)
        args = args[0] if args.size == 1 && args[0].is_a?(Array)
        format(pattern, *args)
      end

      # register :recursively_apply_mappings, t(:array_recursion, t)
    end
  end
end
