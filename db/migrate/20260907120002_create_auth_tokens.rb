class CreateAuthTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :auth_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :auth_tokens, :token, unique: true
    add_index :auth_tokens, :expires_at
    add_index :auth_tokens, :revoked_at
  end
end
