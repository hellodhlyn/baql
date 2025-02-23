# frozen_string_literal: true

class ImagesController < ApplicationController
  def student
    student_id = params[:id]
    send_webp(SchaleDB::V1::Images.student_collection(student_id))
  end

  def item
    item_id = params[:id]
    send_webp(SchaleDB::V1::Images.item_icon(item_id))
  end

  private

  def send_webp(data)
    expires_in(30.days, public: true)
    send_data(data, type: "image/webp", disposition: "inline")
  end
end
