# frozen_string_literal: true

# Idempotent published, draft, and scheduled pages for the dummy share list.
module PageShareDemo
  PUBLISHED_TITLE = "Getting Started"
  DRAFT_TITLE = "Studio notes"
  SCHEDULED_TITLE = "Fall listening session"
  SCHEDULED_AT = Time.utc(2026, 11, 3, 15, 0, 0)
  Row = Struct.new(:key, :page, :recording, :payload, :status, :badge, keyword_init: true)

  class << self
    def rows
      ensure!
      [
        row(:published, PUBLISHED_TITLE, "Published", :success),
        row(:draft, DRAFT_TITLE, "Draft", :default),
        row(:scheduled, SCHEDULED_TITLE, "Scheduled", :warning)
      ]
    end

    def published_page
      ensure!
      Page.find_by!(title: PUBLISHED_TITLE)
    end

    def recording_for(page)
      RecordingStudio::Recording.where(recordable: page, trashed_at: nil).order(:created_at, :id).last
    end

    def ensure!
      publish!(ensure_recording!(PUBLISHED_TITLE))
      draft!(ensure_recording!(DRAFT_TITLE))
      schedule!(ensure_recording!(SCHEDULED_TITLE))
    end

    private

    def row(key, title, status, badge)
      page = Page.find_by!(title: title)
      recording = recording_for(page)
      Row.new(
        key: key,
        page: page,
        recording: recording,
        payload: page.share_payload,
        status: status,
        badge: badge
      )
    end

    def publish!(recording)
      return if recording.publishable_child_recording&.recordable&.currently_published?

      transition!(recording, "publish")
    end

    def draft!(recording)
      publishable = recording.publishable_child_recording&.recordable
      return if publishable&.draft_state? && !publishable.scheduled_for_future?

      transition!(recording, "draft")
    end

    def schedule!(recording)
      publishable = recording.publishable_child_recording&.recordable
      return if publishable&.scheduled_for_future? && publishable.publish_at == SCHEDULED_AT

      call_service!(
        RecordingStudioPublishable::Services::Publishables::Update,
        parent_recording: recording,
        attributes: { status: "published", publish_at: SCHEDULED_AT, unpublish_at: nil }
      )
    end

    def transition!(recording, transition)
      call_service!(
        RecordingStudioPublishable::Services::Publishables::Transition,
        parent_recording: recording,
        transition: transition
      )
    end

    def call_service!(service, **kwargs)
      service.call(**kwargs, actor: Current.actor).value!
    end

    def ensure_recording!(title)
      page = Page.find_or_create_by!(title: title)
      existing = recording_for(page)
      return existing if existing

      root = RecordingStudio.root_recording_for(workspace)
      folder_recording = child_recording(folder, root, root)
      child_recording(page, root, folder_recording)
    end

    def child_recording(recordable, root_recording, parent_recording)
      RecordingStudio::Recording.find_by(
        root_recording: root_recording,
        parent_recording: parent_recording,
        recordable: recordable,
        trashed_at: nil
      ) || RecordingStudio.record!(
        action: "created",
        recordable: recordable,
        root_recording: root_recording,
        parent_recording: parent_recording
      ).recording
    end

    def workspace
      Workspace.find_or_create_by!(name: "Studio Workspace")
    end

    def folder
      Folder.find_or_create_by!(name: "Product Docs")
    end
  end
end
