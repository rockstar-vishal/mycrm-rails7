class AddSvFormBudgetOptionsToProjects < ActiveRecord::Migration[7.1]
  def change
    add_column :projects, :sv_form_budget_options, :text
  end
end
