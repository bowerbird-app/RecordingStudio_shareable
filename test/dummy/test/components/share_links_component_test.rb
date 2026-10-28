# frozen_string_literal: true

require "test_helper"

class ShareLinksComponentTest < ActiveSupport::TestCase
  include ViewComponent::TestHelpers

  setup do
    @user = User.find_or_create_by!(email: "share-links@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    Current.actor = @user
    PageShareDemo.ensure!
    @payload = Page.find_by!(title: PageShareDemo::PUBLISHED_TITLE).share_payload
  end

  test "share links are secondary destinations without copy as a url" do
    html = render_inline(RecordingStudioShareable::ShareLinks::Component.new(payload: @payload)).to_html
    fragment = Nokogiri::HTML.fragment(html)
    list = fragment.at_css("[aria-label='Share destinations']")

    assert list
    %w[LinkedIn X Facebook].each do |service|
      button = fragment.at_css("[aria-label='Share on #{service}']")
      assert button
      assert_equal "secondary", button["data-fp-style"]
      assert_equal "_blank", button["target"]
    end
    email = fragment.at_css("[aria-label='Share by email']")
    assert email
    assert_equal "secondary", email["data-fp-style"]
    assert_nil email["target"]
    assert_match(/\Amailto:/, email["href"])
    refute_includes html, "Copy link"
  end
end
