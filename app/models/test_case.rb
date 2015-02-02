class TestCase < ActiveRecord::Base
  attr_accessible :name, :description, :test_type_id, :category_id, :product_id, :status, :custom_items_attributes, :steps_attributes, :test_case_targets_attributes, :created_by_id, :tag_ids
  
  # Versioned test cases always belong to a parent test case.
  # We track the original parent in the parent_id field
  belongs_to :parent_case, :class_name => "TestCase", :foreign_key => "parent_id" 
  
	belongs_to :test_type
	belongs_to :category
	belongs_to :product
	belongs_to :created_by, :class_name => "User", :foreign_key => "created_by_id"
	belongs_to :modified_by, :class_name => "User", :foreign_key => "modified_by_id"
	has_many :steps, :dependent => :destroy, :order => "step_number"
	has_many :comments, :dependent => :destroy
	has_many :plan_cases
	has_many :test_plans, :through => :plan_cases
	has_many :results, :dependent => :destroy
	has_many :test_results, :through => :result_cases
	has_many :uploads, :as => :uploadable, :dependent => :destroy
	has_many :custom_items, :dependent => :destroy
	has_many :custom_fields, :through => :custom_items
	has_many :tag_test_cases, :dependent => :destroy
	has_many :tags, :through => :tag_test_cases
	has_many :test_case_targets, :dependent => :destroy
	
	validates :name, :presence => true
	validates :product_id, :presence => true
	validates :category_id, :presence => true
	
	accepts_nested_attributes_for :custom_items
	accepts_nested_attributes_for :steps, :allow_destroy => true, :reject_if => lambda { |a| a[:action].blank? }
	accepts_nested_attributes_for :test_case_targets, :allow_destroy => true, :reject_if => lambda { |a| a[:filename].blank? }
	
	def self.search(search)
    if search
      # find(:all, :conditions => ['name LIKE ?', "%#{search}%"])
      where(:product_id => current_user.products).where('name LIKE ?', "%#{search}%")
    else
      find(:all)
    end
  end
  
  def duplicate_case
    # clone the test case
    test_case = self.dup
    # Remember to increate the version value
    test_case.name = test_case.name + " COPY"
    test_case.version = 1
    test_case.parent_id = nil
    test_case.save
    
    # Make a clone of each step for this test case
    self.steps.each do |step|
      new_step = step.dup
      new_step.test_case_id = test_case.id
      new_step.save
    end
    
    test_case
  end
end
