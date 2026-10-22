# frozen_string_literal: true

require "test_helper"

class ShareModalComponentTest < ActiveSupport::TestCase
  include ViewComponent::TestHelpers

  setup do
    @user = User.find_or_create_by!(email: "share-modal@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    Current.actor = @user
    PageShareDemo.ensure!
    @published = Page.find_by!(title: PageShareDemo::PUBLISHED_TITLE).share_payload
  end

  test "copy link is primary and the sheet does not print the url" do
    html = render_inline(modal).to_html
    fragment = Nokogiri::HTML.fragment(html)
    copy = fragment.at_css("button[aria-label='Copy link']")

    assert_equal "primary", copy["data-fp-style"]
    assert_equal @published.url, fragment.at_css("[data-flat-pack--clipboard-text-value]")["data-flat-pack--clipboard-text-value"]
    assert_nil fragment.at_css("p.break-all")
    assert_empty fragment.css("p").select { |node| node.text == @published.url }

    %w[LinkedIn X Facebook].each do |service|
      assert_equal "secondary", fragment.at_css("[aria-label='Share on #{service}']")["data-fp-style"]
    end
    assert_equal "secondary", fragment.at_css("[aria-label='Share by email']")["data-fp-style"]
  end

  private

  def modal
    RecordingStudioShareable::ShareModal::Component.new(payload: @published, modal_id: "share-example")
  end
end
