# frozen_string_literal: true

# Example Rails Controller
#
# Place this in app/controllers/examples_controller.rb

class ExamplesController < ApplicationController
  def index
    # Sample data for the examples
    @products = [
      OpenStruct.new(id: 1, name: 'Product 1', price: 29.99, image_path: '/products/1.jpg'),
      OpenStruct.new(id: 2, name: 'Product 2', price: 39.99, image_path: '/products/2.jpg'),
      OpenStruct.new(id: 3, name: 'Product 3', price: 49.99, image_path: '/products/3.jpg')
    ]

    @current_user = OpenStruct.new(
      name: 'John Doe',
      avatar_path: '/avatars/john-doe.jpg'
    )
  end

  def gallery
    @photos = Photo.all
  end

  def product
    @product = Product.find(params[:id])
  end
end
