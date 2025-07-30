class AddColumnsToProjects < ActiveRecord::Migration

  def change
    add_column :projects, :fb_form_nos, :text, array: true, index: true, default: []
  end
end
