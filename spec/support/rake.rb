require "rake"

# Loads the app's rake tasks once and re-enables a task before each run, so
# specs can invoke the same task more than once.
module RakeHelpers
  def run_task(name, *args)
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    task = Rake::Task[name]
    task.reenable
    task.invoke(*args)
  end
end

RSpec.configure do |config|
  config.include RakeHelpers, type: :task
  config.define_derived_metadata(file_path: %r{/spec/tasks/}) { |metadata| metadata[:type] = :task }
end
