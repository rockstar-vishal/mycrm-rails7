class AddAttachmentToStructure < ActiveRecord::Migration
  def change
    add_attachment :structures, :sv_logo
  end
end
