class CreateFacebookExternals < ActiveRecord::Migration[7.1]
  def change
    create_table :facebook_externals do |t|
      t.string :fbform_id
      t.string :endpoint_url

      t.timestamps
    end
  end
end
