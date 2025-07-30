class AddAttachmentsToProjects < ActiveRecord::Migration
  def change
    add_attachment :projects, :project_brochure
    add_attachment :projects, :banner_image
  end
end
