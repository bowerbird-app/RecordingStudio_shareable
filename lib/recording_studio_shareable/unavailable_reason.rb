# frozen_string_literal: true

module RecordingStudioShareable
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
      stamp = scheduled_stamp
      return "Scheduled. You can share it then." if stamp.blank?

      "Scheduled for #{stamp}. You can share it then."
    end

    def scheduled_stamp
      source = schedule_publishable
      return if source.nil? || !source.respond_to?(:publish_at)

      time = source.publish_at
      return if time.blank?

      zoned = time.in_time_zone(Time.zone)
      minutes = zoned.min.to_s.rjust(2, "0")
      I18n.l(zoned, format: "%A #{zoned.day} %B at #{twelve_hour(zoned)}:#{minutes} %p")
    rescue StandardError
      nil
    end

    def twelve_hour(time)
      hour = time.hour % 12
      hour.zero? ? 12 : hour
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
  end
end
