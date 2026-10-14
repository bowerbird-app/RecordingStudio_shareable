# frozen_string_literal: true

require "test_helper"

class EngineTest < Minitest::Test
  def setup
    @original_configuration = RecordingStudioShareable.instance_variable_get(:@configuration)
    RecordingStudioShareable.instance_variable_set(:@configuration, RecordingStudioShareable::Configuration.new)
  end

  def teardown
    RecordingStudioShareable.configuration.hooks.clear!
    RecordingStudioShareable.instance_variable_set(:@configuration, @original_configuration)
  end

  def test_before_and_after_initialize_initializers_run_hooks
    before_called = false
    after_called = false

    RecordingStudioShareable.configuration.hooks.before_initialize { |_engine| before_called = true }
    RecordingStudioShareable.configuration.hooks.after_initialize { |_engine| after_called = true }

    find_initializer("recording_studio_shareable.before_initialize").block.call(Object.new)
    find_initializer("recording_studio_shareable.after_initialize").block.call(Object.new)

    assert before_called
    assert after_called
  end

  def test_load_config_merges_config_sources_and_runs_on_configuration_hook
    hook_called = false
    hook_payload = nil
    RecordingStudioShareable.configuration.hooks.on_configuration do |cfg|
      hook_called = true
      hook_payload = cfg
    end

    xcfg = Struct.new(:recording_studio_shareable).new({ destinations: %w[copy email] })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { public_base_url: "https://from-yaml.example/" }
      end
    end.new(app_config)

    find_initializer("recording_studio_shareable.load_config").block.call(app)

    assert hook_called
    assert_equal RecordingStudioShareable.configuration, hook_payload
    assert_equal "https://from-yaml.example", RecordingStudioShareable.configuration.public_base_url
    assert_equal %i[copy email], RecordingStudioShareable.configuration.destinations
  end

  def test_load_config_handles_errors_and_each_pair_fallback
    pair_config = Class.new do
      def each_pair
        yield(:public_base_url, "https://pair.example/")
      end
    end.new

    xcfg = Struct.new(:recording_studio_shareable).new(pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        raise "missing file"
      end
    end.new(app_config)

    find_initializer("recording_studio_shareable.load_config").block.call(app)

    assert_equal "https://pair.example", RecordingStudioShareable.configuration.public_base_url
  end

  def test_load_config_swallow_each_pair_errors
    bad_pair_config = Class.new do
      def each_pair
        raise "bad pair"
      end
    end.new

    xcfg = Struct.new(:recording_studio_shareable).new(bad_pair_config)
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      def config_for(_name)
        { public_base_url: "https://yaml.example" }
      end
    end.new(app_config)

    find_initializer("recording_studio_shareable.load_config").block.call(app)

    assert_equal "https://yaml.example", RecordingStudioShareable.configuration.public_base_url
  end

  def test_load_config_is_noop_without_config_sources
    app = Struct.new(:config).new(Object.new)

    find_initializer("recording_studio_shareable.load_config").block.call(app)

    assert_nil RecordingStudioShareable.configuration.public_base_url
    assert_equal RecordingStudioShareable::Configuration::DEFAULT_DESTINATIONS,
                 RecordingStudioShareable.configuration.destinations
  end

  def test_load_config_ignores_non_enumerable_yaml_and_merge_errors
    yaml = Class.new do
      def each
        raise "bad yaml"
      end
    end.new

    xcfg = Struct.new(:recording_studio_shareable).new({ public_base_url: "https://rails.example" })
    app_config = Struct.new(:x).new(xcfg)
    app = Struct.new(:config) do
      attr_accessor :yaml

      def config_for(_name)
        @yaml
      end
    end.new(app_config)
    app.yaml = yaml

    find_initializer("recording_studio_shareable.load_config").block.call(app)

    assert_equal "https://rails.example", RecordingStudioShareable.configuration.public_base_url
  end

  def test_engine_does_not_mix_behavior_into_every_model
    names = RecordingStudioShareable::Engine.initializers.map(&:name)
    source = File.read(File.expand_path("../lib/recording_studio_shareable/engine.rb", __dir__))

    refute_includes names, "recording_studio_shareable.apply_model_extensions"
    refute_includes names, "recording_studio_shareable.apply_controller_extensions"
    refute_includes source, "to_prepare"
    refute_includes source, "descendants"
    assert_includes names, "recording_studio_shareable.helpers"
  end

  def test_shareable_ships_no_migrations
    migration_files = Dir.glob(File.expand_path("../db/migrate/*.rb", __dir__))
    generator = File.expand_path("../lib/generators/recording_studio_shareable/migrations", __dir__)

    assert_empty migration_files
    refute File.exist?(generator)
  end

  private

  def find_initializer(name)
    RecordingStudioShareable::Engine.initializers.find { |initializer| initializer.name == name }
  end
end
