class AddReferenceFieldsToLead < ActiveRecord::Migration[7.1]
  def change
    add_column :leads, :referal_name, :string
    add_column :leads, :referal_mobile, :string
    add_column :sources, :is_reference, :boolean, default: false
  end
end
