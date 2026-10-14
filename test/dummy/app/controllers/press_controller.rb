# frozen_string_literal: true

class PressController < ApplicationController
  def show
    @page = Page.find_by!(title: "Getting Started")
    @payload = @page.share_payload
  end
end
