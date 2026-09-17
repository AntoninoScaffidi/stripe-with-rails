class StripeCallbacksController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [ :webhook ]

  def webhook
    payload = request.body.read
    sig_header = request.headers["Stripe-Signature"]
    webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue JSON::ParserError, Stripe::SignatureVerificationError => e
      Rails.logger.warn("[Stripe] Webhook rejected: #{e.message}")
      head :bad_request and return
    end

    begin
      StripeEvent.create!(stripe_event_id: event.id, event_type: event.type, raw_payload: event.to_hash)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      # Stripe retried a delivery we already processed — idempotent no-op.
      # RecordInvalid comes from the model uniqueness validation (the common
      # path); RecordNotUnique would only fire if that validation were ever
      # bypassed and the DB's own unique index caught it instead.
      head :ok and return
    end

    handle_event(event)

    head :ok
  end

  def success
    redirect_to root_path
  end

  def cancel
    redirect_to root_path
  end

  private

  def handle_event(event)
    case event.type
    when "checkout.session.completed"
      handle_checkout_completed(event)
    end
  end

  def handle_checkout_completed(event)
    session = event.data.object
    order = Order.find_by(order_number: session.client_reference_id)
    return if order.nil? || !order.pending_payment?

    order.mark_paid!(
      stripe_payment_intent_id: session.payment_intent,
      stripe_raw_event: event.to_hash
    )
  end
end
