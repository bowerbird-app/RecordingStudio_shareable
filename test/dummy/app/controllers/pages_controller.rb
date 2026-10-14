# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @rows = PageShareDemo.rows
  end
end
