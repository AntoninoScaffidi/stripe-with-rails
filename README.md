# stripe-with-rails

Companion code for the [Stripe with Rails](https://antoninoscaffidi.github.io/series/stripe-with-rails/) series ([Italiano](https://antoninoscaffidi.github.io/it/series/stripe-with-rails/)) — a from-scratch guide to integrating Stripe Checkout into a Ruby on Rails app.

One tag per episode (`episode-1`, `episode-2`, ...) so you can check out the exact code state that matches each post.

## Setup

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
```

You'll need your own Stripe test API keys — free, instant, from the [Stripe Dashboard](https://dashboard.stripe.com/test/apikeys) (test mode, no business verification needed). Add them with:

```bash
bin/rails credentials:edit
```

```yaml
stripe:
  secret_key: sk_test_...
  publishable_key: pk_test_...
  webhook_secret: whsec_...
```

## Running the tests

```bash
bin/rails test
```

11 tests, no live Stripe calls — the Stripe API is stubbed with `Minitest::Mock`.

## Episodes

1. Setting up and initiating a payment (Stripe Checkout)
