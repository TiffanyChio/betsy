require "test_helper"

describe Order do
  let(:paid_order) { orders(:order2) }
  let(:pending_order) { orders(:pending_order) }
  
  describe "validation" do
    it "will not allow Orders to have no status" do
      paid_order.status = nil
      
      expect(paid_order.valid?).must_equal false
      expect(paid_order.errors.messages).must_include :status
      expect(paid_order.errors.messages[:status]).must_include "can't be blank"
    end
    
    it "will not allow Orders to have status outside of pending, paid, complete, cancel" do
      paid_order.status = "pending"
      expect(paid_order.valid?).must_equal true
      
      paid_order.status = "paid"
      expect(paid_order.valid?).must_equal true
      
      paid_order.status = "complete"
      expect(paid_order.valid?).must_equal true
      
      paid_order.status = "cancel"
      expect(paid_order.valid?).must_equal true
      
      paid_order.status = "bacon"
      expect(paid_order.valid?).must_equal false
      expect(paid_order.errors.messages).must_include :status
      expect(paid_order.errors.messages[:status]).must_include "bacon is not a valid status"
    end
    
    it "can update an Order with valid data" do
      expect{ Orderitem.create(quantity: 1, order: pending_order, product: products(:stella), shipped: false) }.must_change "pending_order.orderitems.count", 1
      
      expect{ 
        pending_order.update(
          email: "abc@123.com",
          address: "123 abc street",
          cc_name: "Mochi Cat",
          cc_num: 12345,
          cvv: 123,
          cc_exp: "12/2013",
          zip: 12345,
          status: "paid"
        )
      }.wont_change "Order.count"
      
      expect(pending_order.email).must_equal "abc@123.com"
      expect(pending_order.address).must_equal "123 abc street"
      expect(pending_order.cc_name).must_equal "Mochi Cat"
      expect(pending_order.cc_num).must_equal "12345"
      expect(pending_order.cvv).must_equal "123"
      expect(pending_order.cc_exp).must_equal "12/2013"
      expect(pending_order.zip).must_equal "12345"
      expect(pending_order.status).must_equal "paid"
      expect(pending_order.orderitems.length).must_equal 1
    end
    
    it "will not update an Order without orderitems" do
      expect(pending_order.orderitems.count).must_equal 0
      
      expect(
        pending_order.update(
          email: "abc@123.com",
          address: "123 abc street",
          cc_name: "Mochi Cat",
          cc_num: 12345,
          cvv: 123,
          cc_exp: "12/2013",
          zip: 12345,
          status: "paid"
        )
      ).must_equal false
      
      updated_order = Order.find_by(id: pending_order.id)
      
      expect(updated_order.email).must_be_nil
      expect(updated_order.address).must_be_nil
      expect(updated_order.cc_name).must_be_nil
      expect(updated_order.cc_num).must_be_nil
      expect(updated_order.cvv).must_be_nil
      expect(updated_order.cc_exp).must_be_nil
      expect(updated_order.zip).must_be_nil
      expect(updated_order.status).must_equal "pending"
    end
    
    it "will outputs errors if updating Orders without orderitems" do
      updated_order = pending_order.update(
        email: "abc@123.com",
        address: "123 abc street",
        cc_name: "Mochi Cat",
        cc_num: 1234,
        cvv: 123,
        cc_exp: "12/2013",
        zip: 12345,
        status: "paid"
      )
      
      expect(updated_order).must_equal false
      expect(pending_order.errors.messages).must_include :orderitems
      expect(pending_order.errors.messages[:orderitems]).must_include "There are no items in your cart!"
    end
    
    describe "All attributes must be present when updating" do
      before do
        expect{ Orderitem.create(quantity: 1, order: pending_order, product: products(:stella), shipped: false) }.must_change "pending_order.orderitems.count", 1
        
        @updated_order = pending_order.update(
          status: "paid"
        )
      end
      
      it "will not update an Order with no email" do
        expect(@updated_order).must_equal false
        expect(pending_order.errors.messages).must_include :email
        expect(pending_order.errors.messages[:email]).must_include "can't be blank"
      end
      
      it "will not update an Order with no address" do
        expect(@updated_order).must_equal false
        expect(pending_order.errors.messages).must_include :address
        expect(pending_order.errors.messages[:address]).must_include "can't be blank"
      end
      
      it "will not update an Order with no cc_name" do
        expect(@updated_order).must_equal false
        expect(pending_order.errors.messages).must_include :cc_name
        expect(pending_order.errors.messages[:cc_name]).must_include "can't be blank"
      end
      
      it "will not update an Order with no cc_num" do
        expect(@updated_order).must_equal false
        expect(pending_order.errors.messages).must_include :cc_num
        expect(pending_order.errors.messages[:cc_num]).must_include "can't be blank"
      end
      
      it "will not update an Order with no cvv" do
        expect(@updated_order).must_equal false
        expect(pending_order.errors.messages).must_include :cvv
        expect(pending_order.errors.messages[:cvv]).must_include "can't be blank"
      end
      
      it "will not update an Order with no cc_exp" do
        expect(@updated_order).must_equal false
        expect(pending_order.errors.messages).must_include :cc_exp
        expect(pending_order.errors.messages[:cc_exp]).must_include "can't be blank"
      end
      
      it "will not update an Order with no zip" do
        expect(@updated_order).must_equal false
        expect(pending_order.errors.messages).must_include :zip
        expect(pending_order.errors.messages[:zip]).must_include "can't be blank"
      end
    end
    
    it "cannot update an Order with a non-numerical cc_num" do
      updated_order = paid_order.update(cc_num: "abc")
      
      expect(updated_order).must_equal false
      expect(paid_order.errors.messages).must_include :cc_num
      expect(paid_order.errors.messages[:cc_num]).must_include "is not a number"
    end 
    
    it "cannot update an Order with a non-numerical cvv" do
      updated_order = paid_order.update(cvv: "abc")
      
      expect(updated_order).must_equal false
      expect(paid_order.errors.messages).must_include :cvv
      expect(paid_order.errors.messages[:cvv]).must_include "is not a number"
    end 
    
    it "cannot update an Order with a non-numerical zip" do
      updated_order = paid_order.update(zip: "abc")
      
      expect(updated_order).must_equal false
      expect(paid_order.errors.messages).must_include :zip
      expect(paid_order.errors.messages[:zip]).must_include "is not a number"
    end 
    
    it "cannot update an Order with a cc_num with less than 4 digits" do
      updated_order = paid_order.update(cc_num: 123)
      
      expect(updated_order).must_equal false
      expect(paid_order.errors.messages).must_include :cc_num
      expect(paid_order.errors.messages[:cc_num]).must_include "is too short (minimum is 4 characters)"
    end 
    
    it "cannot update an Order with a cc_num that is a float" do
      updated_order = paid_order.update(cc_num: 123.4)
      
      expect(updated_order).must_equal false
      expect(paid_order.errors.messages).must_include :cc_num
      expect(paid_order.errors.messages[:cc_num]).must_include "must be an integer"
    end 
    
    it "cannot update an Order with a cvv that is a float" do
      updated_order = paid_order.update(cvv: 3.4)
      
      expect(updated_order).must_equal false
      expect(paid_order.errors.messages).must_include :cvv
      expect(paid_order.errors.messages[:cvv]).must_include "must be an integer"
    end
    
    it "cannot update an Order with a zip that is a float" do
      updated_order = paid_order.update(zip: 3.4)
      
      expect(updated_order).must_equal false
      expect(paid_order.errors.messages).must_include :zip
      expect(paid_order.errors.messages[:zip]).must_include "must be an integer"
    end
  end
  
  
  describe "relationships" do
    it "has many orderitems" do
      expect(paid_order.orderitems.count).must_be :>, 1
      
      paid_order.orderitems.each do |orderitem|
        expect(orderitem).must_be_instance_of Orderitem
      end
    end
    
    it "has many products" do
      expect(paid_order.products.count).must_be :>, 1
      
      paid_order.products.each do |product|
        expect(product).must_be_instance_of Product
      end
    end
  end
  
  describe "custom methods" do
    describe "reduce_stock" do
      it "will reduce the number of product stock by orderitem quantity" do
        expect(products(:heineken).stock).must_equal 3
        expect(products(:corona).stock).must_equal 4
        expect(products(:sapporo).stock).must_equal 5
        
        paid_order.reduce_stock
        
        updated_heineken = Product.find_by(id: products(:heineken).id)
        updated_corona = Product.find_by(id: products(:corona).id)
        updated_sapporo = Product.find_by(id: products(:sapporo).id)
        
        expect(updated_heineken.stock).must_equal 2
        expect(updated_corona.stock).must_equal 3
        expect(updated_sapporo.stock).must_equal 3
      end
    end
    
    describe "return_stock" do
      it "will add back the number of product stock by orderitem quantity if the product is not retired" do
        expect(products(:heineken).stock).must_equal 3
        expect(products(:corona).stock).must_equal 4
        expect(products(:sapporo).stock).must_equal 5
        
        expect(products(:heineken).retired).must_equal false
        expect(products(:corona).retired).must_equal true
        expect(products(:sapporo).retired).must_equal false
        
        paid_order.return_stock
        
        updated_heineken = Product.find_by(id: products(:heineken).id)
        updated_corona = Product.find_by(id: products(:corona).id)
        updated_sapporo = Product.find_by(id: products(:sapporo).id)
        
        expect(updated_heineken.stock).must_equal 4
        expect(updated_corona.stock).must_equal 4
        expect(updated_sapporo.stock).must_equal 7
      end
    end
    
    describe "total" do
      it "can calculate the correct total for a cart" do
        expect(paid_order.total).must_be_close_to 88.88
      end
      
      it "returns 0 for an empty cart" do
        expect(pending_order.total).must_equal 0
      end
    end
    
    describe "mark_as_complete?" do
      it "will not mark an order as complete if there are remaining not-shipped orderitems" do
        expect(orders(:fruit_order).orderitems.count).must_equal 3
        expect(orders(:fruit_order).status).must_equal "paid"
        
        expect(orderitems(:carrot_op).order.id).must_equal orders(:fruit_order).id
        expect(orderitems(:banana_op).order.id).must_equal orders(:fruit_order).id
        expect(orderitems(:peach_op).order.id).must_equal orders(:fruit_order).id
        
        expect(orderitems(:carrot_op).shipped).must_equal true
        expect(orderitems(:banana_op).shipped).must_equal true
        expect(orderitems(:peach_op).shipped).must_equal false
        
        orders(:fruit_order).mark_as_complete?
        updated_order = Order.find_by(id: orders(:fruit_order).id)
        
        expect(updated_order.status).must_equal "paid"
      end
      
      it "will mark an order as complete when the last remaining not-shipped orderitem is shipped" do
        fruit_order = Order.find_by(id: orders(:fruit_order).id)
        
        orderitems(:peach_op).update(shipped: true)
        peach = Orderitem.find_by(id: orderitems(:peach_op).id)
        
        expect(peach.shipped).must_equal true
        
        fruit_order = Order.find_by(id: orders(:fruit_order).id)
        
        fruit_order.mark_as_complete?
        updated_order = Order.find_by(id: orders(:fruit_order).id)
        
        expect(updated_order.status).must_equal "complete"
      end
    end
    
    describe "is_order_of" do
      it "returns true when merchant's product is included in order" do
        dog_order = orders(:dog_order)
        casper_id = merchants(:casper).id
        partydood_id = merchants(:partydood).id
        
        expect(dog_order.is_order_of(casper_id)).must_equal true
        expect(dog_order.is_order_of(partydood_id)).must_equal true
      end
      
      it "returns false when merchant's product is not included in order" do
        dog_order = orders(:dog_order)
        brad_id = merchants(:brad).id
        
        expect(dog_order.is_order_of(brad_id)).must_equal false
      end
    end
  end
end
