# frozen_string_literal: true

module Dry
  module Ability
    class Key < String
      COERC = F[:coerc_key].to_proc.freeze
      private_constant :COERC

      attr_reader :nsed
      alias_method :namespaced, :nsed

      def initialize(key, nsfn)
        string = COERC[key]
        @nsed = nsfn[string].freeze
        super(string)
      end
    end
  end
end
