class AddColumnsImagesToLeads < ActiveRecord::Migration
  def change
    add_attachment :leads, :image
  end
end
