class AddCrmLogoFieldsToMobileCrmLogo < ActiveRecord::Migration
  def change
    add_attachment :mobile_crm_logos, :large_favicon
    add_attachment :mobile_crm_logos, :er_sm_logo
  end
end
