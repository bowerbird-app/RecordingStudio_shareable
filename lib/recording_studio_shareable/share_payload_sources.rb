# frozen_string_literal: true

module RecordingStudioShareable
  module SharePayloadSources
    private

    def capability_enabled?(name)
      type_name = recordable_type
      return false if type_name.blank?

      RecordingStudio.capability_enabled?(name, for: type_name)
    rescue StandardError
      false
    end

    def published_url
      return unless recordable.respond_to?(:published_url)

      recordable.published_url
    rescue StandardError
      nil
    end

    def host_public_url
      invoke(setting(:public_url))
    end

    def text_setting(name)
      invoke(setting(name)).to_s.strip.presence
    end

    def publishable_text(method_name)
      source = current_publishable
      return if source.nil?
      return unless source.respond_to?(method_name)

      source.public_send(method_name).to_s.strip.presence
    end

    def recordable_text(method_name)
      return if recordable.nil?
      return unless recordable.respond_to?(method_name)

      recordable.public_send(method_name).to_s.strip.presence
    end

    def current_publishable
      source = publishable_source
      return unless source

      source.current_publishable
    rescue StandardError
      nil
    end

    def publishable_source
      return subject if recording? && subject.respond_to?(:current_publishable)
      return recordable if !recordable.nil? && recordable.respond_to?(:current_publishable)

      nil
    end

    def type_label
      return if recordable_type.blank?

      RecordingStudio.recordable_type_label(recordable_type).to_s.strip.presence
    rescue StandardError
      recordable_type.to_s.demodulize.presence
    end

    def setting(name)
      return overrides[name] if overrides.key?(name)

      options = capability_options
      return options[name] if options.key?(name)

      configuration.public_send(name) if configuration.respond_to?(name)
    end

    def capability_options
      return {} if recordable_type.blank?

      RecordingStudio.capability_options(:shareable, for: recordable_type).to_h.symbolize_keys
    rescue StandardError
      {}
    end

    def invoke(value)
      return if value.nil?
      return value unless value.respond_to?(:call)

      value.arity.zero? ? value.call : value.call(recordable)
    rescue StandardError
      nil
    end

    def configuration
      RecordingStudioShareable.configuration
    end

    def recording?
      defined?(RecordingStudio::Recording) && subject.is_a?(RecordingStudio::Recording)
    end

    def recordable
      recording? ? subject.recordable : subject
    end

    def recordable_type
      return subject.recordable_type if recording?
      return if recordable.nil?

      recordable.class.name
    end
  end
end
