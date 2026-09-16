class OrdersController < ApplicationController
  before_action :set_product, only: [ :new, :create ]

  def new
    redirect_to(product_path(@product)) and return unless @product.purchasable?

    @order = Order.new
  end

  def create
    redirect_to(product_path(@product)) and return unless @product.purchasable?

    @order = Order.build_from_product!(
      product: @product,
      guest_attributes: order_params.to_h,
      quantity: order_params[:quantity].presence || 1
    )

    session = StripeCheckoutService.create_session(
      order: @order,
      success_url: stripe_success_url(order_number: @order.order_number),
      cancel_url: stripe_cancel_url(order_number: @order.order_number)
    )
    @order.update!(stripe_checkout_session_id: session.id)

    redirect_to session.url, allow_other_host: true
  rescue ActiveRecord::RecordInvalid => e
    @order = e.record
    render :new, status: :unprocessable_entity
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def order_params
    params.permit(:quantity, :guest_first_name, :guest_last_name, :guest_email, :guest_phone)
  end
end
