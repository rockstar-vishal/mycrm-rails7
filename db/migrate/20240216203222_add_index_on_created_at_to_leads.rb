class AddIndexOnCreatedAtToLeads < ActiveRecord::Migration[7.1]
  def change
    add_index :leads, :created_at
  end
end
