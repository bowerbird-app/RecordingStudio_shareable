# frozen_string_literal: true

require "test_helper"

class DestinationUrlsTest < Minitest::Test
  URL = "https://public.example/kits/1?ref=share"
  TITLE = "Press kit & photos"

  def test_builds_encoded_social_endpoints
    urls = RecordingStudioShareable::DestinationUrls.for(
      url: URL,
      title: TITLE,
      destinations: %i[linkedin x facebook email]
    )

    assert_equal "https://www.linkedin.com/sharing/share-offsite/?url=#{encoded_url}", urls[:linkedin]
    assert_equal "https://twitter.com/intent/tweet?url=#{encoded_url}&text=#{encoded_title}", urls[:x]
    assert_equal "https://www.facebook.com/sharer/sharer.php?u=#{encoded_url}", urls[:facebook]
    assert_includes urls[:email], "mailto:?"
    assert_includes urls[:email], "subject=#{encoded_title}"
    assert_includes urls[:email], encoded_url
    refute_includes urls[:linkedin], " "
    refute_includes urls[:x], "& photos"
  end

  def test_omits_text_when_title_is_blank_and_skips_unrequested_destinations
    urls = RecordingStudioShareable::DestinationUrls.for(
      url: URL,
      title: " ",
      destinations: [:facebook]
    )

    assert_equal [:facebook], urls.keys
    assert_equal "mailto:?subject=#{encoded_url}&body=#{encoded_url}",
                 RecordingStudioShareable::DestinationUrls.email(URL, title: nil)
    refute_includes RecordingStudioShareable::DestinationUrls.x(URL, title: nil), "text="
  end

  private

  def encoded_url
    URI.encode_www_form_component(URL)
  end

  def encoded_title
    URI.encode_www_form_component(TITLE)
  end
end
