class AddColumnEnquirySubSourceIdToFbForms < ActiveRecord::Migration[7.1]
  def change
    add_column :companies_fb_forms, :enquiry_sub_source_id, :integer
  end
end
