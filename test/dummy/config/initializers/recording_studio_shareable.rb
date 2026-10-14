# frozen_string_literal: true

# Shareable stays opt-in. Do not enable it on a recordable from this initializer.
RecordingStudioShareable.configure do |config|
  config.public_base_url = "https://press.example"
end
