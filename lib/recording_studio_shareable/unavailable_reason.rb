# frozen_string_literal: true

module RecordingStudioShareable
  # Copy for a share control that cannot open. Publication state comes from
  # Publishable's own predicates. This module only turns that state into a sentence.
  module UnavailableReason
    PUBLISH_REASON = "Publish this page to share it"
    MISSING_URL_REASON = "This page has no public URL."

    def unavailable_reason
      return @unavailable_reason if defined?(@unavailable_reason)

      @unavailable_reason = resolve_unavailable_reason
    end

    private

    def resolve_unavailable_reason
      return if available?
      return unless capability_enabled?(:shareable)

      publishable_enabled? ? publishable_unavailable_reason : MISSING_URL_REASON
    end

    def publishable_unavailable_reason
      return scheduled_reason if publishable_state?(:scheduled?)
      return PUBLISH_REASON if publishable_state?(:draft?) || publishable_state?(:unpublished?)

      MISSING_URL_REASON
    end

    def publishable_state?(method_name)
      record = recordable
      return false if record.nil? || !record.respond_to?(method_name)

      record.public_send(method_name)
    rescue StandardError
      false
    end

    def scheduled_reason
      date = scheduled_on
      return "Scheduled; sharing opens then" if date.blank?

      "Scheduled for #{date}; sharing opens then"
    end

    def scheduled_on
      source = schedule_publishable
      return if source.nil? || !source.respond_to?(:publish_at)

      time = source.publish_at
      return if time.blank?

      time = time.in_time_zone(source.effective_time_zone) if zoned_publishable?(source)
      "#{time.strftime('%B')} #{time.day}, #{time.year}"
    rescue StandardError
      nil
    end

    def schedule_publishable
      current_publishable || publishable_from_recording
    end

    def publishable_from_recording
      recording = parent_recording
      return unless recording.respond_to?(:current_publishable)

      recording.current_publishable
    rescue StandardError
      nil
    end

    def parent_recording
      return subject if recording?
      return unless defined?(RecordingStudio::Recording)

      record = recordable
      return if record.nil? || record.class.name.blank? || !record.respond_to?(:id)

      RecordingStudio::Recording.where(recording_conditions(record)).order(:created_at, :id).last
    end

    def recording_conditions(record)
      conditions = { recordable_type: record.class.name, recordable_id: record.id }
      return conditions unless defined?(RecordingStudioPublishable::TrashedAt)
      return conditions unless RecordingStudioPublishable::TrashedAt.respond_to?(:merge_active)

      RecordingStudioPublishable::TrashedAt.merge_active(conditions)
    end

    def zoned_publishable?(source)
      source.respond_to?(:effective_time_zone) && source.effective_time_zone.present?
    end
  end
end
