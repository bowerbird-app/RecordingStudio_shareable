# frozen_string_literal: true

require "cgi"
require "uri"

module RecordingStudioShareable
  module UrlSafety
    BLOCKED_FRAGMENTS = [
      "active_storage",
      "publishable/preview",
      "recording_studio"
    ].freeze

    module_function

    def absolute_http_url(value, base_url:)
      candidate = absolutize(value, base_url: base_url)
      candidate if http_url?(candidate) && allowed?(candidate)
    end

    def absolute_https_url(value)
      candidate = value.to_s.strip
      candidate if https_url?(candidate) && allowed?(candidate)
    end

    def absolutize(value, base_url:)
      string = value.to_s.strip
      return if string.empty? || string.start_with?("//")
      return string if http_url?(string)
      return join_base(base_url, string) if string.start_with?("/")

      nil
    end

    def http_url?(value)
      scheme?(value, %w[http https])
    end

    def https_url?(value)
      scheme?(value, %w[https])
    end

    def allowed?(value)
      uri = parse(value)
      return false unless uri

      blocked = BLOCKED_FRAGMENTS.any? { |fragment| location(uri).include?(fragment) }
      !blocked
    end

    def join_base(base_url, path)
      base = base_url.to_s.strip.sub(%r{/+\z}, "")
      return unless http_url?(base)

      "#{base}#{path}"
    end

    def scheme?(value, schemes)
      uri = parse(value)
      uri && schemes.include?(uri.scheme&.downcase) && uri.host.present?
    end

    def location(uri)
      CGI.unescape([uri.path, uri.query].compact.join("?")).downcase
    rescue StandardError
      [uri.path, uri.query].compact.join("?").downcase
    end

    def parse(value)
      return if value.blank?

      URI.parse(value.to_s)
    rescue URI::InvalidURIError
      nil
    end
  end
end
