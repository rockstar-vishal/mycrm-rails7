class Leads::SecondarySource < ActiveRecord::Base
  belongs_to :lead, class_name: "::Lead"
  belongs_to :source, class_name: "::Source"

  validates :source_id, uniqueness: { scope: :lead_id}
end
