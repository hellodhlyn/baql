# frozen_string_literal: true

class ImagesController < ApplicationController
  def student_collection
    uid = params[:uid]
    send_webp(SchaleDB::V1::Images.student_collection(uid))
  end

  def student_standing
    uid = params[:uid]
    send_webp(SchaleDB::V1::Images.student_standing(uid))
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
