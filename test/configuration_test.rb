# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @configuration = RecordingStudioShareable::Configuration.new
  end

  def test_defaults
    assert_nil @configuration.public_base_url
    assert_nil @configuration.public_url
    assert_equal RecordingStudioShareable::Configuration::DEFAULT_DESTINATIONS, @configuration.destinations
    assert_instance_of RecordingStudio::Hooks, @configuration.hooks
  end

  def test_merge_updates_known_attributes_and_ignores_unknown_keys
    @configuration.merge!(
      "public_base_url" => "https://press.example/",
      "destinations" => %w[copy email],
      "unknown_key" => "ignored"
    )

    assert_equal "https://press.example", @configuration.public_base_url
    assert_equal %i[copy email], @configuration.destinations
    refute_respond_to @configuration, :unknown_key
  end

  def test_merge_with_non_enumerable_is_noop
    @configuration.public_base_url = "https://press.example"
    @configuration.merge!(nil)

    assert_equal "https://press.example", @configuration.public_base_url
  end

  def test_unknown_destination_is_rejected
    error = assert_raises(ArgumentError) do
      @configuration.destinations = %i[copy qr]
    end

    assert_includes error.message, "qr"
  end

  def test_to_h_reports_registered_hook_counts
    @configuration.hooks.before_initialize { nil }
    @configuration.hooks.after_service { nil }

    result = @configuration.to_h

    assert_nil result.fetch(:public_base_url)
    assert_equal @configuration.destinations, result.fetch(:destinations)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:before_initialize)
    assert_equal 1, result.fetch(:hooks_registered).fetch(:after_service)
  end

  def test_configure_without_block_is_safe
    RecordingStudioShareable.configure

    assert_kind_of RecordingStudioShareable::Configuration, RecordingStudioShareable.configuration
  end
end
