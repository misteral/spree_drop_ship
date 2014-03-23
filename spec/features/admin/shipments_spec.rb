require 'spec_helper'

describe 'Admin - Shipments', js: true do

  context 'as Supplier' do

    before do
      new_method = create(:shipping_method, :name => "Newer")
      @order = create(:order_ready_for_drop_ship, state: 'complete')
      @supplier = @order.suppliers.first
      @order.shipments.each do |ship|
        ship.add_shipping_method new_method, true
        ship.save!
      end
      login_user create(:user, supplier: @supplier)
      @shipment = @order.shipments.where(stock_location_id: @supplier.stock_locations.first.id).first
      visit spree.edit_admin_shipment_path(@shipment)
    end

    context 'edit page' do

      it "can add tracking information" do
        within 'table.index tr.show-tracking' do
          click_icon :edit
        end
        within 'table.index tr.edit-tracking' do
          fill_in "tracking", :with => "FOOBAR"
          click_icon :ok
        end
        within 'table.index tr.show-tracking' do
          page.should have_content("Tracking: FOOBAR")
        end
      end

      it "can change the shipping method" do
        within("table.index tr.show-method") do
          click_icon :edit
        end
        select2 "Newer", :from => "Shipping Method"
        click_icon :ok
        wait_for_ajax

        page.should have_content("Newer $0.00")
      end

      it "can ship a completed order" do
        click_link "ship"
        wait_for_ajax

        page.should have_content("SHIPPED PACKAGE")
        @order.reload.shipment_state.should == "shipped"
      end
    end

    it 'should render unauthorized visiting another suppliers shipment' do
      visit spree.edit_admin_shipment_path(create(:shipment))
      page.should have_content('Authorization Failure')
    end
  end

end
