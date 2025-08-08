class AddBookingDonefieldsToLeads < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :booked_flat_no, :string
    add_column :leads, :bank_loan_name, :string
    add_column :leads, :bank_person_name, :string
    add_column :leads, :bank_person_contact, :string
    add_column :leads, :bank_sales_person, :string
  end
end
