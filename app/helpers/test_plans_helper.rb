module TestPlansHelper
  # Takes a test plan and figures out if it is the parent
  # Return value is the parent id
  def find_test_plan_parent_id(test_plan)
    # Figure out if this is the parent
    # If the test plan's parent_id is blank, its ID is the parent ID
    if test_plan.parent_id.nil?
      parent_id = test_plan.id
    # otherwise, the parent id is the one listed on the test case
    else
      parent_id = test_plan.parent_id
    end
  end  
end
