class AddCallerDeskProjetIdToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :caller_desk_project_id, :integer
  end
end
