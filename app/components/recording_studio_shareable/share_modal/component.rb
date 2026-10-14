# frozen_string_literal: true

module RecordingStudioShareable
  module ShareModal
    # Share sheet: preview, copy field, optional device share, and service buttons.
    class Component < ViewComponent::Base
      def initialize(payload:, modal_id:, image_src: nil, image_alt: "")
        super()
        @payload = payload
        @modal_id = modal_id
        @image_src = image_src
        @image_alt = image_alt
      end

      def call
        return "".html_safe unless @payload.available?

        safe_join([render(modal), toast_region])
      end

      private

      def modal
        content = sheet_body
        FlatPack::Modal::Component.new(id: @modal_id, title: "Share", size: :md).tap do |sheet|
          sheet.body { content }
        end
      end

      def sheet_body
        content_tag(:div, class: "flex flex-col gap-5", **controller_attributes) do
          safe_join([preview, copy_field, native_share, destinations])
        end
      end

      def controller_attributes
        {
          data: {
            controller: "recording-studio-shareable--share",
            recording_studio_shareable__share_url_value: @payload.url,
            recording_studio_shareable__share_title_value: @payload.title.to_s,
            recording_studio_shareable__share_text_value: @payload.description.to_s
          }
        }
      end

      def preview
        content_tag(:div, class: "flex items-center gap-4") do
          safe_join([preview_image, preview_copy].compact)
        end
      end

      def preview_image
        return if @image_src.blank?

        tag.img(src: @image_src, alt: @image_alt, class: "h-16 w-16 shrink-0 rounded-lg object-cover")
      end

      def preview_copy
        content_tag(:div, class: "min-w-0") do
          safe_join([
                      content_tag(:p, @payload.title, class: "text-base font-semibold"),
                      content_tag(:p, @payload.description, class: "mt-1 text-sm")
                    ])
        end
      end

      def copy_field
        render CopyLink::Component.new(url: @payload.url)
      end

      def native_share
        content_tag(:div, hidden: true, data: { recording_studio_shareable__share_target: "native" }) do
          render FlatPack::Button::Component.new(
            text: "Share",
            style: :secondary,
            class: "w-full",
            aria: { label: "Share" },
            data: { action: "click->recording-studio-shareable--share#native" }
          )
        end
      end

      def destinations
        render ShareLinks::Component.new(payload: @payload)
      end

      def toast_region
        helpers.render(partial: "recording_studio_shareable/toasts")
      end
    end
  end
end
