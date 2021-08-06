# frozen_string_literal: true

require "dry/initializer"
require "dry/ability/t"

module Dry
  module Ability
    class ResourceMediator
      include Initializer[undefined: false].define -> do
        defaults = {
          nil:  proc { nil },
          false: proc { false },
          with:  -> (input, type) {  (type.default? ? type.value : [type.member.value]) | type[input]  }
        }.freeze
        t = { **(t = {
          bool:         T['params.bool'],
          string:       T['params.string'],
          symbol:       T['params.symbol'],
          array:        T['array'] << Array.method(:wrap),
          set:          T.Constructor(Set)
        }), **{
          symbols:      t[:array].of(T['params.symbol']),
          symbols_with: -> (*list) { t[:symbols].default(list.freeze) << defaults[:with] }
        }}.freeze

        param :name,     t[:symbol]
        param :path,     t[:string]
        param :sequence, t[:set] << t[:symbols]

        with_options optional: true do |free|
          free.option :parent, T['bool']

          free.option :class, T['false'] | t[:string], default: proc { @name.to_s.classify }, as: :class_name

          free.option :shallow,   t[:bool], default:  defaults[:false]

          free.option :singleton, t[:bool], default:  defaults[:false]

          free.option :find_by,             t[:symbol]

          free.option :params_method,       t[:symbol]

          free.option :through,             t[:symbol]
        end



        option :parent_action,       t[:symbol], default: proc { :show }

        option :instance_name,       t[:symbol], default: proc { @name }

        option :collection_name,     t[:symbol], default:  proc { @name.to_s.pluralize }

        option :through_association, t[:symbol], default: proc { collection_name }

        option :id_param, t[:symbol], default: proc { parent? ? :"#@name\_id" : :id }, as: :id_param_key

        collection_type = t[:symbols_with][:index]
        option :collection, collection_type, default: proc { collection_type[] }, as: :collection_actions

        new_type = t[:symbols_with][:new, :create]
        option :new, new_type, default: proc { new_type[] }, as: :new_actions

        save_type = t[:symbols_with][:create, :update]
        option :save, save_type, default: proc { save_type[] }, as: :save_actions
      end

      alias_method :parent?,   :parent
      alias_method :shallow?,  :shallow
      alias_method :singleton?, :singleton

      def before(controller)
        resource_class(controller).new(self, controller).call
      end

      def resource_class(controller)
        if defined?(::InheritedResources) && controller.is_a?(::InheritedResources::Actions)
          InheritedResource
        else
          ControllerResource
        end
      end

      def member_action?(action_name, params)
        @new_actions.include?(action_name) || singleton? ||
          ((params[:id] || params[@id_param_key]) && !@collection_actions.include?(action_name))
      end

      def collection_action?(action_name, *)
        @collection_actions.include?(action_name)
      end
    end
  end
end