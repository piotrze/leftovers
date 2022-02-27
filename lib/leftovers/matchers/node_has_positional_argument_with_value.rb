# frozen_string_literal: true

module Leftovers
  module Matchers
    class NodeHasPositionalArgumentWithValue
      def initialize(position, matcher)
        @position = position
        @matcher = matcher

        freeze
      end

      def ===(node)
        args = node.positional_arguments
        return false unless args

        value_node = args[@position]
        @matcher === value_node if value_node
      end

      freeze
    end
  end
end
