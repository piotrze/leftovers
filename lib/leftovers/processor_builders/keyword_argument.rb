# frozen-string-literal: true

require_relative '../matcher_builders/node_name'
require_relative '../value_processors/keyword_argument'

module Leftovers
  module ProcessorBuilders
    module KeywordArgument
      def self.build(pattern, then_processor)
        matcher = ::Leftovers::MatcherBuilders::NodeName.build(pattern)
        return unless matcher

        ::Leftovers::ValueProcessors::KeywordArgument.new(matcher, then_processor)
      end
    end
  end
end
