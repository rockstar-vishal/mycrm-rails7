class AddContactToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :contact, :string
  end
end
