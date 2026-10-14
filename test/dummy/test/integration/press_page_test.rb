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
    assert_select "input[name='share_url'][readonly][value=?]", payload.url
    assert_select "[aria-label='Copy input value']"
    assert_select "[aria-label='Share on LinkedIn'][href=?]", payload.destination_urls.fetch(:linkedin), text: "LinkedIn"
    assert_select "[aria-label='Share on X'][href=?]", payload.destination_urls.fetch(:x), text: "X"
    assert_select "[aria-label='Share on Facebook'][href=?]", payload.destination_urls.fetch(:facebook), text: "Facebook"
    assert_select "[aria-label='Share by email'][href=?]", payload.destination_urls.fetch(:email), text: "Email"
    assert_select "#share-page a svg", count: 0
    assert_select "[data-recording-studio-shareable--share-target='native'][hidden]"
    assert_select "[aria-label='Share']", text: "Share"
    assert_select "[aria-label='Share'] svg", count: 0
    assert_includes response.body, "recording-studio-shareable--share"
    assert_includes response.body, %(href="#{payload.url}")
    assert_includes response.body, %(property="og:title")
    assert_includes response.body, %(property="og:image")
    assert_includes response.body, Page::PRESS_IMAGE_URL
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
