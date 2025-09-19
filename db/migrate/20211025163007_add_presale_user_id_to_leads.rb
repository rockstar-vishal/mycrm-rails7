class AddPresaleUserIdToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :presale_user_id, :integer
  end
end
