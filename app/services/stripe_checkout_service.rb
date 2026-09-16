class StripeCheckoutService
  def self.create_session(order:, success_url:, cancel_url:)
    Stripe::Checkout::Session.create(
      mode: "payment",
      line_items: [
        {
          price_data: {
            currency: order.currency,
            product_data: { name: order.product.name },
            unit_amount: order.unit_price_in_cents
          },
          quantity: order.quantity
        }
      ],
      customer_email: order.guest_email,
      client_reference_id: order.order_number,
      success_url: success_url,
      cancel_url: cancel_url
    )
  end
end
