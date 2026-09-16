class Order < ApplicationRecord
  VALID_EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  belongs_to :product

  enum :status, { pending_payment: 0, paid: 1, payment_failed: 2, cancelled: 3, refunded: 4 }

  STATUS_LABELS = {
    "pending_payment" => "Waiting for payment",
    "paid" => "Paid",
    "payment_failed" => "Payment failed",
    "cancelled" => "Cancelled",
    "refunded" => "Refunded"
  }.freeze

  before_validation :generate_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true
  validates :unit_price, :total_amount, numericality: { greater_than: 0 }
  validates :quantity, numericality: { greater_than: 0 }
  validates :guest_first_name, :guest_last_name, presence: true
  validates :guest_email, presence: true, format: { with: VALID_EMAIL_REGEX }

  # The route param is :order_number, never the sequential id, in public URLs.
  def to_param
    order_number
  end

  def status_label
    STATUS_LABELS.fetch(status, status.humanize)
  end

  def guest_name
    "#{guest_first_name} #{guest_last_name}".strip
  end

  # Stripe expects amounts as an integer number of the currency's smallest unit
  # (cents, for EUR/USD) — never a decimal.
  def unit_price_in_cents
    (unit_price * 100).round
  end

  # Idempotent: a second call on an already-paid order is a no-op.
  def mark_paid!(stripe_payment_intent_id: nil, stripe_raw_event: nil)
    return if paid?

    update!(
      status: :paid, paid_at: Time.current,
      stripe_payment_intent_id: stripe_payment_intent_id || self.stripe_payment_intent_id,
      stripe_raw_event: stripe_raw_event || self.stripe_raw_event
    )
  end

  # The only place that reads the price from the database and computes the total.
  def self.build_from_product!(product:, guest_attributes:, quantity: 1)
    raise ArgumentError, "Product is not purchasable" unless product.purchasable?

    unit_price = product.price
    quantity = quantity.to_i

    create!(
      product: product, quantity: quantity, unit_price: unit_price,
      total_amount: unit_price * quantity,
      **guest_attributes
    )
  end

  private

  def generate_order_number
    self.order_number ||= loop do
      candidate = SecureRandom.alphanumeric(12).upcase
      break candidate unless Order.exists?(order_number: candidate)
    end
  end
end
