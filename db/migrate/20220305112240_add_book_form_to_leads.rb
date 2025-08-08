class AddBookFormToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :booking_date, :date
    # Active Storage handles file attachments automatically
    # add_attachment :leads, :booking_form
  end
end
