module HistoriesHelper
  # Create a map of history actions 
  # Not for use with dropdowns. Items are placed in a list
  # None was added to fill the zero value of the array
  def history_actions(item_index)
    # The previous mapping wasn't always in order
    # I18n.t(:history_actions).map { |key, value| [ value ] } 
    # Retrieve translations and sort
    actions = I18n.t(:history_actions)
    actions[item_index]
  end
end
