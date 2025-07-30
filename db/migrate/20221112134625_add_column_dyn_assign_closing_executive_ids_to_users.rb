class AddColumnDynAssignClosingExecutiveIdsToUsers < ActiveRecord::Migration
  def change
    add_column :projects, :dyn_assign_closing_executive_ids, :text, array: true, default: []
  end
end
