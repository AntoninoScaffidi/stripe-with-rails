require "test_helper"

class StripeCallbacksControllerTest < ActionDispatch::IntegrationTest
  SECRET = "whsec_test_secret"

  setup do
    @order = orders(:pending_order)
  end

  test "a validly signed checkout.session.completed marks the order paid" do
    payload = checkout_completed_payload(order: @order)

    post_webhook(payload)

    assert_response :ok
    @order.reload
    assert @order.paid?
    assert_equal "pi_test_123", @order.stripe_payment_intent_id
  end

  test "an unsigned request is rejected and the order is left untouched" do
    payload = checkout_completed_payload(order: @order)

    Rails.application.credentials.stub(:dig, SECRET) do
      post stripe_webhook_path, params: payload,
        headers: { "Content-Type" => "application/json", "Stripe-Signature" => "t=1,v1=not_a_real_signature" }
    end

    assert_response :bad_request
    assert_not @order.reload.paid?
  end

  test "a retried delivery of the same event is a no-op the second time" do
    payload = checkout_completed_payload(order: @order)

    post_webhook(payload)
    assert @order.reload.paid?
    paid_at_first = @order.paid_at

    post_webhook(payload) # Stripe retries deliveries; the event id is identical

    assert_response :ok
    assert_equal 1, StripeEvent.where(stripe_event_id: "evt_test_123").count
    assert_equal paid_at_first, @order.reload.paid_at
  end

  test "an event for an unknown order is accepted but changes nothing" do
    payload = checkout_completed_payload(order: @order, order_number: "DOES_NOT_EXIST")

    post_webhook(payload)

    assert_response :ok
    assert_not @order.reload.paid?
  end

  private

  def checkout_completed_payload(order:, order_number: nil, event_id: "evt_test_123")
    {
      id: event_id,
      object: "event",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_123",
          object: "checkout.session",
          client_reference_id: order_number || order.order_number,
          payment_intent: "pi_test_123"
        }
      }
    }.to_json
  end

  def post_webhook(payload)
    timestamp = Time.current
    signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, SECRET)
    sig_header = Stripe::Webhook::Signature.generate_header(timestamp, signature)

    Rails.application.credentials.stub(:dig, SECRET) do
      post stripe_webhook_path, params: payload,
        headers: { "Content-Type" => "application/json", "Stripe-Signature" => sig_header }
    end
  end
end
