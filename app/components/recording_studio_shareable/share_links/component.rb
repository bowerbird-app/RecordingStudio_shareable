# frozen_string_literal: true

module RecordingStudioShareable
  module ShareLinks
    # Full-width secondary buttons, matching CopyButton's button style.
    class Component < ViewComponent::Base
      LABELS = { linkedin: "LinkedIn", x: "X", facebook: "Facebook", email: "Email" }.freeze

      def initialize(payload:)
        super()
        @payload = payload
      end

      def call
        content_tag(:ul, safe_join(items), **list_attributes)
      end

      private

      def list_attributes
        { class: "m-0 flex list-none flex-col gap-2 p-0", aria: { label: "Share destinations" } }
      end

      def items
        @payload.destination_urls.filter_map { |name, url| item(name.to_sym, url) }
      end

      def item(name, url)
        content_tag(:li, class: "w-full") { destination_button(name, url) }
      end

      def destination_button(name, url)
        render FlatPack::Button::Component.new(**button_options(name, url))
      end

      def button_options(name, url)
        {
          text: LABELS.fetch(name),
          href: url,
          target: (name == :email ? nil : "_blank"),
          style: :secondary,
          size: :md,
          class: "w-full",
          aria: { label: share_label(name) }
        }
      end

      def share_label(name)
        return "Share by email" if name == :email

        "Share on #{LABELS.fetch(name)}"
      end
    end
  end
end
