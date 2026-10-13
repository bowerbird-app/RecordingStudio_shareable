# frozen_string_literal: true

module RecordingStudioShareable
  class Configuration
    DEFAULT_DESTINATIONS = %i[copy native linkedin x facebook email].freeze

    attr_reader :destinations, :hooks, :public_base_url
    attr_accessor :public_url, :title, :description, :image

    def initialize
      @public_base_url = nil
      @public_url = nil
      @title = nil
      @description = nil
      @image = nil
      @destinations = DEFAULT_DESTINATIONS.dup
      @hooks = RecordingStudio::Hooks.new
    end

    def public_base_url=(value)
      @public_base_url = value.to_s.strip.sub(%r{/+\z}, "").presence
    end

    def destinations=(value)
      @destinations = self.class.normalize_destinations(value)
    end

    def self.normalize_destinations(value)
      names = Array(value).map { |name| name.to_s.strip.downcase.to_sym }
      unknown = names - DEFAULT_DESTINATIONS
      raise ArgumentError, "unknown share destinations: #{unknown.join(', ')}" if unknown.any?

      names.uniq
    end

    def to_h
      {
        public_base_url: public_base_url,
        destinations: destinations,
        hooks_registered: hook_counts
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each { |key, value| assign_setting(key, value) }
    end

    private

    def assign_setting(key, value)
      setter = "#{key}="
      public_send(setter, value) if respond_to?(setter)
    end

    def hook_counts
      hooks.instance_variable_get(:@registry).transform_values(&:size)
    end
  end
end
