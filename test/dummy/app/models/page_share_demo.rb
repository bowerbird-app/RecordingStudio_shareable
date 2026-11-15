# frozen_string_literal: true

# Idempotent published, draft, and scheduled pages for the dummy share list.
module PageShareDemo
  PUBLISHED_TITLE = "Getting Started"
  DRAFT_TITLE = "Studio notes"
  SCHEDULED_TITLE = "Fall listening session"
  Row = Struct.new(:key, :page, :recording, :payload, :status, :badge, keyword_init: true)

  class << self
    def scheduled_at
      Time.current.utc.change(min: 0, sec: 0) + 3.days
    end

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
      RecordingStudio::Recording.kept.where(recordable: page).order(:created_at, :id).last
    end

    def ensure!
      previous_actor = Current.actor
      Current.actor ||= demo_actor
      publish!(ensure_recording!(PUBLISHED_TITLE))
      draft!(ensure_recording!(DRAFT_TITLE))
      schedule!(ensure_recording!(SCHEDULED_TITLE))
    ensure
      Current.actor = previous_actor
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
      at = scheduled_at
      return if publishable&.scheduled_for_future? && publishable.publish_at.to_i == at.to_i

      call_service!(
        RecordingStudioPublishable::Services::Publishables::Update,
        parent_recording: recording,
        attributes: { status: "published", publish_at: at, unpublish_at: nil }
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

      root = RecordingStudio.create_root_recording!(workspace, actor: Current.actor)
      folder_recording = child_recording(folder, root, root)
      child_recording(page, root, folder_recording)
    end

    def child_recording(recordable, root_recording, parent_recording)
      RecordingStudio::Recording.kept.find_by(
        root_recording: root_recording,
        parent_recording: parent_recording,
        recordable: recordable
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

    def demo_actor
      User.find_or_create_by!(email: "admin@admin.com") do |user|
        user.password = "Password"
        user.password_confirmation = "Password"
      end
    end
  end
end
