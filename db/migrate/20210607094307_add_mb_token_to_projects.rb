class AddMbTokenToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :mb_token, :string
    add_column :projects, :nine_token, :string
  end
end
