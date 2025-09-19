class AddPostsaleUrlToCompany < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :postsale_url, :string
  end
end
