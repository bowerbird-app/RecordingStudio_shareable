# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class ShareableDemoTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "shareable-demo@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    @page = Page.find_or_create_by!(title: "Getting Started")
    @folder = Folder.find_or_create_by!(name: "Product Docs")
    sign_in @user
  end

  test "demo shows the page payload, destination links, head tags, and an unshared folder" do
    get shareable_demo_path

    assert_response :success
    payload = @page.share_payload
    encoded_url = CGI.escape(payload.url)

    assert_equal "https://press.example/pages/#{@page.id}", payload.url
    assert_equal "Getting Started", payload.title
    assert_nil payload.description
    assert_predicate payload, :available?
    refute RecordingStudioShareable::SharePayload.for(@folder).available?

    assert_select "#payload-availability", text: "Available"
    assert_select "#payload-url", text: payload.url
    assert_select "#payload-title", text: "Getting Started"
    assert_select "#payload-description", text: "None"
    assert_select "#destination-linkedin[href=?]", payload.destination_urls.fetch(:linkedin)
    assert_select "#destination-x[href=?]", payload.destination_urls.fetch(:x)
    assert_select "#destination-facebook[href=?]", payload.destination_urls.fetch(:facebook)
    assert_select "#destination-email[href=?]", payload.destination_urls.fetch(:email)
    assert_select "#destination-copy", text: "No URL"
    assert_select "#destination-native", text: "No URL"
    assert_includes payload.destination_urls.fetch(:linkedin), encoded_url
    assert_select "#head-tags-output", text: /rel="canonical"/
    assert_select "#head-tags-output", text: /property="og:title"/
    assert_select "#head-tags-output", text: /Getting Started/
    refute_includes css_select("#head-tags-output").text, "og:description"
    assert_select "#unavailable-availability", text: "Unavailable"
    assert_select "#unavailable-url", text: "None"
    assert_select "#unavailable-links", text: "None"
    assert_select "#unavailable-head-tags", text: "Empty"
    assert_includes response.body, %(href="#{payload.url}")
  end

  test "demo requires a signed-in user" do
    sign_out @user

    get shareable_demo_path

    assert_redirected_to new_user_session_path
  end
end
