class AddSvFormBudgetOptionsToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :sv_form_budget_options, :text
  end
end
