# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Leftovers::YAML do
  subject(:collector) do
    collector = Leftovers::FileCollector.new(ruby, file)
    collector.collect
    collector
  end

  before do
    Leftovers.reset
    with_temp_dir
  end

  after { Leftovers.reset }

  let(:path) { 'foo.yaml' }
  let(:file) do
    temp_file(path, yaml)

    Leftovers::File.new(Leftovers.pwd + path).tap do |f|
      allow(f).to receive(:yaml?).and_return(true)
    end
  end
  let(:yaml) { '' }
  let(:ruby) { file.ruby }

  context 'with yaml files with constant' do
    let(:yaml) do
      stub_const('This::That', Module.new)
      [This::That].to_yaml
    end

    it { is_expected.to have_no_definitions.and(have_calls_including(:This, :That)) }
  end

  context 'with yaml files with instance' do
    let(:yaml) do
      stub_const('This::That', Class.new)
      [This::That.new].to_yaml
    end

    it { is_expected.to have_no_definitions.and(have_calls_including(:This, :That)) }
  end

  context 'with yaml files with e.g. exception subclass' do
    let(:yaml) do
      stub_const('This::That', Class.new(RuntimeError))
      [This::That].to_yaml
    end

    it { is_expected.to have_no_definitions.and(have_calls_including(:This, :That)) }
  end

  context 'with invalid yaml files' do
    let(:yaml) do
      <<~YAML
        my_class: '
      YAML
    end

    it 'outputs an error and collects nothing' do
      expect { subject }.to output(a_string_including(<<~STDERR)).to_stderr
        Psych::SyntaxError: (foo.yaml): found unexpected end of stream while scanning a quoted scalar at line 1 column 11
      STDERR
      expect(subject).to have_no_definitions.and(have_no_calls)
    end
  end
end