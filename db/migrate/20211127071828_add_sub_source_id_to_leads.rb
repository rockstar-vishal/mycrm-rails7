class AddSubSourceIdToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :enquiry_sub_source_id, :integer
  end
end
