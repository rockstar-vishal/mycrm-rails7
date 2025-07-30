class AddIndexToNcdInLeads < ActiveRecord::Migration
  def change
    add_index :leads, :ncd
  end
end
