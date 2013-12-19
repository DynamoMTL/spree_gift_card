Spree::Core::Engine.routes.draw do
  resources :gift_cards
  namespace :admin do
    resources :gift_cards
  end
  get '/admin/gift_cards/send_email/:id', to: 'admin/gift_cards#send_email', as: 'admin_gift_cards_send_email'
end
