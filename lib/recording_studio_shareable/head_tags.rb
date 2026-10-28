# frozen_string_literal: true

require "action_view"

module RecordingStudioShareable
  module HeadTags
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::OutputSafetyHelper

    def shareable_head_tags(subject = nil, recording: nil, recordable: nil, payload: nil)
      resolved = resolve_head_subject(subject, recording: recording, recordable: recordable)
      payload ||= SharePayload.for(resolved.fetch(:payload_subject))
      return deferred_publishable_tags(resolved) if payload.publishable_enabled?
      return "".html_safe unless payload.available?

      safe_join(shareable_tag_rows(payload), "\n")
    end

    private

    def resolve_head_subject(subject, recording:, recordable:)
      resolved_recording = recording || recording_subject(subject)
      resolved_recordable = recordable || recordable_subject(subject, resolved_recording)
      {
        recording: resolved_recording,
        recordable: resolved_recordable,
        payload_subject: resolved_recording || resolved_recordable
      }
    end

    def recording_subject(subject)
      return subject if defined?(RecordingStudio::Recording) && subject.is_a?(RecordingStudio::Recording)

      nil
    end

    def recordable_subject(subject, recording)
      return recording.recordable if !recording.nil? && recording.respond_to?(:recordable)
      return if subject.nil? || recording_subject(subject)

      subject
    end

    def deferred_publishable_tags(resolved)
      return "".html_safe unless respond_to?(:publishable_head_tags, true)

      publishable_head_tags(**publishable_tag_options(resolved))
    end

    def publishable_tag_options(resolved)
      recording = resolved[:recording]
      options = { parent_recordable: resolved[:recordable] }
      append_publishable_recording(options, recording)
      options
    end

    def append_publishable_recording(options, recording)
      return unless recording

      if recording.respond_to?(:publishable_child_recording)
        options[:publishable_recording] = recording.publishable_child_recording
      end
      options[:publishable] = recording.current_publishable if recording.respond_to?(:current_publishable)
    end

    def shareable_tag_rows(payload)
      rows = [tag.link(rel: "canonical", href: payload.url), tag.meta(property: "og:url", content: payload.url)]
      rows.concat(text_meta_rows(payload))
      rows.concat(image_meta_rows(payload))
      rows << tag.meta(name: "twitter:card", content: twitter_card(payload))
      rows
    end

    def text_meta_rows(payload)
      rows = []
      rows << tag.meta(property: "og:title", content: payload.title) if payload.title.present?
      rows << tag.meta(name: "twitter:title", content: payload.title) if payload.title.present?
      rows.concat(description_meta_rows(payload))
      rows
    end

    def description_meta_rows(payload)
      return [] if payload.description.blank?

      [
        tag.meta(property: "og:description", content: payload.description),
        tag.meta(name: "twitter:description", content: payload.description)
      ]
    end

    def image_meta_rows(payload)
      return [] if payload.image_url.blank?

      [
        tag.meta(property: "og:image", content: payload.image_url),
        tag.meta(name: "twitter:image", content: payload.image_url)
      ]
    end

    def twitter_card(payload)
      payload.image_url.present? ? "summary_large_image" : "summary"
    end
  end
end
