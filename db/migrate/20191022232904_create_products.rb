class CreateProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :products do |t|
      t.string :name
      t.string :description
      t.float :price
      t.string :photo_url
      t.integer :stock

      t.timestamps
    end
  end
end
