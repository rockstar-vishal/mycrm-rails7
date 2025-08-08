class AddPresaleStageIdToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :presale_stage_id, :integer
  end
end
