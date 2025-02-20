require "test_helper"

describe OrdersController do
  let(:valid_params){
    {
      order: {
        email: "anything@gmail.com",
        address: "123 abcstreet",
        cc_name: "Mochi Cat",
        cc_num: 12345,
        cvv: 123,
        cc_exp: "12/2019",
        zip: 11111,
      },
    }
  }
  
  describe "empty/uninitialized carts/orders" do
    it "returns redirect to root path with a flash message for the cart action" do
      get cart_path
      
      must_respond_with :redirect
      must_redirect_to root_path
      
      expect(flash[:status]).must_equal :failure
    end
    
    it "returns not found for the edit action" do
      get edit_order_path(id: Order.first.id)
      must_respond_with :not_found
    end
    
    it "returns not found for the update action" do
      expect { patch order_path(id: Order.first.id), params: valid_params }.wont_change "Order.count"
      must_respond_with :not_found
    end
    
    describe "show" do
      it "returns not found for the show action with an invalid ID" do
        get order_path(id: -1)
        must_respond_with :not_found
      end
      
      it "redirects to root path with flash messages for orders with valid IDs but pending status" do
        get order_path(id: orders(:order1))
        
        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
      end
      
      it "responds with success for valid orders with paid status" do
        get order_path(id: orders(:fruit_order))
        
        must_respond_with :success
      end
      
      it "responds with success for valid orders with completed status" do
        orders(:fruit_order).update!(status: "complete")
        updated_order = Order.find_by(id: orders(:fruit_order).id)
        
        expect(updated_order.status).must_equal "complete"
        
        get order_path(id: orders(:fruit_order))
        
        must_respond_with :success
      end
      
      it "responds with success for valid orders with cancelled status" do
        orders(:fruit_order).update!(status: "cancel")
        updated_order = Order.find_by(id: orders(:fruit_order).id)
        
        expect(updated_order.status).must_equal "cancel"
        
        get order_path(id: orders(:fruit_order))
        
        must_respond_with :success
      end
    end
    
    describe "cancel" do
      it "returns not found for the show action with an invalid ID" do
        patch cancel_order_path(id: -1)
        must_respond_with :not_found
      end
      
      it "redirects to root path with flash messages for orders with pending status" do
        patch cancel_order_path(id: orders(:order1))
        
        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
      end
      
      it "redirects to root path with flash messages for orders with complete status" do
        orders(:order1).update!(status: "complete")
        updated_order = Order.find_by(id: orders(:order1).id)
        
        expect(updated_order.status).must_equal "complete"
        
        patch cancel_order_path(id: orders(:order1))
        
        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
      end
      
      it "redirects to root path with flash messages for orders with cancel status" do
        orders(:order1).update!(status: "cancel")
        updated_order = Order.find_by(id: orders(:order1).id)
        
        expect(updated_order.status).must_equal "cancel"
        
        patch cancel_order_path(id: orders(:order1))
        
        must_redirect_to root_path
        expect(flash[:status]).must_equal :failure
      end
      
      it "changes status to cancel, returns product stock, and redirects to order path for valid orders with paid status" do
        expect(orders(:fruit_order).status).must_equal "paid"
        
        patch cancel_order_path(id: orders(:fruit_order))
        
        updated_order = Order.find_by(id: orders(:fruit_order).id)
        updated_carrot = Product.find_by(id: products(:carrot).id)
        updated_banana = Product.find_by(id: products(:banana).id)
        updated_peach = Product.find_by(id: products(:peach).id)
        
        expect(updated_order.status).must_equal "cancel"
        expect(updated_carrot.stock).must_equal 12
        expect(updated_banana.stock).must_equal 12
        expect(updated_peach.stock).must_equal 12
        
        must_redirect_to order_path(id: updated_order.id)
      end
    end
  end
  
  describe "initialized carts/orders" do
    before do
      post product_orderitems_path(product_id: products(:cat_food).id), params: { orderitem: { quantity: 2, }, }
      post product_orderitems_path(product_id: products(:kitty_litter).id), params: { orderitem: { quantity: 1, }, }
      post product_orderitems_path(product_id: products(:cat_toy).id), params: { orderitem: { quantity: 3, }, }
    end
    
    describe "cart" do
      it "returns success for an existing session order id" do
        get cart_path
        must_respond_with :success
      end
    end
    
    describe "edit" do
      it "returns success for an existing session order id" do
        get edit_order_path(id: -1)
        must_respond_with :success
      end
    end
    
    describe "update" do
      it "can purchase an order with valid payment information" do
        expect(session[:order_id]).wont_be_nil
        current_order = Order.last
        expect(current_order.orderitems.count).must_equal 3
        expect(current_order.status).must_equal "pending"
        expect(current_order.products.find_by(name: "Cat Toy")).wont_be_nil
        
        expect{ patch order_path(current_order), params: valid_params }.wont_change "Order.count"
        
        updated_order = Order.find_by(id: current_order.id)
        
        expect(updated_order.status).must_equal "paid"
        expect(updated_order.email).must_equal "anything@gmail.com"
        expect(updated_order.address).must_equal "123 abcstreet"
        expect(updated_order.cc_name).must_equal "Mochi Cat"
        expect(updated_order.cc_num).must_equal "12345"
        expect(updated_order.cvv).must_equal "123"
        expect(updated_order.cc_exp).must_equal "12/2019"
        expect(updated_order.zip).must_equal "11111"
        
        expect(session[:order_id]).must_be_nil
        
        expect(Product.find_by(id: products(:cat_food).id).stock).must_equal 8
        expect(Product.find_by(id: products(:kitty_litter).id).stock).must_equal 9
        expect(Product.find_by(id: products(:cat_toy).id).stock).must_equal 7
        
        must_redirect_to order_path(updated_order)
      end
      
      it "cannot purchase out of stock items" do
        products(:cat_toy).update!(stock: 1)
        expect(Product.find_by(id: products(:cat_toy).id).stock).must_equal 1
        current_order = Order.last
        
        expect{ patch order_path(current_order), params: valid_params }.wont_change "Order.count"
        
        updated_order = Order.find_by(id: current_order.id)
        
        expect(updated_order.status).must_equal "pending"
        expect(updated_order.email).must_be_nil
        expect(updated_order.address).must_be_nil
        expect(updated_order.cc_name).must_be_nil
        expect(updated_order.cc_num).must_be_nil
        expect(updated_order.cvv).must_be_nil
        expect(updated_order.cc_exp).must_be_nil
        expect(updated_order.zip).must_be_nil
        
        expect(Product.find_by(id: products(:cat_food).id).stock).must_equal 10
        expect(Product.find_by(id: products(:kitty_litter).id).stock).must_equal 10
        expect(Product.find_by(id: products(:cat_toy).id).stock).must_equal 1
        
        expect(flash.now[:status]).must_equal :failure
        must_redirect_to cart_path
      end
      
      it "cannot purchase retired items" do
        products(:cat_toy).update!(retired: true)
        expect(Product.find_by(id: products(:cat_toy).id).retired).must_equal true
        current_order = Order.last
        
        expect{ patch order_path(current_order), params: valid_params }.wont_change "Order.count"
        
        updated_order = Order.find_by(id: current_order.id)
        
        expect(updated_order.status).must_equal "pending"
        expect(updated_order.email).must_be_nil
        expect(updated_order.address).must_be_nil
        expect(updated_order.cc_name).must_be_nil
        expect(updated_order.cc_num).must_be_nil
        expect(updated_order.cvv).must_be_nil
        expect(updated_order.cc_exp).must_be_nil
        expect(updated_order.zip).must_be_nil
        
        expect(Product.find_by(id: products(:cat_food).id).stock).must_equal 10
        expect(Product.find_by(id: products(:kitty_litter).id).stock).must_equal 10
        expect(Product.find_by(id: products(:cat_toy).id).stock).must_equal 10
        
        expect(flash.now[:status]).must_equal :failure
        must_redirect_to cart_path
      end
      
      it "cannot purchase an order with missing fields" do
        invalid_param = {
          order: {
            email: nil,
          },
        }
        
        current_order = Order.last
        expect{ patch order_path(current_order), params: invalid_param }.wont_change "Order.count"
        
        updated_order = Order.find_by(id: current_order.id)
        
        expect(updated_order.valid?).must_equal false
        expect(updated_order.errors.messages).must_include :email
        expect(updated_order.errors.messages).must_include :address
        expect(updated_order.errors.messages).must_include :cc_name
        expect(updated_order.errors.messages).must_include :cc_num
        expect(updated_order.errors.messages).must_include :cvv
        expect(updated_order.errors.messages).must_include :cc_exp
        expect(updated_order.errors.messages).must_include :zip
        
        expect(updated_order.errors.messages[:email]).must_include "can't be blank"
        expect(updated_order.errors.messages[:address]).must_include "can't be blank"
        expect(updated_order.errors.messages[:cc_name]).must_include "can't be blank"
        expect(updated_order.errors.messages[:cc_num]).must_include "can't be blank"
        expect(updated_order.errors.messages[:cvv]).must_include "can't be blank"
        expect(updated_order.errors.messages[:cc_exp]).must_include "can't be blank"
        expect(updated_order.errors.messages[:zip]).must_include "can't be blank"
      end
      
      it "cannot purchase an order with no orderitems" do
        current_order = Order.last
        
        current_order.orderitems.each do |orderitem|
          orderitem.destroy
        end
        
        expect{ patch order_path(current_order), params: valid_params }.wont_change "Order.count"
        
        updated_order = Order.find_by(id: current_order.id)
        
        expect(session[:order_id]).must_equal updated_order.id
        expect(updated_order.orderitems.count).must_equal 0
        
        expect(updated_order.valid?).must_equal false
        expect(updated_order.errors.messages).must_include :orderitems
        expect(updated_order.errors.messages[:orderitems]).must_include "There are no items in your cart!"
      end
    end
  end
  
  describe "guest user - merchant_order" do
    it "does not allow gues users to access merchant_order path" do
      get merchant_order_path(id: Order.first.id)
      
      must_redirect_to root_path
      expect(flash[:error]).wont_be_nil
    end
  end
  
  describe "logged-in user - merchant_order" do 
    it "does not allow merchants who's products are not a part of the order to access page" do
      perform_login(merchants(:brad))
      order_id = orders(:dog_order)
      
      get merchant_order_path(id: order_id)
      
      must_respond_with :redirect
      expect(flash[:status]).must_equal :failure
    end
    
    it "returns not found for an invalid order id" do
      perform_login(merchants(:casper))
      order_id = -1
      
      get merchant_order_path(id: order_id)
      
      must_respond_with :not_found
    end
    
    it "returns success for valid merchant and order id" do
      perform_login(merchants(:casper))
      order_id = orders(:dog_order)
      
      get merchant_order_path(id: order_id)
      
      must_respond_with :success
    end
  end
end
