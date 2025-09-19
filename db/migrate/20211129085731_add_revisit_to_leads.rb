class AddRevisitToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :revisit, :boolean, default: false
  end
end
