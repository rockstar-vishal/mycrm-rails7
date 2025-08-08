class AddSubSourceToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :sub_source, :string
  end
end
