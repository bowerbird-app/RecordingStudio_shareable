# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PressPageTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "press-page@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    @page = Page.find_or_create_by!(title: "Getting Started")
    sign_in @user
  end

  test "press page renders the article, share sheet, and head tags" do
    get press_path

    assert_response :success
    payload = @page.share_payload

    assert_equal Page::PRESS_TITLE, payload.title
    assert_equal Page::PRESS_DESCRIPTION, payload.description
    assert_equal Page::PRESS_IMAGE_URL, payload.image_url
    assert_select "article#press-article"
    assert_select "img[src='#{Page::PRESS_IMAGE_PATH}']"
    assert_select "[aria-label='Share this page'][data-modal-id='share-page'][aria-haspopup='dialog']"
    assert_select "#share-page[role='dialog'], #share-page [role='dialog']"
    assert_select "input[name='share_url']", count: 0
    assert_select "p", text: payload.url
    assert_select "button[aria-label='Copy link'][data-fp-style='secondary'].fp-button.fp-copy-button"
    assert_select "[data-flat-pack--clipboard-text-value=?]", payload.url
    assert_select "[data-flat-pack--clipboard-copied-label-value='Copied']"
    assert_select "[data-flat-pack--clipboard-target='label']", text: "Copy link"
    assert_operator response.body.index("Copy link"), :<, response.body.index("Share on LinkedIn")
    assert_select "[aria-label='Share on LinkedIn'][href=?]", payload.destination_urls.fetch(:linkedin), text: "LinkedIn"
    assert_select "[aria-label='Share on X'][href=?]", payload.destination_urls.fetch(:x), text: "X"
    assert_select "[aria-label='Share on Facebook'][href=?]", payload.destination_urls.fetch(:facebook), text: "Facebook"
    assert_select "[aria-label='Share by email'][href=?]", payload.destination_urls.fetch(:email), text: "Email"
    assert_select "#share-page a svg", count: 0
    assert_select "[data-recording-studio-shareable--share-target='native'][hidden]"
    assert_select "[aria-label='Share']", text: "Share"
    assert_select "[aria-label='Share'] svg", count: 0
    assert_includes response.body, "recording-studio-shareable--share"
    assert_includes payload.url, "https://press.example/published/"
    assert_includes response.body, %(data-flat-pack--clipboard-text-value="#{payload.url}")
    refute_includes response.body, "https://press.example/pages/#{@page.id}"
    assert_includes response.body, %(property="og:title")
    assert_includes response.body, %(rel="canonical")
    refute_includes response.body, "Resolved payload"
    refute_includes response.body, "shareable_head_tags"
  end

  test "press page requires a signed-in user and the debug route is gone" do
    sign_out @user

    get press_path
    assert_redirected_to new_user_session_path

    sign_in @user
    get "/shareable"
    assert_response :not_found
  end
end
