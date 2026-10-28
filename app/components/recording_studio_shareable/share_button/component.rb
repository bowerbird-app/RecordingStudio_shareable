# frozen_string_literal: true

module RecordingStudioShareable
  module ShareButton
    # Opens the share modal. FlatPack owns the button primitive so this can be
    # swapped when FlatPack ships its own share button.
    class Component < ViewComponent::Base
      MODES = %i[hide disable].freeze

      def initialize(payload:, modal_id:, when_unavailable: :hide)
        super()
        @payload = payload
        @modal_id = modal_id
        @when_unavailable = when_unavailable.to_sym
        validate_mode!
      end

      def call
        return enabled_button if @payload.available?
        return "".html_safe unless @when_unavailable == :disable

        disabled_button
      end

      private

      def validate_mode!
        return if MODES.include?(@when_unavailable)

        raise ArgumentError, "when_unavailable must be one of: #{MODES.join(', ')}"
      end

      def enabled_button
        render FlatPack::Button::Component.new(**enabled_options)
      end

      def enabled_options
        {
          text: "Share",
          icon: "share",
          style: :secondary,
          size: :md,
          aria: { label: "Share this page", haspopup: "dialog", controls: @modal_id },
          data: { modal_id: @modal_id }
        }
      end

      def disabled_button
        render FlatPack::Tooltip::Component.new(**tooltip_options) do |tooltip|
          tooltip.tooltip_content { reason_text }
          disabled_control
        end
      end

      def tooltip_options
        {
          placement: :top,
          tabindex: "0",
          aria: { label: "Share this page", describedby: reason_id }
        }
      end

      def reason_text
        content_tag(:span, @payload.unavailable_reason, id: reason_id)
      end

      def disabled_control
        render FlatPack::Button::Component.new(**disabled_options)
      end

      def disabled_options
        {
          text: "Share",
          icon: "share",
          style: :secondary,
          size: :md,
          disabled: true,
          aria: { label: "Share this page", disabled: "true", describedby: reason_id }
        }
      end

      def reason_id
        @reason_id ||= "share-unavailable-#{@modal_id.to_s.parameterize}"
      end
    end
  end
end
