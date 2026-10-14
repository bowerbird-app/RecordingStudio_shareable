# frozen_string_literal: true

module RecordingStudioShareable
  module ShareButton
    # Opens the share modal. FlatPack owns the button primitive so this can be
    # swapped when FlatPack ships its own share button.
    class Component < ViewComponent::Base
      def initialize(payload:, modal_id:)
        super()
        @payload = payload
        @modal_id = modal_id
      end

      def call
        return "".html_safe unless @payload.available?

        render FlatPack::Button::Component.new(**button_options)
      end

      private

      def button_options
        {
          text: "Share",
          icon: "share",
          style: :secondary,
          size: :md,
          aria: { label: "Share this page", haspopup: "dialog", controls: @modal_id },
          data: { modal_id: @modal_id }
        }
      end
    end
  end
end
