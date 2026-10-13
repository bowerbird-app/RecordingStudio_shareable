# frozen_string_literal: true

class ShareableDemoController < ApplicationController
  def show
    @page = Page.find_by!(title: "Getting Started")
    @folder = Folder.find_by!(name: "Product Docs")
    @page_payload = @page.share_payload
    @folder_payload = RecordingStudioShareable::SharePayload.for(@folder)
  end
end
