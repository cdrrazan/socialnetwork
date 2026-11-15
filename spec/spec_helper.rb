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

    # The full suite (`bin/rspec` with no arguments, or CI) must cover every
    # line and branch. Running a subset only reports, so it never "fails" for
    # missing coverage.
    if ARGV.empty? || ENV["COVERAGE_MINIMUM"] == "true"
      minimum_coverage line: 100, branch: 100
    end
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
