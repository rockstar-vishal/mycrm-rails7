class Projects::FbForm < ActiveRecord::Base

  belongs_to :project

  validates :form_no, presence: true

end
