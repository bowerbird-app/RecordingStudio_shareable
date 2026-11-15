# frozen_string_literal: true

# API's default parent is AdminRoot. This dummy has no admin root, so clear
# the list before eager load declares RecordingStudioApi::AdminApi.
RecordingStudioApi.configuration.admin_root_recordable_type_names = []

RecordingStudio.configure do |config|
  # Registered delegated_type recordables (strings or classes)
  config.recordable_types = [
    "Workspace",
    "Folder",
    "Page",
    "RecordingStudioPublishable::Publishable",
    "RecordingStudioAttachable::Attachment",
    # API loads this model on eager load and declares it. The engine only
    # registers it when an admin root is configured.
    "RecordingStudioApi::AdminApi"
  ]

  # Require each configured ActiveRecord type to call recording_studio_recordable.
  config.require_recordable_declarations = true

  # Shown in the shared default layout title fallback.
  config.app_name = "Addon Template" if config.respond_to?(:app_name=)

  # Actor resolver for events when no actor is explicitly supplied
  config.actor = -> { Current.actor }

  # Core 6.5 fails closed without an authorizer. The dummy allows any present actor.
  config.authorize_write = ->(actor:, **) { actor.present? }

  # Emit ActiveSupport::Notifications events
  config.event_notifications_enabled = true

  # Idempotency behavior for log_event!
  config.idempotency_mode = :return_existing # or :raise

  # Recordable duplication strategy for revisions
  config.recordable_dup_strategy = :dup
end
