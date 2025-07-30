class AddIndexOnCreatedAtToLeads < ActiveRecord::Migration
  def change
    add_index :leads, :created_at
  end
end
