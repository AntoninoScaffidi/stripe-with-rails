require "test_helper"
require "ostruct"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @fake_session = OpenStruct.new(id: "cs_test_123", url: "https://checkout.stripe.com/pay/cs_test_123")
  end

  test "checkout ignores a tampered total sent in the POST" do
    product = products(:cooking_class)

    Stripe::Checkout::Session.stub(:create, @fake_session) do
      post orders_path, params: {
        product_id: product.id, quantity: 2,
        guest_first_name: "Mario", guest_last_name: "Rossi", guest_email: "mario@example.com",
        total_amount: "1", unit_price: "1" # not even a permitted parameter
      }
    end

    order = Order.last
    assert_equal 35.00, order.unit_price.to_f
    assert_equal 70.00, order.total_amount.to_f
  end

  test "a successful checkout redirects to the Stripe-hosted session URL" do
    product = products(:cooking_class)

    Stripe::Checkout::Session.stub(:create, @fake_session) do
      post orders_path, params: {
        product_id: product.id,
        guest_first_name: "Mario", guest_last_name: "Rossi", guest_email: "mario@example.com"
      }
    end

    assert_redirected_to "https://checkout.stripe.com/pay/cs_test_123"
    assert_equal "cs_test_123", Order.last.stripe_checkout_session_id
  end

  test "a non-purchasable product cannot be checked out" do
    product = products(:not_yet_on_sale)

    assert_no_difference "Order.count" do
      post orders_path, params: {
        product_id: product.id, guest_first_name: "Mario", guest_last_name: "Rossi",
        guest_email: "mario@example.com"
      }
    end

    assert_redirected_to product_path(product)
  end

  test "new redirects away for a non-purchasable product" do
    product = products(:not_yet_on_sale)
    get new_order_path(product_id: product.id)
    assert_redirected_to product_path(product)
  end
end
