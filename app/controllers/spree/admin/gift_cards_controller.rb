module Spree
  module Admin
    class GiftCardsController < Spree::Admin::ResourceController
      before_filter :find_gift_card_variants, :except => [:destroy]

      def create
        @object.attributes = params[object_name]
        @object.admin_created = true
        if @object.save
          flash[:success] = I18n.t(:successfully_created_gift_card)
          redirect_to admin_gift_cards_path
        else
          render :new
        end
      end

      def send_email
        @gift_card = Spree::GiftCard.find(params[:id])
        if @gift_card.order_id
          order = Spree::Order.find(@gift_card.order_id)
          Spree::OrderMailer.gift_card_email(@gift_card, order).deliver
          flash[:success] = I18n.t(:email_was_sent)
        end

        redirect_to admin_gift_cards_path
      end

      private
      def collection
        return @collection if @collection.present?
        params[:q] ||= {}
        @search = super.ransack(params[:q])
        @collection = @search.result.
            order("created_at desc").
            page(params[:page]).
            per(Spree::Config[:admin_products_per_page])

        @collection
      end

      def find_gift_card_variants
        gift_card_product_ids = Product.not_deleted.where(["is_gift_card = ?", true]).map(&:id)
        variants = Variant.joins(:prices).where(["amount > 0 AND product_id IN (?)", gift_card_product_ids]).order("amount")
        master_variants = Variant.joins(:prices).where(["is_master = true AND product_id IN (?)", gift_card_product_ids])
        @gift_card_variants = variants + master_variants
      end

    end
  end
end
