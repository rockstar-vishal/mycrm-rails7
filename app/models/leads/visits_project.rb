class Leads::VisitsProject < ActiveRecord::Base

  belongs_to :leads_visit, :class_name=>"Leads::Visit", foreign_key: :visit_id
  belongs_to :project

end
