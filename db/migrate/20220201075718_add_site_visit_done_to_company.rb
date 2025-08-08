class AddSiteVisitDoneToCompany < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :site_visit_done_id, :integer
  end
end
