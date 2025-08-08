class AddColumnsImagesToLeads < ActiveRecord::Migration[7.1]
  def change
    # Active Storage handles image attachments automatically
    # add_attachment :leads, :image
  end
end
