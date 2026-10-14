# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PagesShareTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "pages-share@example.com") do |user|
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
    end
    sign_in @user
  end

  test "page list disables sharing until publishable says the page is public" do
    get pages_path

    assert_response :success
    assert_select "h1", text: "Pages"
    assert_select "#share-row-published [aria-label='Share this page'][data-modal-id='share-published']"
    assert_select "#share-row-published [aria-disabled]", count: 0
    assert_select "#share-published [role='dialog']"

    draft = css_select("#share-row-draft").to_html
    assert_includes draft, "Publish this page to share it"
    assert_includes draft, 'aria-disabled="true"'
    assert_includes draft, "aria-describedby"
    assert_includes draft, 'disabled="disabled"'
    refute_includes draft, "data-modal-id"
    refute_includes draft, "href="
    refute_share_url draft

    scheduled = css_select("#share-row-scheduled").to_html
    assert_includes scheduled, "Scheduled for Tuesday 3 November at 3:00 PM. You can share it then."
    assert_includes scheduled, 'aria-disabled="true"'
    assert_includes scheduled, 'tabindex="0"'
    refute_includes scheduled, "href="
    refute_share_url scheduled
    refute_includes scheduled, "press.example"
  end

  private

  def refute_share_url(html)
    refute_match %r{https?://(?!www\.w3\.org/2000/svg)}, html
  end
end
