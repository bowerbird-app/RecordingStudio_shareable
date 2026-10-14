class Page < ApplicationRecord
  PRESS_TITLE = "Bowerbird Studio press kit"
  PRESS_DESCRIPTION = "A portrait of the room, a short history, and the facts editors ask for first."
  PRESS_IMAGE_URL = "https://press.example/press/studio-kit.jpg"
  PRESS_IMAGE_PATH = "/press/studio-kit.jpg"
  PRESS_IMAGE_ALT = "The studio live room, seen from the control-room window."

  recording_studio_recordable label: "Page", root: false, allowed_parent_types: [ "Workspace", "Folder" ]

  # Host public URL only. Publication rules stay outside this gem.
  include RecordingStudio::Capabilities::Shareable.to(
    public_url: ->(page) { "https://press.example/pages/#{page.id}" },
    title: PRESS_TITLE,
    description: PRESS_DESCRIPTION,
    image: PRESS_IMAGE_URL
  )
end
