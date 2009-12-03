require 'application/main'

run lambda { |environment| $requestManager.handleRequest environment }
