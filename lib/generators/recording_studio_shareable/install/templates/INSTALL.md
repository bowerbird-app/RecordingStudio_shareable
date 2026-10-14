RecordingStudioShareable install complete.

Next steps:

1. Review config/initializers/recording_studio_shareable.rb and set `public_base_url` if share paths are relative.
2. If you use environment-specific settings, create config/recording_studio_shareable.yml.
3. Opt a recordable in with `include RecordingStudio::Capabilities::Shareable.to(public_url: ->(record) { ... })`.
4. Run `bin/rails tailwindcss:build` if you use Tailwind CSS.
5. This gem has no migrations.
6. Mount routes are added at the configured mount path. Adjust auth, layout, and current actor integration to match your host app.
7. Keep strict recordable declarations enabled and add `recording_studio_recordable(...)` to every configured recordable before running `RecordingStudio.validate_recordable_declarations!`.