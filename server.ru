require 'application/main'

run lambda { |environment| $mainSite.requestManager.handleRequest environment }
