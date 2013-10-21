require 'spec_helper'

describe Spree::Order do

  let(:gift_card) { create(:gift_card, variant: create(:variant, price: 25, product: create(:product, is_gift_card: true))) }

  it '#find_line_item_by_variant should return false if variant is gift card' do
    subject.find_line_item_by_variant(gift_card.variant).should eql(false)
  end

  context '#finalize!' do

    context 'when redeeming gift card' do
      it 'debits gift cards current value' do
        gift_card.current_value.should eql(25.0)
        order = create(:order_with_totals)
        order.line_items = [create(:line_item, order: order, price: 75, variant: create(:variant, price: 75))]
        order.reload # reload so line item is associated
        order.update!
        gift_card.apply(order)
        gift_card.reload.current_value.to_f.should eql(25.0)
        order.finalize!
        gift_card.reload.current_value.to_f.should eql(0.0)
      end
    end

    context 'when purchasing gift card' do
      it 'sends emails' do
        order = create(:order_with_totals)
        order.line_items = [create(:line_item, gift_card: gift_card, order: order, price: 25, variant: gift_card.variant)]
        order.reload # reload so line item is associated
        order.update!
        order.finalize!
        gift_card.reload.original_order.should_not be_nil
        Delayed::Job.count.should == 1
      end
    end

    context "with other credits" do
      it "does not let the order total fall below zero" do
        order = create(:order_with_totals)
        order.line_items = [create(:line_item, order: order, price: 40, variant: create(:variant, price: 40))]
        order.adjustments.create(:label => I18n.t(:store_credit) , :amount => -25)
        order.reload
        order.update!
        gift_card.apply(order)
        order.total.to_f.should eql(0.0)
      end
    end

  end

  context '#cancel!' do
    let(:order) { create(:completed_order_with_totals)}
    let(:gift_card) { create(:gift_card, original_order: order, variant: create(:variant, price: 25)) }
    let(:gift_card2) { create(:gift_card, original_order: order, variant: create(:variant, price: 25)) }

    it "should set the current value of an associated gift card to 0 when cancelling" do
      gift_card.current_value.should == 25
      gift_card2.current_value.should == 25
      order.cancel!
      gift_card.reload.current_value.to_f.should == 0
      gift_card2.reload.current_value.to_f.should == 0
    end

  end

end
