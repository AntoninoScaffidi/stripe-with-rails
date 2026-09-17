require "test_helper"

class StripeEventTest < ActiveSupport::TestCase
  test "requires a stripe_event_id and event_type" do
    event = StripeEvent.new
    assert_not event.valid?
    assert_includes event.errors.attribute_names, :stripe_event_id
    assert_includes event.errors.attribute_names, :event_type
  end

  test "stripe_event_id must be unique" do
    StripeEvent.create!(stripe_event_id: "evt_dup", event_type: "checkout.session.completed")
    duplicate = StripeEvent.new(stripe_event_id: "evt_dup", event_type: "checkout.session.completed")

    assert_not duplicate.valid?
  end
end
