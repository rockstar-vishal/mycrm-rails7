class CreateUsersSources < ActiveRecord::Migration
  def change
    create_table :users_sources, force: :cascade do |t|
      t.integer "source_id", index: true
      t.integer "user_id", index: true

      t.timestamps
    end
  end
end
