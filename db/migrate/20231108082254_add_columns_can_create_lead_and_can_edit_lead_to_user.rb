class AddColumnsCanCreateLeadAndCanEditLeadToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :disable_create_lead, :boolean, default: false
    add_column :users, :disable_lead_edit, :boolean, default: false
  end
end
