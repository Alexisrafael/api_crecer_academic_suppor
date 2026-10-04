class UserProgress < ApplicationRecord
  belongs_to :user
  belongs_to :lesson, optional: true
  belongs_to :activity, optional: true
end
