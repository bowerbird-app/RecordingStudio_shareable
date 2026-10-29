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
    stack = copy.ancestors.find { |node| node["class"].to_s.include?("mt-6") }
    assert_includes stack["class"], "mt-6"
    assert_equal @published.url, fragment.at_css("[data-flat-pack--clipboard-text-value]")["data-flat-pack--clipboard-text-value"]
    assert_nil fragment.at_css("p.break-all")
    assert_empty fragment.css("p").select { |node| node.text == @published.url }

    %w[LinkedIn X Facebook].each do |service|
      assert_equal "secondary", fragment.at_css("[aria-label='Share on #{service}']")["data-fp-style"]
    end
    assert_equal "secondary", fragment.at_css("[aria-label='Share by email']")["data-fp-style"]
  end

  test "native share stays hidden until the stimulus controller reveals it" do
    html = render_inline(modal).to_html
    fragment = Nokogiri::HTML.fragment(html)
    sheet = fragment.at_css("[data-controller='recording-studio-shareable--share']")
    native = fragment.at_css("[data-recording-studio-shareable--share-target='native']")
    share = fragment.at_css("[data-action='click->recording-studio-shareable--share#native']")

    assert sheet
    assert_equal @published.url, sheet["data-recording-studio-shareable--share-url-value"]
    assert_equal @published.title.to_s, sheet["data-recording-studio-shareable--share-title-value"]
    assert native
    assert native.key?("hidden")
    assert share
    assert_equal "Share", share["aria-label"]
  end

  private

  def modal
    RecordingStudioShareable::ShareModal::Component.new(payload: @published, modal_id: "share-example")
  end
end
