# frozen_string_literal: true

require 'fast_ignore'
require 'set'
require_relative 'parser'
require_relative 'definition'

module Leftovers
  class FileCollector < ::Parser::AST::Processor # rubocop:disable Metrics/ClassLength
    attr_reader :calls
    attr_reader :definitions

    def initialize(ruby, file) # rubocop:disable Metrics/MethodLength
      @calls = []
      @definitions = []
      @allow_lines = Set.new.compare_by_identity
      @test_lines = Set.new.compare_by_identity
      @ruby = ruby
      @file = file
    end

    def filename
      @filename ||= @file.relative_path
    end

    def to_h
      {
        test?: @file.test?,
        calls: calls,
        definitions: definitions
      }
    end

    def collect
      ast, comments = Leftovers::Parser.parse_with_comments(@ruby, @file)
      process_comments(comments)
      process(ast)
    rescue ::Parser::SyntaxError => e
      Leftovers.warn "\e[31m#{filename}:#{e.diagnostic.location.line}:#{e.diagnostic.location.column} SyntaxError: #{e.message}\e[0m" # rubocop:disable Layout/LineLength
    end

    METHOD_NAME_RE = /[[:alpha:]_][[:alnum:]_]*\b[\?!=]?/.freeze
    NON_ALNUM_METHOD_NAME_RE = Regexp.union(%w{
      []= [] ** ~ +@ -@ * / % + - >> << &
      ^ | <=> <= >= < > === == != =~ !~ !
    }.map { |op| /#{Regexp.escape(op)}/ })
    CONSTANT_NAME_RE = /[[:upper:]][[:alnum:]_]*\b/.freeze
    NAME_RE = Regexp.union(METHOD_NAME_RE, NON_ALNUM_METHOD_NAME_RE, CONSTANT_NAME_RE)
    LEFTOVERS_CALL_RE = /\bleftovers:call(?:s|ed|er|ers|) (#{NAME_RE}(?:[, :]+#{NAME_RE})*)/.freeze
    LEFTOVERS_ALLOW_RE = /\bleftovers:(?:keeps?|skip(?:s|ped|)|allow(?:s|ed|))\b/.freeze
    LEFTOVERS_TEST_RE = /\bleftovers:(?:for_tests?|tests?|testing)\b/.freeze
    def process_comments(comments) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      comments.each do |comment|
        @allow_lines << comment.loc.line if comment.text.match?(LEFTOVERS_ALLOW_RE)

        @test_lines << comment.loc.line if comment.text.match?(LEFTOVERS_TEST_RE)

        next unless (match = comment.text.match(LEFTOVERS_CALL_RE))
        next unless match[1]

        match[1].scan(NAME_RE).each { |s| add_call(s.to_sym) }
      end
    end

    # grab method definitions
    def on_def(node)
      add_definition(node.children.first, node.loc.name)

      super
    end

    def on_ivasgn(node)
      add_definition(node.children.first, node.loc.name)

      super
    end
    alias_method :on_gvasgn, :on_ivasgn
    alias_method :on_cvasgn, :on_ivasgn

    def on_ivar(node)
      add_call(node.children.first)

      super
    end
    alias_method :on_gvar, :on_ivar
    alias_method :on_cvar, :on_ivar

    def on_op_asgn(node)
      collect_op_asgn(node)

      super
    end

    def on_and_asgn(node)
      collect_op_asgn(node)

      super
    end

    def on_or_asgn(node)
      collect_op_asgn(node)

      super
    end

    # grab method calls
    def on_send(node)
      super

      add_call(node.children[1])

      collect_rules(node)
    end
    alias_method :on_csend, :on_send

    def on_const(node)
      super

      add_call(node.children[1])
    end

    # grab e.g. :to_s in each(&:to_s)
    def on_block_pass(node)
      super

      add_call(node.children.first.to_sym) if node.children.first&.string_or_symbol?
    end

    # grab class Constant or module Constant
    def on_class(node)
      # don't call super so we don't process the class name
      # !!! (# wtf does this mean dana? what would happen instead?)
      process_all(node.children.drop(1))

      node = node.children.first

      add_definition(node.children[1], node.loc.name)
    end
    alias_method :on_module, :on_class

    # grab Constant = Class.new or CONSTANT = 'string'.freeze
    def on_casgn(node)
      super

      add_definition(node.children[1], node.loc.name)

      collect_rules(node)
    end

    # grab calls to `alias new_method original_method`
    def on_alias(node)
      super

      new_method, original_method = node.children

      add_definition(new_method.children.first, new_method.loc.expression)
      add_call(original_method.children.first)
    end

    private

    def test?(loc)
      @file.test? || @test_lines.include?(loc.line)
    end

    def add_definition(name, loc)
      return if @allow_lines.include?(loc.line)

      definitions << Leftovers::Definition.new(name, location: loc, file: @file, test: test?(loc))
    end

    def add_call(name)
      calls << name
    end

    # just collects the call, super will collect the definition
    def collect_var_op_asgn(node)
      name = node.children.first

      return unless name

      add_call(name)
    end

    def collect_send_op_asgn(node)
      name = node.children[1]

      return unless name

      add_call(:"#{name}=")
    end

    def collect_op_asgn(node)
      node = node.children.first
      case node.type
      when :send then collect_send_op_asgn(node)
      when :ivasgn, :gvasgn, :cvasgn then collect_var_op_asgn(node)
      end
    end

    def collect_rules(node) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      Leftovers.config.rules.each do |rule|
        next unless rule.match?(node.name, node.name_s, filename)

        next if rule.skip?

        calls.concat(rule.calls(node))

        next if @allow_lines.include?(node.loc.line)

        node.file = @file
        node.test = test?(node.loc)
        definitions.concat(rule.definitions(node))
      end
    rescue StandardError => e
      raise e.class, "#{e.message}\nwhen processing #{node} at #{filename}:#{node.loc.line}:#{node.loc.column}", e.backtrace # rubocop:disable Layout/LineLength
    end
  end
end
