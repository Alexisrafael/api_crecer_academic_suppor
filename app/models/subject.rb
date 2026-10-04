class Subject < ApplicationRecord
  has_many :courses, dependent: :destroy
end
