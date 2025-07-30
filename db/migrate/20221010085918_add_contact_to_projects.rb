class AddContactToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :contact, :string
  end
end
