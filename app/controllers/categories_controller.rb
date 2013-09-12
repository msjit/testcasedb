class CategoriesController < ApplicationController
  # GET /categories
  # GET /categories.xml
  def index
    authorize! :read, Category
    # Uses the tree view. for initial load we only provide the list of products
    #@categories = Category.all
    
    @products = current_user.products.order('name')
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new_product
    authorize! :create, Category
    @product = Product.find(params[:product_id])
    @category = Category.new

    # Verify user can view this test case. Must be in his product
    authorize_product!(@product)
    
    respond_to do |format|
      format.js # new.js.erb
    end
  end
  
  def new_category
    authorize! :create, Category
    @category = Category.new
    @parentCategory = Category.find(params[:category_id])
    
    # Verify user can view this category by finding parent product. Must be in his product
    authorize_product!(@parentCategory.generate_product)
    
    respond_to do |format|
      format.js # new.html.erb
    end
  end

  # GET /categories/1/edit
  def edit
    authorize! :update, Category
    @category = Category.find(params[:id])
    
    # Verify user can view this category by finding parent product. Must be in his product
    authorize_product!(@category.generate_product)
    
    respond_to do |format|
      format.js # new.html.erb
    end
  end

  # POST /categories
  # POST /categories.xml
  def create
    authorize! :create, Category
    @category = Category.new(params[:category])
    if @category.product_id
      @product = Product.find(@category.product_id)
    end
    
    # Verify user can view this category by finding parent product. Must be in his product
    authorize_product!(@category.generate_product)
    
    respond_to do |format|
      if @category.save
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:category_id => @category.id, :action => 1, :user_id => current_user.id)
        
        format.html { redirect_to(@category, :notice => 'Category was successfully created.') }
        format.js
      else
        @errors = true
        format.html { render :action => "new" }
        format.js  { render :action => "new_product", params[:product_id] => params[:product_id] }
      end
    end
  end

  # PUT /categories/1
  # PUT /categories/1.xml
  def update
    authorize! :update, Category
    @category = Category.find(params[:id])

    # Verify user can view this category by finding parent product. Must be in his product
    authorize_product!(@category.generate_product)
    
    respond_to do |format|
      if @category.update_attributes(params[:category])
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:category_id => @category.id, :action => 2, :user_id => current_user.id)
        
        format.js
      else
        format.js
      end
    end
  end

  # DELETE /categories/1
  # DELETE /categories/1.xml
  def destroy
    authorize! :destroy, Category

    @category = Category.find(params[:id])
    
    # Verify user can view this category by finding parent product. Must be in his product
    authorize_product!(@category.generate_product)
    
    if ( Category.where(:category_id => @category.id).count > 0 )
      @error_message = "Can not delete. This category contains sub-categories."
	    render :partial => "can_not_delete"
	  elsif ( TestCase.where(:category_id => @category.id).count > 0 )
	    @error_message = "Can not delete. This category contains contains test cases."
	    render :partial => "can_not_delete"
    else
      @category_id = @category.id
      @category.destroy

      respond_to do |format|
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:category_id => @category.id, :action => 3, :user_id => current_user.id)
        format.js
      end
    end
  end
  
  # GET /categories/list/:product_id
  def list
    authorize! :read, Category
    # This function takes a product ID and returns a list of categories
    # either JS or HTML is returned.
    @categories = Category.find_all_by_product_id(params[:product_id], :order => "name")
    
    # It seems unneccessary to get the product as it is related to the categories
    # however, if there are no categories, we still need to know which product we're deling with 
    # so we retrieve the product for the display
    @product = Product.find(params[:product_id])
    
    # Verify user can view this category by finding parent product. Must be in his product
    authorize_product!(@product)
    
    respond_to do |format|
      format.js
    end
  end

  # GET /categories/list_children/:category_id
  def list_children
    authorize! :read, Category
    # This function takes a category ID and returns a list of sub-categories and test cases
    # either JS
    # Pass @category_id to the js view so it knows which div to add code to
    @category_id = params[:category_id]
    
    # Find all of the sub categories for this sub-category
    @categories = Category.find(@category_id).categories(:order => "name")
    
    # Verify user can view this category by finding parent product. Must be in his product
    authorize_product!(Category.find(@category_id).generate_product)
    
    respond_to do |format|
      format.js
    end
  end

end
