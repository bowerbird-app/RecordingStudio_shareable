# frozen_string_literal: true

require_relative "share_payload_sources"
require_relative "unavailable_reason"

module RecordingStudioShareable
  # Resolves the share URL, copy, and destination links for one recordable.
  # Publishable decides whether a public URL exists. This object only distributes it.
  class SharePayload
    include SharePayloadSources
    include UnavailableReason

    def self.for(subject, **overrides)
      new(subject, **overrides)
    end

    def initialize(subject, **overrides)
      @subject = subject
      @overrides = overrides
    end

    def available?
      url.present?
    end

    def publishable_enabled?
      capability_enabled?(:publishable)
    end

    def url
      return @url if defined?(@url)

      @url = resolve_url
    end

    def title
      return @title if defined?(@title)

      @title = resolve_title
    end

    def description
      return @description if defined?(@description)

      @description = resolve_description
    end

    def image_url
      return @image_url if defined?(@image_url)

      @image_url = UrlSafety.absolute_https_url(invoke(setting(:image)))
    end

    def destinations
      @destinations ||= resolved_destinations
    end

    def destination_urls
      return {} unless available?

      DestinationUrls.for(url: url, title: title, destinations: destinations)
    end

    private

    attr_reader :subject, :overrides

    def resolve_url
      return unless capability_enabled?(:shareable)

      raw = publishable_enabled? ? published_url : host_public_url
      UrlSafety.absolute_http_url(raw, base_url: configuration.public_base_url)
    end

    def resolve_title
      text_setting(:title) || publishable_text(:social_title) || publishable_text(:seo_title) ||
        recordable_text(:title) || recordable_text(:name) || type_label
    end

    def resolve_description
      text_setting(:description) || publishable_text(:social_description) ||
        publishable_text(:seo_description) || recordable_text(:description)
    end

    def resolved_destinations
      value = setting(:destinations)
      return configuration.destinations if value.nil?

      Configuration.normalize_destinations(value)
    end
  end
end
