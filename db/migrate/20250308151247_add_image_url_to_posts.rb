class AddImageUrlToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :image_url, :string
  end
end
