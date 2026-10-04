class Lesson < ApplicationRecord
  belongs_to :course
  has_many :activities, dependent: :destroy
end
