class AddAttachmentsToProjects < ActiveRecord::Migration[7.1]
  def change
    # Active Storage handles file attachments automatically
    # add_attachment :projects, :project_brochure
    # add_attachment :projects, :banner_image
  end
end
