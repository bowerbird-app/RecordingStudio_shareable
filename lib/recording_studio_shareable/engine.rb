# frozen_string_literal: true

module RecordingStudioShareable
  class Engine < ::Rails::Engine
    isolate_namespace RecordingStudioShareable

    initializer "recording_studio_shareable.before_initialize",
                before: "recording_studio_shareable.load_config" do |_app|
      RecordingStudioShareable.configuration.hooks.run(:before_initialize, self)
    end

    initializer "recording_studio_shareable.load_config" do |app|
      RecordingStudioShareable::Engine.load_yaml_config(app)
      RecordingStudioShareable::Engine.load_rails_config(app)
      RecordingStudioShareable.configuration.hooks.run(:on_configuration, RecordingStudioShareable.configuration)
    end

    initializer "recording_studio_shareable.after_initialize",
                after: "recording_studio_shareable.load_config" do |_app|
      RecordingStudioShareable.configuration.hooks.run(:after_initialize, self)
    end

    initializer "recording_studio_shareable.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper RecordingStudioShareable::HeadTags
      end
    end

    config.autoload_paths << root.join("app/components")

    initializer "recording_studio_shareable.assets" do |app|
      app.config.assets.paths << root.join("app/javascript") if app.config.respond_to?(:assets)
    end

    initializer "recording_studio_shareable.importmap", before: "importmap" do |app|
      app.config.importmap.paths << root.join("config/importmap.rb") if app.config.respond_to?(:importmap)
    end

    class << self
      def load_yaml_config(app)
        return unless app.respond_to?(:config_for)

        yaml = app.config_for(:recording_studio_shareable)
        RecordingStudioShareable.configuration.merge!(yaml) if yaml.respond_to?(:each)
      rescue StandardError
        nil
      end

      def load_rails_config(app)
        return unless rails_config?(app)

        RecordingStudioShareable.configuration.merge!(rails_config_hash(app.config.x.recording_studio_shareable))
      rescue StandardError
        nil
      end

      def rails_config?(app)
        app.config.respond_to?(:x) && app.config.x.respond_to?(:recording_studio_shareable)
      end

      def rails_config_hash(xcfg)
        return xcfg.to_h if xcfg.respond_to?(:to_h)

        pair_hash(xcfg)
      end

      def pair_hash(xcfg)
        return {} unless xcfg.respond_to?(:each_pair)

        hash = {}
        xcfg.each_pair { |key, value| hash[key] = value }
        hash
      rescue StandardError
        {}
      end
    end
  end
end
