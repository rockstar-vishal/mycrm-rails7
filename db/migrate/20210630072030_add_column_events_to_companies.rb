class AddColumnEventsToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :events, :text, array: true, default: []
  end
end
