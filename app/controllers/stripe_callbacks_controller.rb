class StripeCallbacksController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [ :webhook ]

  # TODO episode 2: verify the event signature, look up the order via
  # client_reference_id, and mark it paid. For now this only needs to exist
  # so Stripe has an HTTPS endpoint to call.
  def webhook
    head :ok
  end

  def success
    redirect_to root_path
  end

  def cancel
    redirect_to root_path
  end
end
