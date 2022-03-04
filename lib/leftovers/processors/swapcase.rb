# frozen_string_literal: true

module Leftovers
  module Processors
    class Swapcase
      include ComparableInstance

      def initialize(then_processor)
        @then_processor = then_processor

        freeze
      end

      def process(str, node, method_node, acc)
        return unless str

        @then_processor.process(str.swapcase, node, method_node, acc)
      end

      freeze
    end
  end
end
