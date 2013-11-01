require 'spree/core/validators/email'

module Spree
  class GiftCard < ActiveRecord::Base

    UNACTIVATABLE_ORDER_STATES = ["complete", "awaiting_return", "returned"]

    attr_accessor :amount
    attr_accessible :email, :name, :note, :variant_id, :amount, :order_id

    belongs_to :original_order, class_name: 'Order', foreign_key: 'order_id'
    belongs_to :variant
    belongs_to :line_item

    has_many :transactions, class_name: 'Spree::GiftCardTransaction'

    validates :code,               presence: true, uniqueness: true
    validates :current_value,      presence: true
    validates :email, email: true, presence: true
    validates :name,               presence: true
    validates :original_value,     presence: true

    before_validation :generate_code, on: :create
    before_validation :set_calculator, on: :create
    before_validation :set_values, on: :create

    calculated_adjustments

    def apply(order)
      # Nothing to do if the gift card is already associated with the order
      order.remove_existing_gift_card_credits
      return if order.gift_credit_exists?(self)
      order.update!
      create_adjustment(I18n.t(:gift_card), order, order, true)
      order.update!
    end

    # Calculate the amount to be used when creating an adjustment
    def compute_amount(calculable)
      self.calculator.compute(calculable, self)
    end

    def debit(amount, order)
      raise 'Cannot debit gift card by amount greater than current value.' if (self.current_value - amount.to_f.abs) < 0
      transaction = self.transactions.build
      transaction.amount = amount
      transaction.order  = order
      self.current_value = self.current_value - amount.abs
      self.amount = current_value
      self.save
    end

    def price
      self.line_item ? self.line_item.price * self.line_item.quantity : self.variant.price
    end

    def order_activatable?(order)
      redeemable? &&
      order &&
      current_value > 0 &&
      !UNACTIVATABLE_ORDER_STATES.include?(order.state)
    end

    def sender
      original_order.present? ? original_order.email : ''
    end

    def order_number
      original_order.present? ? original_order.number : ''
    end

    def redeemable?
      (original_order && original_order.complete?) || admin_created?
    end

    def self.list_redeemable_by_email(email)
      self.where(email: email).order('created_at DESC').select { |card| card.redeemable? }
    end

    def self.find_by_code(code)
      where(code: code.downcase)
    end

    private

    def generate_code
      until self.code.present? && self.class.where(code: self.code).count == 0
        self.code = Digest::SHA1.hexdigest([Time.now, rand].join)[0..20]
      end
    end

    def set_calculator
      self.calculator = Spree::Calculator::GiftCard.new
    end

    def set_values
      self.current_value  = self.variant.try(:price)
      self.original_value = self.variant.try(:price)
    end

  end
end
