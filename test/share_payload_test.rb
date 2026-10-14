# frozen_string_literal: true

require "test_helper"
require_relative "support/capability_snapshot"

class SharePayloadTest < Minitest::Test
  include CapabilitySnapshot

  module Probe
    class Unshared
      def self.probe
        "unshared"
      end
    end

    class Page
      attr_accessor :title, :name, :description, :published_url, :current_publishable

      def initialize(title: nil, name: nil, description: nil)
        @title = title
        @name = name
        @description = description
      end
    end
  end

  def setup
    snapshot_shareable_state!
    @page = Probe::Page.new(title: "Public page", description: "About the page")
    Probe::Page.include(RecordingStudio::Capabilities::Shareable.to(public_url: "https://host.example/pages/1"))
    RecordingStudioShareable.configuration.public_base_url = "https://share.example"
  end

  def teardown
    restore_shareable_state!
  end

  def test_uses_host_public_url_when_publishable_is_absent
    payload = RecordingStudioShareable::SharePayload.for(@page)

    assert_predicate payload, :available?
    refute_predicate payload, :publishable_enabled?
    assert_equal "https://host.example/pages/1", payload.url
  end

  def test_absolutizes_only_relative_host_urls
    enable_shareable(public_url: "/kits/press")

    assert_equal "https://share.example/kits/press", payload_for(@page).url
  end

  def test_does_not_double_prefix_an_absolute_url
    enable_shareable(public_url: "https://public.example/kits/1")

    assert_equal "https://public.example/kits/1", payload_for(@page).url
  end

  def test_relative_url_without_base_is_unavailable
    RecordingStudioShareable.configuration.public_base_url = nil
    enable_shareable(public_url: "/kits/press")

    refute_predicate payload_for(@page), :available?
  end

  def test_missing_public_url_is_unavailable
    enable_shareable
    payload = payload_for(@page)

    refute_predicate payload, :available?
    assert_empty payload.destination_urls
    assert_equal RecordingStudioShareable::SharePayload::MISSING_URL_REASON, payload.unavailable_reason
  end

  def test_publishable_published_url_wins_and_host_url_is_not_called
    called = false
    enable_shareable(public_url: lambda { |_record|
      called = true
      "https://host.example/direct"
    })
    @page.published_url = "/published/uuid/my-slug"

    with_publishable do
      payload = payload_for(@page)

      assert_equal "https://share.example/published/uuid/my-slug", payload.url
      refute called
    end
  end

  def test_publishable_absolute_url_is_not_double_prefixed
    enable_shareable(public_url: "https://host.example/direct")
    @page.published_url = "https://public.example/kits/1"

    with_publishable do
      assert_equal "https://public.example/kits/1", payload_for(@page).url
    end
  end

  def test_draft_scheduled_and_unpublished_do_not_fall_back
    called = false
    enable_shareable(public_url: lambda { |_record|
      called = true
      "https://host.example/secret"
    })
    @page.published_url = nil

    with_publishable do
      payload = payload_for(@page)

      refute_predicate payload, :available?
      assert_nil payload.url
      assert_empty payload.destination_urls
    end
    refute called
  end

  def test_rejects_preview_storage_and_admin_urls
    enable_shareable
    [
      "https://public.example/recordings/1/publishable/preview",
      "/recordings/1/publishable/preview",
      "https://cdn.example/rails/active_storage/disk/blob",
      "https://public.example/recording_studio/pages/1",
      "https://public.example/ok?next=/recording_studio",
      "javascript:alert(1)",
      "https://public.example/files?id=active_storage%2Fblobs%2F1"
    ].each do |unsafe|
      @page.published_url = unsafe
      with_publishable do
        payload = payload_for(@page)

        refute payload.available?, "expected #{unsafe} to be rejected"
        assert_nil payload.url
        assert_empty payload.destination_urls
      end
    end
  end

  def test_call_site_public_url_does_not_override_publishable
    enable_shareable
    @page.published_url = nil

    with_publishable do
      payload = RecordingStudioShareable::SharePayload.for(@page, public_url: "https://host.example/direct")

      refute_predicate payload, :available?
    end
  end

  def test_shareable_stays_off_until_the_type_opts_in
    payload = RecordingStudioShareable::SharePayload.for(Probe::Unshared.new)

    refute_predicate payload, :available?
    assert_nil payload.unavailable_reason
  end

  def test_available_payload_has_no_unavailable_reason
    payload = payload_for(@page)

    assert_predicate payload, :available?
    assert_nil payload.unavailable_reason
  end

  def test_draft_and_unpublished_ask_publishable_for_the_reason
    enable_shareable(public_url: "https://host.example/secret")
    @page.published_url = nil

    with_publishable do
      stub_publishable_state(draft: true)
      assert_equal RecordingStudioShareable::SharePayload::PUBLISH_REASON, payload_for(@page).unavailable_reason

      stub_publishable_state(draft: false, unpublished: true)
      assert_equal RecordingStudioShareable::SharePayload::PUBLISH_REASON, fresh_payload.unavailable_reason
    end
  end

  def test_scheduled_reason_uses_publishable_predicate_and_publish_at
    enable_shareable(public_url: "https://host.example/secret")
    @page.published_url = nil
    @page.current_publishable = Struct.new(:publish_at, :effective_time_zone).new(
      Time.utc(2026, 11, 3, 15, 0, 0),
      "UTC"
    )
    stub_publishable_state(scheduled: true)

    with_publishable do
      payload = payload_for(@page)

      refute_predicate payload, :available?
      assert_nil payload.url
      Time.use_zone("UTC") do
        assert_equal "Scheduled for Tuesday 3 November at 3:00 PM. You can share it then.",
                     payload_for(@page).unavailable_reason
      end
      Time.use_zone("America/New_York") do
        assert_equal "Scheduled for Tuesday 3 November at 10:00 AM. You can share it then.",
                     fresh_payload.unavailable_reason
      end
    end
  end

  def test_future_publish_at_is_not_scheduled_unless_publishable_says_so
    enable_shareable
    @page.published_url = nil
    @page.current_publishable = Struct.new(:publish_at, :effective_time_zone).new(Time.utc(2026, 12, 1), "UTC")
    stub_publishable_state(scheduled: false, draft: true)

    with_publishable do
      assert_equal RecordingStudioShareable::SharePayload::PUBLISH_REASON, payload_for(@page).unavailable_reason
    end
  end

  def test_publishable_without_a_state_reports_a_missing_url
    enable_shareable(public_url: "https://host.example/secret")
    @page.published_url = nil

    with_publishable do
      payload = payload_for(@page)

      refute_predicate payload, :available?
      assert_equal RecordingStudioShareable::SharePayload::MISSING_URL_REASON, payload.unavailable_reason
    end
  end

  def test_title_and_description_fallbacks
    @page.current_publishable = Struct.new(:social_title, :social_description, :seo_title, :seo_description).new(
      "Social title",
      "Social description",
      "SEO title",
      "SEO description"
    )

    payload = payload_for(@page)

    assert_equal "Social title", payload.title
    assert_equal "Social description", payload.description

    @page.current_publishable.social_title = nil
    @page.current_publishable.social_description = " "
    assert_equal "SEO title", payload_for(@page).title
    assert_equal "SEO description", payload_for(@page).description

    @page.current_publishable = nil
    assert_equal "Public page", payload_for(@page).title
    assert_equal "About the page", payload_for(@page).description

    @page.title = nil
    @page.description = nil
    @page.name = "Named page"
    assert_equal "Named page", payload_for(@page).title
    assert_nil payload_for(@page).description

    @page.name = nil
    assert_predicate payload_for(@page).title, :present?
  end

  def test_explicit_title_description_and_image_overrides
    payload = RecordingStudioShareable::SharePayload.for(
      @page,
      title: "Override",
      description: ->(record) { "Copy of #{record.title}" },
      image: "https://cdn.example/card.png"
    )

    assert_equal "Override", payload.title
    assert_equal "Copy of Public page", payload.description
    assert_equal "https://cdn.example/card.png", payload.image_url
  end

  def test_image_accepts_only_absolute_https_and_ignores_publishable_images
    @page.current_publishable = Struct.new(:social_image_url).new("https://cdn.example/from-publishable.png")

    assert_nil payload_for(@page).image_url
    assert_nil RecordingStudioShareable::SharePayload.for(@page, image: "http://cdn.example/a.png").image_url
    assert_nil RecordingStudioShareable::SharePayload.for(@page, image: "/card.png").image_url
    assert_nil RecordingStudioShareable::SharePayload.for(
      @page,
      image: "https://cdn.example/active_storage/blobs/1"
    ).image_url
    assert_equal "https://cdn.example/card.png",
                 RecordingStudioShareable::SharePayload.for(@page, image: "https://cdn.example/card.png").image_url
  end

  def test_destination_list_defaults_and_can_be_narrowed
    assert_equal RecordingStudioShareable::Configuration::DEFAULT_DESTINATIONS, payload_for(@page).destinations

    narrowed = RecordingStudioShareable::SharePayload.for(@page, destinations: %i[copy linkedin])

    assert_equal %i[copy linkedin], narrowed.destinations
    assert_equal [:linkedin], narrowed.destination_urls.keys
  end

  def test_configuration_overrides_apply_when_the_type_does_not_set_them
    enable_shareable
    RecordingStudioShareable.configuration.public_url = "https://configured.example/page"
    RecordingStudioShareable.configuration.title = "Configured title"

    payload = payload_for(@page)

    assert_equal "https://configured.example/page", payload.url
    assert_equal "Configured title", payload.title
  end

  private

  def payload_for(record)
    RecordingStudioShareable::SharePayload.for(record)
  end

  def enable_shareable(**)
    Probe::Page.include(RecordingStudio::Capabilities::Shareable.to(**))
  end

  def stub_publishable_state(scheduled: false, draft: false, unpublished: false)
    @publishable_state ||= { scheduled: false, draft: false, unpublished: false }
    @publishable_state.merge!(scheduled: scheduled, draft: draft, unpublished: unpublished)
    return if @publishable_predicates

    state = @publishable_state
    @page.define_singleton_method(:scheduled?) { state[:scheduled] }
    @page.define_singleton_method(:draft?) { state[:draft] }
    @page.define_singleton_method(:unpublished?) { state[:unpublished] }
    @publishable_predicates = true
  end

  def fresh_payload
    RecordingStudioShareable::SharePayload.for(@page)
  end

  def with_publishable(&block)
    original = RecordingStudio.method(:capability_enabled?)
    RecordingStudio.stub(:capability_enabled?, lambda { |name, **kwargs|
      return true if name.to_sym == :publishable

      original.call(name, **kwargs)
    }) { block.call }
  end
end
