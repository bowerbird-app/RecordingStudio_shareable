module ApplicationHelper
  include RecordingStudioPublishable::ApplicationHelper

  def dummy_page_nav(title:, back_url: nil, back_label: "Home")
    # recording_studio_page_nav was removed in core 6. The local layout still
    # reads these content_for slots.
    content_for(:title, title) if title.present?
    content_for(:page_nav_back_url, back_url) if back_url.present?
    content_for(:page_nav_back_label, back_label) if back_label.present?

    recording_studio_page_nav_right do
      concat recording_studio_root_switch_dropdown(style: :ghost, size: :md)
      concat render(
        FlatPack::Button::Component.new(
          text: "Sign out",
          style: :ghost,
          size: :md,
          href: main_app.destroy_user_session_path,
          data: { turbo_method: :delete }
        )
      )
    end
  end
end
