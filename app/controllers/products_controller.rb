class ProductsController < ApplicationController
  # before_action :require_login, except [:index]
  
  def index
    @products = Product.all
  end

  def show
  end 

  # only merchants
  def new
  end

  # only merchants
  def edit
  end 

  # only merchants
  def create
  end

  # only merchants
  def update
  end

  # only merchants
  def destroy
  end

  private

  # def require_login
  # end

end
