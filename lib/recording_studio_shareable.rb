# frozen_string_literal: true

require "recording_studio"
require "recording_studio_shareable/version"
require "recording_studio_shareable/configuration"
require "recording_studio_shareable/url_safety"
require "recording_studio_shareable/destination_urls"
require "recording_studio_shareable/share_payload"
require "recording_studio_shareable/head_tags"
require "recording_studio/capabilities/shareable"
require "recording_studio_shareable/engine"

module RecordingStudioShareable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
