module Kookaburra
  class APIDriver
    include Plumbing
    include JSONTools

    # Pattern:
    # - Get some data from test_data.factory
    # - Post it to the API
    # - Remember the response in test_data
  end
end
