class MerchantsController < ApplicationController
  before_action :require_login, except: [:index, :destroy, :create]
 

  def index
    @merchants = Merchant.all
  end

  def create
    auth_hash = request.env["omniauth.auth"]
    merchant = Merchant.find_by(uid: auth_hash[:uid], provider: "github")

    if merchant
      flash[:status] = :success
      flash[:result_text] = "Logged in as returning merchant #{merchant.username}."  
    else
      merchant = Merchant.build_from_github(auth_hash)
      if merchant.save
        flash[:status] = :success
        flash[:result_text] = "Logged in as new merchant #{merchant.username}." 
      else
        flash[:status] = :failure
        flash[:result_text] = "Could not create new merchant account"
        flash[:messages] = merchant.errors.messages
        return redirect_to root_path
      end 
    end

    session[:merchant_id] = merchant.id
    return redirect_to root_path
  end

  def current
    @current_merchant = Merchant.find_by(id: session[:merchant_id])
  end

  def destroy
    session[:merchant_id] = nil
    flash[:status] = :success
    flash[:result_text] = "Successfully logged out!"

    return redirect_to root_path
  end

  def merchant_orderitems
     @merchant_orderitems = Orderitem.joins(product: :merchant).where(merchants: {id: session[:merchant_id]})

     #.where("product.merchant_id==@current_merchant")

    # @orderitems = Orderitem.where(product_id: )

    #each product has a merchant so we care about the orderitem product_id
    # @orderitems.each do |orderitem|
    # product = Product.where(id: orderitem.product_id)
    # end

    # @current_merchant = Merchant.find_by(id: session[:merchant_id])

    # @current_merechant.products.each do |product|
    # if product.orderitems.shipped == false && orderitems.order.status == 'paid'
  


  end
end
