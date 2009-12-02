require 'application/main'

run lambda { |environment| $manager.handleRequest environment }
