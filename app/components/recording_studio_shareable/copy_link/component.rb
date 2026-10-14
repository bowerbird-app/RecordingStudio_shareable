# frozen_string_literal: true

module RecordingStudioShareable
  module CopyLink
    # Full-width FlatPack copy button. Copied feedback is the button's own state.
    class Component < ViewComponent::Base
      LABEL = "Copy link"

      def initialize(url:)
        super()
        @url = url
      end

      def call
        content_tag(:div, class: "w-full [&>span]:w-full [&>span>button]:w-full") do
          render FlatPack::CopyButton::Component.new(
            text: @url,
            label: LABEL,
            style: :secondary,
            size: :md
          )
        end
      end
    end
  end
end
