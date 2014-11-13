module StencilsHelper
  def device_list
    Device.order('name').collect {|d| [ d.name, d.id ]}
  end
  
  def test_plan_list(product_id)
    TestPlan.where(:product_id => product_id).order('name').collect {|c| [ c.name + ' - Version ' + c.version.to_s, c.id ]}
  end
  
  def link_to_add_test_plans(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    # new_object.test_plan = TestPlan.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    # fields += '<input id="test_case_steps_attributes_new_step_id" name="test_case[steps_attributes][new_step][id]" type="hidden"  />'.html_safe
    button_to_function(name, "add_test_plans(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => "btn btn-primary")
  end
  
  def link_to_remove_test_plans(name, f)
    f.hidden_field(:_destroy) + button_to_function(name, "remove_test_plans(this)", :class => "btn btn-danger btn-small")
  end
  
  # Take a stencil and figure out the id of the parent stencil
  def find_stencil_parent_id(stencil)
    # Figure out if this is the parent
    # If the stencil's parent_id is blank, its ID is the parent ID
    if stencil.parent_id.nil?
      parent_id = stencil.id
    # otherwise, the parent id is the one listed on the stencil
    else
      parent_id = stencil.parent_id
    end
  end  
end
