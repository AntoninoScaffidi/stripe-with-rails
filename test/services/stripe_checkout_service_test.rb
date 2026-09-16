require "test_helper"
require "ostruct"

class StripeCheckoutServiceTest < ActiveSupport::TestCase
  test "create_session sends the price in cents, not decimal euros" do
    order = orders(:pending_order) # unit_price: 35.00, quantity: 1, currency: eur

    captured_params = nil
    fake_session = OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")

    Stripe::Checkout::Session.stub(:create, ->(params) { captured_params = params; fake_session }) do
      session = StripeCheckoutService.create_session(
        order: order, success_url: "https://example.com/success", cancel_url: "https://example.com/cancel"
      )
      assert_equal "cs_test_123", session.id
    end

    line_item = captured_params[:line_items].first
    assert_equal 3500, line_item[:price_data][:unit_amount]
    assert_equal "eur", line_item[:price_data][:currency]
    assert_equal 1, line_item[:quantity]
  end

  test "create_session sets client_reference_id to our own order_number" do
    order = orders(:pending_order)
    fake_session = OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")
    captured_params = nil

    Stripe::Checkout::Session.stub(:create, ->(params) { captured_params = params; fake_session }) do
      StripeCheckoutService.create_session(
        order: order, success_url: "https://example.com/success", cancel_url: "https://example.com/cancel"
      )
    end

    assert_equal order.order_number, captured_params[:client_reference_id]
  end
end
