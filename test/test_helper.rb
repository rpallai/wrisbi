require 'spork'

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  #`rake db:schema:dump && RAILS_ENV=test rake db:schema:load`
end

Spork.each_run do
  # This code will be run each time you run your specs.
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

	#self.use_transactional_fixtures = false
	#self.use_instantiated_fixtures = :no_instances

  # Add more helper methods to be used by all tests here...
end
