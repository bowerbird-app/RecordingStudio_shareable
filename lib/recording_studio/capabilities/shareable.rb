# frozen_string_literal: true

require "active_support/concern"

module RecordingStudio
  module Capabilities
    #   include RecordingStudio::Capabilities::Shareable.to(
    #     public_url: ->(recordable) { recordable.public_path }
    #   )
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
