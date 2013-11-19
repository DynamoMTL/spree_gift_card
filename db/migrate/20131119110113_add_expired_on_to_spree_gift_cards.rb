class AddExpiredOnToSpreeGiftCards < ActiveRecord::Migration
  def change
    add_column :spree_gift_cards, :expired_on, :date, default: nil
  end
end
