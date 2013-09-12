class ProductsController < ApplicationController
  # GET /products
  # GET /products.xml
  def index
    authorize! :read, Product
    # Admins can see all products.
    if current_user.role == 10
      @products = Product.order('name')
    else
      @products = current_user.products.order('name')
    end
    
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /products/1
  # GET /products/1.xml
  def show
    @product = Product.find(params[:id])
    authorize! :read, @product
    authorize_product!(@product)
    
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /products/new
  # GET /products/new.xml
  def new
    @product = Product.new
    authorize! :create, @product

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /products/1/edit
  def edit
    @product = Product.find(params[:id])
    authorize_product!(@product)
    
    authorize! :update, @product
  end

  # POST /products
  # POST /products.xml
  def create
    @product = Product.new(params[:product])
    authorize! :create, @product

    respond_to do |format|
      # Try and save the changes
      if @product.save
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:product_id => @product.id, :action => 1, :user_id => current_user.id)
        
        # If it is save and new
        if params[:commit] == "Save and Create Additional"
          format.html { redirect_to( new_product_path, :notice => 'Product was successfully created. Please create another.') }
         # If it is just save, show the new user
        else
          format.html { redirect_to(@product, :notice => 'Product was successfully created.') }
        end
      # If the save fails
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /products/1
  # PUT /products/1.xml
  def update
    @product = Product.find(params[:id])
    authorize! :update, @product
    authorize_product!(@product)
    
    respond_to do |format|
      if @product.update_attributes(params[:product])
        # Create item in log history
        # Action type based on value from en.yaml
        History.create(:product_id => @product.id, :action => 2, :user_id => current_user.id)
        
        format.html { redirect_to(@product, :notice => 'Product was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.xml
  def destroy
    @product = Product.find(params[:id])
    authorize! :destroy, @product
    authorize_product!(@product)
    
	  if ( Category.where(:product_id => @product.id).count > 0 )
	    redirect_to(products_url, :flash => {:warning => "Can not delete product. Product is in use"} )
	  elsif ( Product.count == 1 )
	    redirect_to(products_url, :flash => {:warning => "Not deleted. There must be at least one  product"} )
	  else
      @product.destroy
      # Create item in log history
      # Action type based on value from en.yaml
      History.create(:product_id => @product.id, :action => 3, :user_id => current_user.id)
      
      respond_to do |format|
	      format.html { redirect_to(products_url) }
	    end
	  end
	end
end
