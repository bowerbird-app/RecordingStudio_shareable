class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: false, allowed_parent_types: [ "Workspace", "Folder" ]

  # Host public URL only. Publishable is not enabled for Page.
  include RecordingStudio::Capabilities::Shareable.to(
    public_url: ->(page) { "https://press.example/pages/#{page.id}" }
  )
end
