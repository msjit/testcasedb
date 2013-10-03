jQuery ->
  # Activate selected result
  $("button[data-result=" + $('#result_result').val() + "]").addClass('active')

  # Set result value
  $("#result-toggle button").click -> 
    $('#result_result').val($(this).data('result'))