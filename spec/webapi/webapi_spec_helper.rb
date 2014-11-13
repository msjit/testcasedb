require "rails_helper"
require 'spec_helper.rb'

FactoryGirl.define do
  factory :user do
    username "User"
    password "password"
    password_confirmation "password"
    email "user@example.com"
    role 11
    single_access_token "kh3h93hfkhfl4hg8"
    active 1 
  end
  factory :user_2, :class => User do
    username "User 2"
    password "password 2"
    password_confirmation "password 2"
    email "user2@example.com"
    role 11
    single_access_token "kh3h93hfkhfl4hg8"
    active 1 
  end  
  factory :product do
    name "Product"
    description "test product"
  end
  factory :product_2, :class => Product do
    name "Product 2"
    description "test product 2"
  end  
  factory :version do
    version "1.0"
    description "test version"
    product_id 1
  end
  factory :version_2, :class => Version do
    version "2.0"
    description "test version 2"
    product_id 1
  end  
  factory :device do
    name "Device"
    description 'test device'
    active 1
  end
  factory :device_2, :class => Device do
    name "Device 2"
    description 'test device 2'
    active 1
  end  
  factory :category do
    name "Test Category"
    product_id 1
  end
  factory :sub_category, :class => Category do
    name "Sub Category"
    product_id 1
    category_id 1
  end  
  factory :tag do
    name "tag"
  end
  factory :tag_2, :class => Tag do
    name "tag 2"
  end  
  factory :test_type do
    name 'Automated'
    description 'For test cases run via automation.'
  end
  factory :test_type_2, :class => TestType do
    name 'Manual'
    description 'For test cases run manually.'
  end  
  factory :test_case do
    name "Test Case"
    description "test case"
    product_id 1
    category_id 1
    test_type_id 1
  end
  factory :test_case_2, :class => TestCase do
    name "Test Case 2"
    description "test case 2"
    product_id 1
    category_id 1
    test_type_id 1
  end
  factory :plan_case do
    test_case_id 1
    test_plan_id 1
    case_order 0
  end
  factory :plan_case_2, :class => PlanCase do
    test_case_id 2
    test_plan_id 1
    case_order 1
  end
  factory :plan_case_3, :class => PlanCase do
    test_case_id 1
    test_plan_id 2
    case_order 0
  end            
  factory :test_plan do
    name "Test Plan"
    description "test plan"
    product_id 1
  end
  factory :test_plan_2, :class => TestPlan do
    name "Test Plan 2"
    description "test plan 2"
    product_id 1
  end  
  factory :stencil do
    name "Test Stencil"
    description "test stencil"
    product_id 1
  end
  factory :stencil_test_plan do
    stencil_id 1
    test_plan_id 1
    device_id 1
    plan_order 0
  end
  factory :stencil_test_plan_2, :class => StencilTestPlan do
    stencil_id 1
    test_plan_id 2
    device_id 2
    plan_order 1
  end
  factory :test_plan_assignment, :class => Assignment do
    product_id 1
    version_id 1
    test_plan_id 1
  end
  factory :stencil_assignment, :class => Assignment do
    product_id 1
    version_id 1
    stencil_id 1
  end
  factory :result do
    assignment_id 11
    test_case_id 11
    result 'Passed'
    note 'result note'
    device_id 1
  end
  factory :result_2, :class => Result do
    assignment_id 12
    test_case_id 11
    result nil
    note 'result note'
    device_id 1
  end 
  factory :result_3, :class => Result do
    assignment_id 12
    test_case_id 12
    result nil
    note 'result note'
    device_id 1
  end               
end
