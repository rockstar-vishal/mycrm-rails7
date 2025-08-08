class AddAttachmentToStructure < ActiveRecord::Migration[7.1]
  def change
    # Active Storage handles file attachments automatically
    # add_attachment :structures, :sv_logo
  end
end
