class Orderitem < ApplicationRecord
  belongs_to :product
  belongs_to :order
  
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  
  validate :in_stock
  
  def subtotal
    return self.quantity * self.product.price
  end
  
  private
  
  def in_stock
    if quantity && product && quantity > product.stock
      errors.add(:quantity, "order exceeds inventory in stock")
    end
  end
end
