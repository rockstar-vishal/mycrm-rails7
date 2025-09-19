class AddProjectIdToMcubeSids < ActiveRecord::Migration[7.1]
  def change
    add_column :mcube_sids, :project_id, :integer
  end
end
