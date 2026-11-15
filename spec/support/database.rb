# Examples run in transactions that are rolled back, but anything committed
# outside the suite (e.g. `RAILS_ENV=test bin/rails db:seed`, which bin/ci runs
# to check the seeds) would otherwise leak into specs that count or list
# records. Start every run from empty tables.
RSpec.configure do |config|
  config.before(:suite) do
    ActiveRecord::Tasks::DatabaseTasks.truncate_all
  end
end
