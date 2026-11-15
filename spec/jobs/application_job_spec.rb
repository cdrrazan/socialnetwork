require "rails_helper"

RSpec.describe ApplicationJob do
  let(:job_class) do
    Class.new(described_class) do
      def self.name = "ExampleJob"

      def perform(outcome = "success")
        case outcome
        when "deadlock"
          raise ActiveRecord::Deadlocked, "Deadlock found when trying to get lock"
        when "deleted_record"
          # ActiveJob raises this while handling the lookup error for a
          # record that was deleted before the job ran.
          begin
            raise ActiveRecord::RecordNotFound
          rescue ActiveRecord::RecordNotFound
            raise ActiveJob::DeserializationError
          end
        end
      end
    end
  end

  it "re-enqueues itself after a MySQL deadlock" do
    expect { job_class.perform_now("deadlock") }.to have_enqueued_job(job_class).with("deadlock")
  end

  it "discards jobs whose records were deleted" do
    expect { job_class.perform_now("deleted_record") }.not_to have_enqueued_job
  end

  it "runs normally otherwise" do
    expect { job_class.perform_now }.not_to raise_error
  end
end
