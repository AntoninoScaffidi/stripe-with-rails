class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :order_number, null: false
      t.references :product, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false
      t.integer :quantity, null: false, default: 1
      t.string :currency, null: false, default: "eur"
      t.string :guest_first_name, null: false
      t.string :guest_last_name, null: false
      t.string :guest_email, null: false
      t.string :guest_phone
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.jsonb :stripe_raw_event
      t.datetime :paid_at

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :stripe_checkout_session_id, unique: true
  end
end
