# Coverage is measured on every run unless COVERAGE=false. SimpleCov must be
# started before any application code is loaded.
unless ENV["COVERAGE"] == "false"
  require "simplecov"

  SimpleCov.start "rails" do
    enable_coverage :branch
    primary_coverage :line

    # Report on every file, including ones no spec happens to load.
    track_files "{app,lib}/**/*.{rb,rake}"

    add_filter %r{^/spec/}
    add_filter %r{^/config/}
    add_filter %r{^/db/}
    add_filter %r{^/vendor/}

    add_group "Admin", "app/admin"
    add_group "Policies", "app/policies"
    add_group "Services", "app/services"
    add_group "Tasks", "lib/tasks"

    # Running a single file shouldn't fail the build; the full suite must
    # cover every line.
    minimum_coverage line: 100 if ENV["COVERAGE_MINIMUM"] != "false" && ARGV.none? { |arg| arg.end_with?(".rb") || arg.include?(".rb:") }
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.disable_monkey_patching!
  config.default_formatter = "doc" if config.files_to_run.one?
  config.profile_examples = 5 if ENV["PROFILE"]
  config.order = :random
  Kernel.srand config.seed
end
