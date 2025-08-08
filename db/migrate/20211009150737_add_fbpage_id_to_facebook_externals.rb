class AddFbpageIdToFacebookExternals < ActiveRecord::Migration[7.1]
  def change
    add_column :facebook_externals, :fbpage_id, :string
  end
end
