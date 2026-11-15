# Run using bin/ci. Needs a running MySQL server (see config/database.yml)
# and Chrome or Chromium for the system specs (set BROWSER_PATH if it isn't on
# your PATH).

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # Model, policy, service, request, admin and browser specs. Fails if line or
  # branch coverage drops below 100%.
  step "Tests: RSpec", "bin/rspec"
  step "Tests: Seeds", "env RAILS_ENV=test bin/rails db:seed:replant"
  step "Data: Audit seeded data", "env RAILS_ENV=test bin/rails data:audit"
  step "Data: Rehearse upgrading a 2017 database", "script/rehearse_upgrade"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
