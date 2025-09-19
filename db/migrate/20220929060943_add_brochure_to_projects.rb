class AddBrochureToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :brochure_link, :string
    add_column :projects, :location, :string
  end
end
