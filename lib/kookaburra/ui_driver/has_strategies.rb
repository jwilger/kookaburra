module Kookaburra
  class UIDriver
    module HasStrategies
      class Strategy
        __cattr_accessor_for_kookaburra(:tag)
        attr_reader :ui_component
        def initialize(ui_component)
          @ui_component = ui_component
        end
      end

      module ClassMethods
        def strategy(tag, &proc)
          Class.new(::Kookaburra::UIDriver::HasStrategies::Strategy).tap { |klass|
            klass.tag = tag
            klass.module_eval &proc
            self.strategy_classes << klass
          }
        end

        def use_strategy_for(*method_names)
          def_delegators :current_strategy, *method_names
        end
      end

      module InstanceMethods
        def strategies
          @strategies ||= strategy_classes.map { |klass| klass.new(self) }
        end

        def current_strategy
          strategies.detect(&:applies?) or raise 'No applicable strategy!'
        end

        def strategy_tag
          current_strategy.tag
        end
      end

      def self.included(receiver)
        receiver.__cattr_accessor_for_kookaburra :strategy_classes, []

        receiver.extend Forwardable
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
