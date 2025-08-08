class AddAttachmentSiteVisitFormToLeadsVisits < ActiveRecord::Migration[7.1]
  def self.up
    # Active Storage handles file attachments automatically
    # change_table :leads_visits do |t|
    #   t.attachment :site_visit_form
    # end
  end

  def self.down
    # Active Storage handles file attachments automatically
    # remove_attachment :leads_visits, :site_visit_form
  end
end
