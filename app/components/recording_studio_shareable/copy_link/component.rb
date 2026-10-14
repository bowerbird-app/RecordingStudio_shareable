# frozen_string_literal: true

module RecordingStudioShareable
  module CopyLink
    # Read-only link field. FlatPack quick_copy shows the copied toast.
    class Component < ViewComponent::Base
      def initialize(url:)
        super()
        @url = url
      end

      def call
        render FlatPack::TextInput::Component.new(
          name: "share_url",
          label: "Link",
          value: @url,
          quick_copy: true
        )
      end
    end
  end
end
