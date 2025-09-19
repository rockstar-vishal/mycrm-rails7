class AddColumnsToProjects < ActiveRecord::Migration[7.1]

  def change
    add_column :projects, :fb_form_nos, :text, array: true, default: []
    add_index :projects, :fb_form_nos, using: :gin
  end
end
