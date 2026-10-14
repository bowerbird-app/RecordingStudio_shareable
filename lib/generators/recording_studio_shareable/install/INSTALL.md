===============================================================================

RecordingStudioShareable has been installed.

Review config/initializers/recording_studio_shareable.rb and set public_base_url
when share paths are relative. Opt a recordable in with:

  include RecordingStudio::Capabilities::Shareable.to(public_url: ->(record) { ... })

This gem has no migrations. Sharing stays off until a recordable opts in.

===============================================================================
