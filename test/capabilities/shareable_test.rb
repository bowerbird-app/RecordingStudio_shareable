# frozen_string_literal: true

require "test_helper"
require_relative "../support/capability_snapshot"

class ShareableCapabilityTest < Minitest::Test
  include CapabilitySnapshot

  module Probe
    class HostType
      attr_accessor :title
    end

    class OtherType
      def self.probe
        "other"
      end
    end
  end

  def setup
    snapshot_shareable_state!
  end

  def teardown
    restore_shareable_state!
  end

  def test_to_is_the_include_for_wrapper
    source = File.read(capability_path)

    assert_includes source, "def self.to(**)"
    assert_includes source, "RecordingStudio::Capabilities.include_for(:shareable, **)"
    refute_includes source, "enable_capability"
    refute_includes source, "set_capability_options"
    assert_equal [:to], RecordingStudio::Capabilities::Shareable.singleton_methods(false)
  end

  def test_to_delegates_to_include_for
    captured_name = nil
    captured_options = nil
    factory = Module.new

    RecordingStudio::Capabilities.stub :include_for, lambda { |name, **options, &block|
      captured_name = name
      captured_options = options
      block&.call(Probe::HostType)
      factory
    } do
      result = RecordingStudio::Capabilities::Shareable.to(public_url: "/pages/1")

      assert_same factory, result
    end

    assert_equal :shareable, captured_name
    assert_equal({ public_url: "/pages/1" }, captured_options)
  end

  def test_loading_the_gem_does_not_enable_shareable
    assert RecordingStudio.registered_capabilities.key?(:shareable)
    assert_equal "RecordingStudio::Capabilities::Shareable",
                 RecordingStudio.registered_capabilities[:shareable][:source]
    assert_empty RecordingStudio.configuration.enabled_recordable_types_for(:shareable)
    refute RecordingStudio.capability_enabled?(:shareable, for: Probe::HostType)
  end

  def test_including_to_enables_only_that_type
    Probe::HostType.include(RecordingStudio::Capabilities::Shareable.to(public_url: "https://example.com/p"))

    assert RecordingStudio.capability_enabled?(:shareable, for: Probe::HostType)
    assert_equal({ public_url: "https://example.com/p" },
                 RecordingStudio.capability_options(:shareable, for: Probe::HostType))
    refute RecordingStudio.capability_enabled?(:shareable, for: Probe::OtherType)
    assert_equal [Probe::HostType.name],
                 RecordingStudio.configuration.enabled_recordable_types_for(:shareable)
  end

  def test_opted_in_recordable_exposes_share_payload
    Probe::HostType.include(
      RecordingStudio::Capabilities::Shareable.to(public_url: "https://example.com/host")
    )
    record = Probe::HostType.new
    record.title = "Host"

    assert_predicate record, :shareable?
    assert_equal "https://example.com/host", record.share_payload.url
  end

  private

  def capability_path
    File.expand_path("../../lib/recording_studio/capabilities/shareable.rb", __dir__)
  end
end
