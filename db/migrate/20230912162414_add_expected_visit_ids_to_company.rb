class AddExpectedVisitIdsToCompany < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :expected_visit_ids, :text, array: true, default: []
  end
end
