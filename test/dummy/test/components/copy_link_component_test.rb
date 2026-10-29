# frozen_string_literal: true

require "test_helper"

class CopyLinkComponentTest < ActiveSupport::TestCase
  include ViewComponent::TestHelpers

  setup do
    @user = User.find_or_create_by!(email: "copy-link@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    Current.actor = @user
    PageShareDemo.ensure!
    @url = Page.find_by!(title: PageShareDemo::PUBLISHED_TITLE).share_payload.url
  end

  test "copy link is a full-width primary button labelled Copy link" do
    html = render_inline(RecordingStudioShareable::CopyLink::Component.new(url: @url)).to_html
    fragment = Nokogiri::HTML.fragment(html)
    copy = fragment.at_css("button[aria-label='Copy link']")

    assert copy
    assert_equal "primary", copy["data-fp-style"]
    assert_includes copy["class"].to_s, "fp-copy-button"
    assert_equal @url, fragment.at_css("[data-flat-pack--clipboard-text-value]")["data-flat-pack--clipboard-text-value"]
    assert_includes fragment.at_css("div")["class"], "w-full"
  end
end
