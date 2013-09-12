module DevicesHelper
  def time_as_string(time_item, separator)
    # When no separator is required, it is because the value is being used to define a div
    # The calendar is split in to 30 minute intervals. This allows us to find the corresponding interval intervals
    if separator == ""
      "%d%02d" % [time_item.hour, time_item.min / 30 * 30]
    # For regular text we do not adjust the time
    else  
      "%d#{separator}%02d" % [time_item.hour, time_item.min]
    end
  end
end
