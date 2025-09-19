class AddIndexToNcdInLeads < ActiveRecord::Migration[7.1]
  def change
    add_index :leads, :ncd
  end
end
