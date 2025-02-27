# frozen_string_literal: true

require 'yaml'

module Leftovers
  module Precompilers
    module YAML
      class Builder < ::Psych::TreeBuilder
        def initialize
          @constants = []

          super
        end

        def add_constant_for_tag(tag, value = nil)
          match = %r{\A!ruby/[^:]*(?::(.*))?\z}.match(tag)
          return unless match

          @constants << (match[1] || value)
        end

        def start_mapping(_anchor, tag, *rest) # leftovers:keep
          add_constant_for_tag(tag)
          tag = nil

          super
        end

        def start_sequence(_anchor, tag, *rest) # leftovers:keep
          add_constant_for_tag(tag)
          tag = nil

          super
        end

        def scalar(value, _anchor, tag, *rest) # leftovers:keep
          add_constant_for_tag(tag, value)
          tag = nil

          super
        end

        def to_ruby_file
          <<~FILE
            __leftovers_document(#{to_ruby_argument(root.to_ruby.first)})
            #{@constants.join("\n")}
          FILE
        end

        private

        def to_ruby_argument(value)
          ruby = value.inspect
          return ruby unless value.is_a?(Array)

          ruby.delete_prefix!('[')
          ruby.delete_suffix!(']')

          ruby
        end
      end

      def self.precompile(yaml)
        builder = ::Leftovers::Precompilers::YAML::Builder.new
        parser = ::Psych::Parser.new(builder)
        parser.parse(yaml)

        builder.to_ruby_file
      rescue ::Psych::SyntaxError => e
        message = [e.problem, e.context].compact.join(' ')
        raise ::Leftovers::PrecompileError.new(message, line: e.line, column: e.column)
      end
    end
  end
end
