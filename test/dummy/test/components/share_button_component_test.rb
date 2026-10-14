# frozen_string_literal: true

require "test_helper"

class ShareButtonComponentTest < ActiveSupport::TestCase
  include ViewComponent::TestHelpers

  setup do
    @user = User.find_or_create_by!(email: "share-button@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    Current.actor = @user
    PageShareDemo.ensure!
    @draft = Page.find_by!(title: PageShareDemo::DRAFT_TITLE).share_payload
    @published = Page.find_by!(title: PageShareDemo::PUBLISHED_TITLE).share_payload
  end

  test "hide is the default and renders nothing when sharing is unavailable" do
    html = render_inline(button(@draft)).to_html

    assert_equal "", html.strip
  end

  test "disable renders a disabled control with the reason and no url" do
    html = render_inline(button(@draft, when_unavailable: :disable)).to_html

    assert_includes html, "Publish this page to share it"
    assert_includes html, 'aria-disabled="true"'
    assert_includes html, "aria-describedby"
    assert_includes html, 'role="tooltip"'
    refute_includes html, "data-modal-id"
    refute_includes html, "href="
    refute_share_url html
  end

  test "an available payload still opens the modal in either mode" do
    hidden = render_inline(button(@published)).to_html
    disabled_mode = render_inline(button(@published, when_unavailable: :disable)).to_html

    [hidden, disabled_mode].each do |html|
      assert_includes html, 'data-modal-id="share-example"'
      refute_includes html, "aria-disabled"
    end
  end

  test "unknown unavailable mode is rejected" do
    error = assert_raises(ArgumentError) do
      button(@draft, when_unavailable: :collapse)
    end

    assert_includes error.message, "when_unavailable"
  end

  private

  def refute_share_url(html)
    refute_match %r{https?://(?!www\.w3\.org/2000/svg)}, html
  end

  def button(payload, **options)
    RecordingStudioShareable::ShareButton::Component.new(
      payload: payload,
      modal_id: "share-example",
      **options
    )
  end
end