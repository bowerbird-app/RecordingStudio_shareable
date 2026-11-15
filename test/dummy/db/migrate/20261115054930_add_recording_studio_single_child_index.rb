# frozen_string_literal: true

class AddRecordingStudioSingleChildIndex < ActiveRecord::Migration[8.1]
  def change
    if index_exists?(:recording_studio_recordings, name: "index_rs_publishable_child_per_parent")
      remove_index :recording_studio_recordings, name: "index_rs_publishable_child_per_parent"
    end

    add_index :recording_studio_recordings,
              %i[parent_recording_id recordable_type],
              unique: true,
              name: "index_recording_studio_recordings_on_single_child",
              where: "recordable_type IN ('RecordingStudioPublishable::Publishable')",
              if_not_exists: true
  end
end
