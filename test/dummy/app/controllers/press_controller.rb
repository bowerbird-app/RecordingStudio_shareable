# frozen_string_literal: true

class PressController < ApplicationController
  def show
    @page = PageShareDemo.published_page
    @recording = PageShareDemo.recording_for(@page)
    @payload = @page.share_payload
  end
end
