# frozen_string_literal: true

require "active_support/concern"

module RecordingStudio
  module Capabilities
    # Opt-in share metadata for one recordable type.
    #
    #   include RecordingStudio::Capabilities::Shareable.to(
    #     public_url: ->(recordable) { recordable.public_path }
    #   )
    #
    # Loading the gem does not enable this. `.to` wraps
    # RecordingStudio::Capabilities.include_for.
    module Shareable
      def self.to(**)
        RecordingStudio::Capabilities.include_for(:shareable, **) do |base|
          base.include(RecordableMethods) unless base < RecordableMethods
        end
      end

      module RecordableMethods
        extend ActiveSupport::Concern

        def share_payload
          RecordingStudioShareable::SharePayload.for(self)
        end

        def shareable?
          share_payload.available?
        end
      end
    end
  end
end

RecordingStudio.register_capability(
  :shareable,
  source: RecordingStudio::Capabilities::Shareable
)
