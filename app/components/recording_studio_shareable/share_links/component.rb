# frozen_string_literal: true

module RecordingStudioShareable
  module ShareLinks
    # Icon buttons for the social destinations that have URLs.
    class Component < ViewComponent::Base
      LABELS = { linkedin: "LinkedIn", x: "X", facebook: "Facebook", email: "Email" }.freeze
      MARKS = { linkedin: "in", x: "X", facebook: "f" }.freeze

      def initialize(payload:)
        super()
        @payload = payload
      end

      def call
        content_tag(:ul, safe_join(items), **list_attributes)
      end

      private

      def list_attributes
        { class: "m-0 flex list-none flex-wrap justify-between gap-3 p-0", aria: { label: "Share destinations" } }
      end

      def items
        @payload.destination_urls.filter_map { |name, url| item(name.to_sym, url) }
      end

      def item(name, url)
        content_tag(:li, class: "flex w-16 flex-col items-center gap-2 text-center") do
          safe_join([destination_button(name, url), content_tag(:span, LABELS[name], class: "text-xs")])
        end
      end

      def destination_button(name, url)
        render FlatPack::Button::Component.new(**button_options(name, url))
      end

      def button_options(name, url)
        options = shared_button_options(name, url)
        return email_button_options(options) if name == :email

        options.merge(text: MARKS.fetch(name), target: "_blank")
      end

      def shared_button_options(name, url)
        { href: url, style: :secondary, size: :lg, class: "rounded-full", aria: { label: share_label(name) } }
      end

      def email_button_options(options)
        options.merge(text: "Email", icon: "envelope", icon_only: true)
      end

      def share_label(name)
        return "Share by email" if name == :email

        "Share on #{LABELS[name]}"
      end
    end
  end
end
