Spree::OrderMailer.class_eval do
  def gift_card_email(card, order)
    @gift_card = card
    @order = order
    subject = "#{order.name} got you a Blue Bottle Coffee gift card!"
    @gift_card.update_attribute(:sent_at, Time.now)
    mail(to: card.email, from: from_address, subject: subject)
  end
end
