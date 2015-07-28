// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require jquery-ui
//= require jquery-fileupload/basic
//= require jquery-fileupload/vendor/tmpl
//= require best_in_place
//= require_tree .

jQuery(function($) {
  $('#nojs').hide();
  
  // Proved select all/deselect all behaviour for test case tree node
  $('input[name$="treenode_selectall"]').click( function()  {
    $('.treeNode').filter(':visible').find('input:checkbox').prop('checked', true);
    return false;
  });
  $('input[name$="treenode_deselectall"]').click( function()  {
    $('.treeNode').filter(':visible').find('input:checkbox').prop('checked', false);
    return false;
  });
  
  // Set tehe report date fields to use the jquery ui datepicker
  $("#report_start_date").datepicker({
    dateFormat: 'yy-mm-dd'
  });
  $("#report_end_date").datepicker({
    dateFormat: 'yy-mm-dd'
  });
  $("#task_due_date").datepicker({
    dateFormat: 'yy-mm-dd'
  });
  $("#task_completion_date").datepicker({
    dateFormat: 'yy-mm-dd'
  });
  $("#assignment_task_attributes_due_date").datepicker({
    dateFormat: 'yy-mm-dd'
  });
  $("#assignment_task_attributes_completion_date").datepicker({
    dateFormat: 'yy-mm-dd'
  });

  // on editing a report, change visible fields based on selected item
  $("#report_report_type").change(function() {
    set_report_visible( $(this) );
  });

  // This function is to set which items are visible on the reports form
  // It should be triggered by a change to the select and form load
  // This covers new forms and form edits
  function set_report_visible(select_item){
    if ( select_item.val() == "System Status" ) {
      $("#report_product_select").hide();
      $("#report_version_select").hide();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
    else if ( select_item.val() == "Release Current State" ) {
      $("#report_product_select").show();
      $("#report_version_select").show();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
    else if ( select_item.val() == "Release Current State - By User" ) {
      $("#report_product_select").show();
      $("#report_version_select").show();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
    else if ( select_item.val() == "Release Progress - Daily" ) {
      $("#report_product_select").show();
      $("#report_version_select").show();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").show();
      $("#report_end_date_select").show();
    }
    else if ( select_item.val() == "Compare Release Results" ) {
      $("#report_product_select").show();
      $("#report_version_select").hide();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
    else if ( select_item.val() == "Compare Release Results - Detailed" ) {
      $("#report_product_select").show();
      $("#report_version_select").show();
      $("#report_second_version_select").show();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
    else if ( select_item.val() == "Test Cases without Steps" ) {
      $("#report_product_select").show();
      $("#report_version_select").hide();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
    else if ( select_item.val() == "Open Tasks - User" ) {
      $("#report_product_select").hide();
      $("#report_version_select").hide();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
    else if ( select_item.val() == "Release Bug Report" ) {
      $("#report_product_select").show();
      $("#report_version_select").show();
      $("#report_second_version_select").hide();
      $("#report_start_date_select").hide();
      $("#report_end_date_select").hide();
    }
  }

  // For tree views. When link ajax is a success we hide the loading message 
  // Important this is not called for cached pages (304 not modified)
  $('#treeView').delegate('a', 'ajax:success', function() {  
    $("#ajaxAlert").hide();
  });
  // For tree views. When link ajax is a failure we hide the loading message 
  $('#treeView').delegate('a', 'ajax:error', function(xhr, status, error) {  
    $("#ajaxAlert").html(error);
  });
  // For tree views.
  $("#treeView").on("click", "a", function(){
    // Figure out current state
    var myClass = $(this).attr("class");
    if (myClass == "treeLink") {
      // Show the loading alert
      $("#ajaxAlert").toggle();

      $(this).removeClass('treeLink').addClass('expandedTreeLink');
      
      if ($(this).siblings('i').filter('.icon-chevron-right').length > 0) {
        $(this).siblings('.icon-chevron-right').removeClass('icon-chevron-right').addClass('icon-chevron-down');
      }

    }
    else if (myClass == "expandedTreeLink") {
      var thisID = $(this).parents('div:first').children('div').not('.icon-chevron-right').not('.icon-chevron-down').not('.treeForm').toggle();

      if ($(this).siblings('i').filter('.icon-chevron-right').length > 0) {
        $(this).siblings('.icon-chevron-right').removeClass('icon-chevron-right').addClass('icon-chevron-down');
      }
      else if ($(this).siblings('i').filter('.icon-chevron-down').length> 0) {
        $(this).siblings('.icon-chevron-down').removeClass('icon-chevron-down').addClass('icon-chevron-right');
      }
      return false;
    }               
  });
  
  $(document).ready(function() {
    $('.dropdown-toggle').dropdown();
    // If there is a report form set visible fields on load
    if ( $("#report_report_type").length ) {
      set_report_visible( $("#report_report_type") );
    };

    // For pages with tables with rowLink Items, set the rows to be clickable
    $('.rowLink').click( function(event) {
      var $target = $(event.target);
      if ( $target.is("a") )
      {
        return;
      }
      else
      {
        window.location = $(this).find('a').attr('href');
      }
    });
    
    $('#new_upload').fileupload({
      dataType: "script",
      add: function(e, data) {
        data.context = $(tmpl("template-upload", data.files[0]));
        $('#new_upload').append(data.context);
        return data.submit();
      },
      progress: function(e, data) {
        var progress;
        if (data.context) {
          progress = parseInt(data.loaded / data.total * 100, 10);
          return data.context.find('.bar').css('width', progress + '%');
        }
      },
      done: function(e, data) {
        return data.context.remove();
      }
    });
    jQuery(".best_in_place").best_in_place();
    
    online_help();

  });
  
  // Inactive field is used by comment fields that have not yes been clicked.
  $(".inactiveTextField").bind("focus", function(){ 
    $(this).attr('rows', '4'); 
    $(this).removeClass('inactiveTextField');
    if ($(this).val() == 'Enter a new comment') {
      $(this).val('');
    }
    $('.hiddenActions').addClass('actions').removeClass('hiddenActions');
  });  

	$( "#steps" ).sortable({
		items: '.step',
		handle: '.stepHandle',
		update: function() {
      step_number=0;
      $('.step').filter(':visible').each(function(i,value ){
        step_number=step_number + 1;
        $(value).children('.step_number').val(step_number);
      });
		}
  });
  
  $( "#stencil_plans" ).sortable({
		items: 'tr.selectedPlan',
		handle: '.planHandle',
		update: function() {
      plan_number=0;
      $('.selectedPlan').filter(':visible').each(function(i,value ){
        plan_number=plan_number + 1;
        $(value).find('.plan_order').val(plan_number);
      });
		}
  });

  $('#test_case_tag_ids').chosen();
  $('#product_user_ids').chosen();
  $('#user_product_ids').chosen();
  
  // Show ajax alert for attachment uploads
  $('#upload_submit').bind('click', function() {
    $('#ajaxAlert').html('Uploading...').show();
  });
  
  // Show test case targets if jmeter is selected
  if ($('#test_case_test_type_id option:selected').text() == 'jMeter') {
    $('#targetHeader').show();
    $('#targetModule').show();
  }
  // Change case targets base on testt type changes
  $('#test_case_test_type_id').change(function() {
    if ($('#test_case_test_type_id option:selected').text() == 'jMeter') {
      $('#targetHeader').show();
      $('#targetModule').show();
    }
    else {
      $('#targetHeader').hide();
      $('#targetModule').hide();
    }
  });
  $('#result-toggle').children().click(function() {
    $(this).parent().children().removeClass('active');
    $(this).addClass('active');
  });
  
})

jQuery(function() {
  $("a[rel=popover]").popover();
  $(".tooltip").tooltip();
  $("a[rel=tooltip]").tooltip();
});

function remove_steps(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".step").hide();
  step_number=0;
  $('.step').filter(':visible').each(function(i,value ){
    step_number=step_number + 1;
    $(value).children('.step_number').val(step_number);
  });
}

function add_steps(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  var highStep=0;
  $(".step_number").each(function(i,inputItem ){
    if(parseInt(inputItem.value)>highStep){
      highStep=parseInt(inputItem.value);
    }
  });
  $(link).before(content.replace(regexp, new_id));
  $('[name="test_case[steps_attributes][' + new_id + '][step_number]"]').val(highStep+1);
  $('[name="test_case[steps_attributes][' + new_id + '][action]"]').focus();
}

function remove_test_plans(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".selectedPlan").hide();
  plan_number=0;
  $('.selectedPlan').filter(':visible').each(function(i,value ){
    plan_number=plan_number + 1;
    $(value).children('plan_order').val(plan_number);
  });
}
function add_test_plans(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g")
  var highStep=0;
  $(".plan_number").each(function(i,inputItem ){
    if(inputItem.value>highStep){
      highStep=inputItem.value;
    }
  });
  //$(link).before(content.replace(regexp, new_id));
  $('.matrix').append(content.replace(regexp, new_id));
  $('[name="stencil[stencil_test_plans_attributes][' + new_id + '][plan_order]"]').val(parseInt(highStep)+1);
  $('[name="stencil[stencil_test_plans_attributes][' + new_id + '][test_plan]"]').focus();
  // Make the product selector active
}

function remove_test_case_targets(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest("tr").hide();
}

function reset_row_classes() {
  $('.sortable_table').find('tr').not('.sortableHeader').each( function(index) {
    $(this).removeClass('odd');
    $(this).removeClass('even');
    if (index % 2 == 1) {
      $(this).addClass('even');
    }
    else {
      $(this).addClass('odd');
    }
  });
}

function online_help() {
  var currentHelpUrl = currentHelpUrl || "";
  
  $('a#help-link').click(function(event){
      if (!$('#help-modal').is(":visible")) {
        console.log(currentHelpUrl);
        console.log( window.location.pathname);
        if (currentHelpUrl !=  window.location.pathname) {
          $.ajax({
            url: "/help",
            context: document.body,
            data: {
              page_path: window.location.pathname
            }
          }).success(function( data ) {
            $("#help-content").html( data );
          });
          currentHelpUrl =  window.location.pathname;
        }
      }
      event.preventDefault();
      $('#help-modal').toggle( "slide", {direction:'right'}, 1000 );
  });
}