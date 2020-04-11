require_relative "./leftovers/collector"
require_relative "./leftovers/merged_config"
require_relative "./leftovers/reporter"

module Leftovers
  module_function

  class << self
    attr_accessor :parallel
    alias_method :parallel?, :parallel

    attr_accessor :quiet
    alias_method :quiet?, :quiet
  end

  def stdout
    @stdout ||= StringIO.new
  end

  def stderr
    @stderr ||= StringIO.new
  end

  def config
    @config ||= Leftovers::MergedConfig.new
  end

  def collector
    @collector ||= Leftovers::Collector.new
  end

  def reporter
    @reporter ||= Leftovers::Reporter.new
  end

  def leftovers
    @leftovers ||= begin
      collector.collect
      leftovers = collector.definitions.reject do |definition|
        definition.any_skipped? || definition.any_in_collection?
      end
    end
  end

  def run(stdout: StringIO.new, stderr: StringIO.new)
    reset
    @stdout = stdout
    @stderr = stderr
    return 0 if leftovers.empty?

    only_test = []
    none = []
    leftovers.sort.each do |definition|
      if !definition.test? && definition.any_in_test_collection?
        only_test << definition
      else
        none << definition
      end
    end

    unless only_test.empty?
      puts "\e[31mOnly directly called in tests:\e[0m"
      only_test.each { |definition| reporter.call(definition) }
    end

    unless none.empty?
      puts "\e[31mNot directly called at all:\e[0m"
      none.each { |definition| reporter.call(definition) }
    end

    1
  end

  def reset
    remove_instance_variable(:@config) if defined?(@config)
    remove_instance_variable(:@collector) if defined?(@collector)
    remove_instance_variable(:@reporter) if defined?(@reporter)
    remove_instance_variable(:@leftovers) if defined?(@leftovers)
    remove_instance_variable(:@try_require) if defined?(@try_require)
    remove_instance_variable(:@stdout) if defined?(@stdout)
    remove_instance_variable(:@stderr) if defined?(@stderr)
    remove_instance_variable(:@parallel) if defined?(@parallel)
    remove_instance_variable(:@quiet) if defined?(@quiet)
  end

  def warn(message)
    stderr.puts("\e[2K#{message}") unless quiet?
  end

  def puts(message)
    stdout.puts("\e[2K#{message}") unless quiet?
  end

  def print(message)
    stdout.print(message) unless quiet?
  end

  def newline
    stdout.puts('')
  end

  def try_require(*requirables, message: nil)
    @try_require ||= {}
    requirables.each do |requirable|
      return @try_require[requirable] if @try_require.key?(requirable)
      @try_require[requirable] = require requirable
    rescue LoadError
      warn message if message
      @try_require[requirable] = false
    end
  end

  def wrap_array(value)
    case value
    when Hash
      [value]
    when Array
      value
    else
      Array(value)
    end
  end
end