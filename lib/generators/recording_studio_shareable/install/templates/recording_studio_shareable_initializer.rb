# frozen_string_literal: true

RecordingStudioShareable.configure do |config|
  # Absolute origin used only to prefix relative share paths.
  # Already-absolute URLs are left unchanged.
  # config.public_base_url = "https://example.com"

  # config.destinations = %i[copy native linkedin x facebook email]

  # Used when a recordable opts into Shareable and does not pass its own public_url.
  # Ignored when that recordable also has Publishable enabled.
  # config.public_url = ->(recordable) { recordable.try(:public_url) }

  # Optional copy overrides. Each may be a string or a callable that receives the recordable.
  # config.title = ->(recordable) { recordable.try(:title) }
  # config.description = ->(recordable) { recordable.try(:description) }
  # config.image = ->(_recordable) { "https://cdn.example/card.png" }
end
