class Order < ApplicationRecord
  has_many :orderitems
  has_many :products, through: :orderitems
  
  validates :status, presence: true, inclusion: { 
    in: %w(pending paid complete cancel),
    message: "%{value} is not a valid status" 
  }
  
  validates :orderitems, length: { minimum: 1, message: "There are no items in your cart!" }, on: :update
  validates :email, presence: true, on: :update
  validates :address, presence: true, on: :update
  validates :cc_name, presence: true, on: :update
  validates :cc_num, presence: true, numericality: { only_integer: true }, length: { minimum: 4 }, on: :update
  validates :cvv, presence: true, numericality: { only_integer: true }, on: :update
  validates :cc_exp, presence: true, on: :update
  validates :zip, presence: true, numericality: { only_integer: true }, on: :update
  
  def reduce_stock
    self.orderitems.each do |orderitem|
      orderitem.product.stock -= orderitem.quantity
      orderitem.product.save
    end
  end
  
  def return_stock
    self.orderitems.each do |orderitem|
      if !orderitem.product.retired
        orderitem.product.stock += orderitem.quantity
        orderitem.product.save
      end
    end
  end
  
  def total
    total_cost = 0
    
    self.orderitems.each do |orderitem|
      total_cost += orderitem.subtotal
    end
    
    return total_cost
  end
  
  def mark_as_complete?
    if self.status == "paid" && self.orderitems.find_by(shipped: false).nil?
      self.status = "complete"
      self.save
    end
  end
  
  def is_order_of(merch_id)
    if self.products.find_by(merchant_id: merch_id).nil?
      return false
    end
    
    return true
  end
end
