class ApplicationJob < ActiveJob::Base
  # MySQL resolves concurrent writes to the same rows by killing one
  # transaction with a deadlock error; retrying it almost always succeeds.
  retry_on ActiveRecord::Deadlocked, wait: :polynomially_longer, attempts: 5

  # A job whose record was deleted before it ran has nothing left to do.
  discard_on ActiveJob::DeserializationError
end
