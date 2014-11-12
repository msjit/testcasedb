module TestCasesHelper
  # Used to delete fields on accepts_nested_Attributes (ex. test case steps)
  # function courtesy of railcasts #197
  def link_to_remove_steps(name, f)
    f.hidden_field(:_destroy) + button_to_function(name, "remove_steps(this)", :class => "btn btn-danger btn-small")
  end
  
  def link_to_add_steps(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    # fields += '<input id="test_case_steps_attributes_new_step_id" name="test_case[steps_attributes][new_step][id]" type="hidden"  />'.html_safe
    button_to_function(name, "add_steps(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => "btn btn-success")
  end
  
  def link_to_remove_test_case_targets(name, f)
    f.hidden_field(:_destroy) + button_to_function(name, "remove_test_case_targets(this)",  :class => "btn btn-danger btn-small")
  end
  
  def link_to_add_test_case_targets(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    # fields += '<input id="test_case_steps_attributes_new_step_id" name="test_case[steps_attributes][new_step][id]" type="hidden"  />'.html_safe
    button_to_function(name, "add_test_case_targets(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => "btn")
  end
  
  def list_of_test_case_tags(tags)
    tag_array = []
    tags.each do |tag|
      tag_array << tag.name
    end
    
    tag_array.sort.join(', ')
  end

  def content_types_list 
    I18n.t(:content_types).map { |key, value| [ value, key ] } 
  end
  
  def test_type_list
    TestType.find(:all).collect {|d| [ d.name, d.id ]}
  end
  
  # Takes a test case and figures out if it is the parent
  # Return value is the parent id
  def find_test_case_parent_id(test_case)
    # Figure out if this is the parent
    # If the test cases's parent_id is blank, its ID is the parent ID
    if test_case.parent_id.nil?
      parent_id = test_case.id
    # otherwise, the parent id is the one listed on the test case
    else
      parent_id = test_case.parent_id
    end
  end
end
