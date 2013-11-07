Spree::CheckoutController.class_eval do

  # TODO Apply gift code in a before filter if possible to avoid overriding the update method for easier upgrades?
  def update
    if @order.update_attributes(object_params)

      fire_event('spree.checkout.update')
      render :edit and return unless apply_coupon_code if defined?(Spree::Promo)
      render :edit and return unless apply_gift_code

      if @order.next
        state_callback(:after)
      else
        flash[:error] = t(:payment_processing_failed)
        respond_with @order, location: checkout_state_path(@order.state)
        return
      end

      if @order.state == 'complete' || @order.completed?
        flash.notice = t(:order_processed_successfully)
        flash[:commerce_tracking] = 'nothing special'
        respond_with @order, location: completion_route
      else
        respond_with @order, location: checkout_state_path(@order.state)
      end
    else
      respond_with(@order) { |format| format.html { render :edit } }
    end
  end

end
