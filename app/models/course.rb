# frozen_string_literal: true

class Course < ApplicationRecord
  belongs_to :subject
  belongs_to :user

  has_many :lessons, dependent: :destroy
  has_many :activities, through: :lessons
  has_many :enrollments, dependent: :destroy
  has_many :students, through: :enrollments, source: :user
end
