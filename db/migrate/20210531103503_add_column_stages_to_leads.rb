class AddColumnStagesToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :stage, :string
  end
end
