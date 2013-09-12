class Category < ActiveRecord::Base
  # We include url_helpers for this module as they are required
  # for creating the text for json in the categories controller
  include Rails.application.routes.url_helpers
  
  attr_accessible :name, :product_id, :category_id
  
  belongs_to :category
  belongs_to :product
  has_many :categories
  has_many :test_cases
  
  validates :name, :presence => true
  
  def generate_product
    category = self
    # A parent category is one that has a product_id
    # We keep finding parent categories until we find one with a 
    # product id
    # We return the product
    while !category.product_id
      category = Category.find(category.category_id)
    end

    return category.product
  end
end
