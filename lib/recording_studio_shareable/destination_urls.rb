# frozen_string_literal: true

require "uri"

module RecordingStudioShareable
  # Standard share endpoints. No API credentials or SDKs.
  module DestinationUrls
    LINKEDIN = "https://www.linkedin.com/sharing/share-offsite/"
    X = "https://twitter.com/intent/tweet"
    FACEBOOK = "https://www.facebook.com/sharer/sharer.php"

    module_function

    def for(url:, title:, destinations:)
      selected = Array(destinations).map(&:to_sym)
      endpoints(url: url, title: title).slice(*selected)
    end

    def endpoints(url:, title:)
      {
        linkedin: linkedin(url),
        x: x(url, title: title),
        facebook: facebook(url),
        email: email(url, title: title)
      }
    end

    def linkedin(url)
      "#{LINKEDIN}?#{encode(url: url)}"
    end

    def x(url, title:)
      params = { url: url }
      text = title.to_s.strip
      params[:text] = text if text.present?
      "#{X}?#{encode(params)}"
    end

    def facebook(url)
      "#{FACEBOOK}?#{encode(u: url)}"
    end

    def email(url, title:)
      subject = title.to_s.strip.presence || url
      body = [title.to_s.strip.presence, url].compact.uniq.join("\n")
      "mailto:?#{encode(subject: subject, body: body)}"
    end

    def encode(params)
      URI.encode_www_form(params)
    end
  end
end
