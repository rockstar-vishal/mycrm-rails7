class AddColumnSmartpingProjectIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :smartping_project_id, :string
  end
end