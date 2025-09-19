class CreateProjectsFbForms < ActiveRecord::Migration[7.1]
  def change
    create_table :projects_fb_forms do |t|
      t.string :form_no
      t.string :title
      t.integer :enquiry_sub_source_id, index: true
      t.integer :project_id, index: true

      t.timestamps
    end
  end
end
