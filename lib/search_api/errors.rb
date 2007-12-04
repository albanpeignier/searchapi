# This modules provides a framework for encapsulating and performing searches.
#
# - SearchApi::Search module holds the abstract search features and behaviors.
# - SearchApi::Bridge module allows SearchApi::Search to apply to actual classes, and particularly to ActiveRecord::Base.
# - SearchApi::Integration makes ActiveRecord transparently use search features.

module SearchApi
  
  # Base for all SearchApi errors.
  class SearchApiError < StandardError; end
end
