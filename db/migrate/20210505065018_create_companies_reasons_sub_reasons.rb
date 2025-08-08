class CreateCompaniesReasonsSubReasons < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :dead_sub_reason, :string
  end
end
