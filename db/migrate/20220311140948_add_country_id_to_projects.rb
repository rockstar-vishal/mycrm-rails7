class AddCountryIdToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :country_id, :integer
  end
end
