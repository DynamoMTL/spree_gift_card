require 'spec_helper'

feature "Admin Gift Card Administration", js: true do

  stub_authorization!

  before do
    ## TODO seed helper for gc
    product = Spree::Product.new(available_on: Time.now, name: "Gift Card", is_gift_card: true, permalink: 'gift-card', price: 0)
    option_type = Spree::OptionType.new(name: "is-gift-card", presentation: "Value")
    product.option_types << option_type
    [25, 50, 75, 100].each do |value|
      option_value = Spree::OptionValue.new(name: value, presentation: "$#{value}")
      option_value.option_type = option_type
      variant = Spree::Variant.new(price: value.to_i, sku: "GIFTCERT#{value}", on_hand: 1000)
      variant.option_values << option_value
      product.variants << variant
    end
    product.save
  end

  scenario 'creating gift card' do
    visit spree.admin_gift_cards_path
    Spree::GiftCard.count.should eql(0)
    click_link 'New Gift Card'
    fill_in 'gift_card[email]', with: 'spree@example.com'
    fill_in 'gift_card[name]', with: 'First Last'
    fill_in 'gift_card[note]', with: 'Test message.'
    fill_in 'gift_card[amount]', with: 50
    click_button 'Create'
    page.should have_content('You have successfully created the gift card.')
    within 'table.index' do
      page.should have_content('First Last')
      Spree::GiftCard.count.should eql(1)
    end
  end

  scenario 'creating gift card with invalid data renders new form with errors' do
    visit spree.admin_gift_cards_path
    Spree::GiftCard.count.should eql(0)
    click_link 'New Gift Card'
    fill_in 'gift_card[email]', with: 'example.com'
    fill_in 'gift_card[name]', with: 'First Last'
    fill_in 'gift_card[note]', with: 'Test message.'
    fill_in 'gift_card[amount]', with: 50
    click_button 'Create'
    page.should have_css('.field_with_errors #gift_card_email')
    Spree::GiftCard.count.should eql(0)
  end

  scenario 'deleting gift card' do
    create :gift_card, name: 'First Last'
    visit spree.admin_gift_cards_path
    within 'table.index' do
      page.should have_content('First Last')
      click_link 'Delete'
      page.driver.browser.switch_to.alert.accept
    end
    wait_until do
      Spree::GiftCard.count.should eql(0)
    end
  end

  scenario 'updating gift card' do
    create :gift_card, name: 'Testing'
    visit spree.admin_gift_cards_path
    click_link 'Edit'
    fill_in 'gift_card[email]', with: 'spree@example.com'
    fill_in 'gift_card[name]', with: 'First Last'
    fill_in 'gift_card[note]', with: 'Test message.'
    fill_in 'gift_card[amount]', with: 50
    click_button 'Update'
    page.should have_content("Gift card \"First Last\" has been successfully updated!")
    within 'table.index' do
      page.should have_content('First Last')
    end
  end

  scenario 'list original order details' do
    original_order = create(:completed_order_with_totals)
    create :gift_card, name: 'For Bryan from Alex', original_order: original_order
    visit spree.admin_gift_cards_path
    within 'table.index' do
      page.should have_content(original_order.email)
      page.should have_content(original_order.number)
    end
  end

end
