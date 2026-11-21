# frozen_string_literal: true

class Activity < ApplicationRecord
  belongs_to :lesson
  has_many :user_progresses, dependent: :destroy
end
