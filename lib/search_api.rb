require 'search_api/errors'
require 'search_api/search'
require 'search_api/callbacks'
require 'search_api/bridge'
require 'search_api/sql_fragment'
require 'search_api/text_criterion'
require 'search_api/active_record_bridge'
require 'search_api/active_record_integration'


class SearchApi::Search::Base
  include SearchApi::Search::Callbacks
end
