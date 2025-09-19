class AddColumnSmartpingProjectIdToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :smartping_project_id, :string
  end
end