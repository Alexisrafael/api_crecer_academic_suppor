# frozen_string_literal: true

class Lesson < ApplicationRecord
  belongs_to :course
  has_many :activities, dependent: :destroy
  has_many :user_progresses, dependent: :destroy
end
