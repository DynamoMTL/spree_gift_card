class AddAdminCreatedToSpreeGiftCards < ActiveRecord::Migration
  def change
    add_column :spree_gift_cards, :admin_created, :boolean, default: false
  end
end
