class RoundRobinSetting < ActiveRecord::Base

  belongs_to :user
  belongs_to :project
  belongs_to :source

  validates :user_id, uniqueness: { scope: [:source_id, :project_id], message: "and source combination must be unique per project" }

end
