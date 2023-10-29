# frozen_string_literal: true

module Dry
  module Ability
    # A general CanCan exception
    class Error < StandardError; end

    # Raised when using check_authorization without calling authorized!
    class AuthorizationNotPerformed < Error; end

    class RuleNotDefined < Error
      DEFAULT_MESSAGE_TEMPLATE = "Rule for subject: %p, action: %p is not defined (candidates: %p)"
      NONE = [].freeze

      def initialize(message = nil, subject:, action:, candidates: NONE)
        @action, @subject = action, subject
        message ||= format(DEFAULT_MESSAGE_TEMPLATE, subject.class, action, candidates)
        super(message)
      end
    end

    class ScopeNotDefault < Error; end

    class AccessDenied < Error
      DEFAULT_MESSAGE_TEMPLATE = "The requester is not authorized to %s %p."

      attr_reader :action, :subject

      def initialize(message = nil, action, subject)
        @action, @subject = action, subject
        message ||= format(DEFAULT_MESSAGE_TEMPLATE, action, subject.class)
        super(message)
      end
    end
  end
end