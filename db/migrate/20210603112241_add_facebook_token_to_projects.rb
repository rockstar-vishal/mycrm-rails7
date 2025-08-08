class AddFacebookTokenToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :housing_token, :string
  end
end
