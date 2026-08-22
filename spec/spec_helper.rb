# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/spec/"
  enable_coverage :branch
  # The one uncovered branch is the `unless defined?` require guard in
  # lib/guard/kitchen.rb, whose already-loaded path cannot run in a single
  # process. Everything else is exercised.
  minimum_coverage line: 100, branch: 80
end

# Load the real Guard first: guard-compat substitutes stub Guard::UI and
# Guard::Notifier modules when Guard is absent, which collide with the real
# ones. We want the real APIs so verifying doubles can check them.
require "guard/kitchen"

# Replaces the hand-rolled monkey patch this suite used to carry: guard-compat
# stubs Guard::Plugin so a plugin can be instantiated without booting Guard.
require "guard/compat/test/helper"

Dir[File.expand_path("support/**/*.rb", __dir__)].sort.each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    # Fail if we stub a method the real object does not implement.
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = ".rspec_status"
  config.warnings = false

  config.order = :random
  Kernel.srand config.seed

  config.include KitchenCommandHelper
end
