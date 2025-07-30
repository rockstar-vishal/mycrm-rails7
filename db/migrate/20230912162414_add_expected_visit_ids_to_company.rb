class AddExpectedVisitIdsToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :expected_visit_ids, :text, array: true, default: []
  end
end
