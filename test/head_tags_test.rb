# frozen_string_literal: true

require "test_helper"
require_relative "support/capability_snapshot"

class HeadTagsTest < Minitest::Test
  include CapabilitySnapshot

  module Probe
    class Page
      attr_accessor :title, :description

      def initialize(title: "Page", description: nil)
        @title = title
        @description = description
      end
    end
  end

  class Harness
    include RecordingStudioShareable::HeadTags

    attr_accessor :publishable_tags, :publishable_called

    def publishable_head_tags(**)
      @publishable_called = true
      @publishable_tags
    end
  end

  class BareHarness
    include RecordingStudioShareable::HeadTags
  end

  def setup
    snapshot_shareable_state!
    Probe::Page.include(
      RecordingStudio::Capabilities::Shareable.to(public_url: "https://host.example/pages/1")
    )
    @page = Probe::Page.new(description: "A public page")
    @harness = Harness.new
  end

  def teardown
    restore_shareable_state!
  end

  def test_renders_canonical_open_graph_and_twitter_tags
    html = @harness.shareable_head_tags(@page)

    assert_includes html, 'rel="canonical"'
    assert_includes html, 'href="https://host.example/pages/1"'
    assert_includes html, 'property="og:title"'
    assert_includes html, 'content="Page"'
    assert_includes html, 'property="og:description"'
    assert_includes html, 'content="A public page"'
    assert_includes html, 'property="og:url"'
    assert_includes html, 'name="twitter:card"'
    assert_includes html, 'content="summary"'
    refute @harness.publishable_called
  end

  def test_omits_description_and_uses_large_image_card_when_an_image_is_present
    @page.description = nil
    html = @harness.shareable_head_tags(
      @page,
      payload: RecordingStudioShareable::SharePayload.for(@page, image: "https://cdn.example/card.png")
    )

    refute_includes html, "og:description"
    assert_includes html, 'property="og:image"'
    assert_includes html, "https://cdn.example/card.png"
    assert_includes html, 'content="summary_large_image"'
  end

  def test_escapes_title_text
    @page.title = "Tom & <Jerry>"
    html = @harness.shareable_head_tags(@page)

    refute_includes html, "<Jerry>"
    assert_includes html, "Tom &amp; &lt;Jerry&gt;"
  end

  def test_empty_when_there_is_no_share_url
    Probe::Page.include(RecordingStudio::Capabilities::Shareable.to)

    assert_equal "", @harness.shareable_head_tags(Probe::Page.new).to_s
  end

  def test_defers_to_publishable_tags_when_that_capability_is_enabled
    @harness.publishable_tags = "publishable-tags"
    html = with_publishable { @harness.shareable_head_tags(@page) }

    assert_equal "publishable-tags", html
    assert @harness.publishable_called
    refute_includes html.to_s, "og:title"
  end

  def test_returns_empty_when_publishable_is_enabled_and_its_helper_is_absent
    html = with_publishable { BareHarness.new.shareable_head_tags(@page) }

    assert_equal "", html.to_s
  end

  def test_does_not_defer_when_publishable_is_absent
    html = @harness.shareable_head_tags(@page)

    assert_includes html, "og:title"
    refute @harness.publishable_called
  end

  private

  def with_publishable(&block)
    original = RecordingStudio.method(:capability_enabled?)
    RecordingStudio.stub(:capability_enabled?, lambda { |name, **kwargs|
      return true if name.to_sym == :publishable

      original.call(name, **kwargs)
    }) { block.call }
  end
end
