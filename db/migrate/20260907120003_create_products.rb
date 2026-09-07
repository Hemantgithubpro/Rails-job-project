class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD"
      t.integer :stock_quantity, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.string :sku, null: false

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :name
    add_index :products, :active
    add_index :products, :price_cents
  end
end
