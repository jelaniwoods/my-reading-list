require "rails_helper"

RSpec.describe ApplicationJob, type: :job do
  self.use_transactional_tests = false

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = original_adapter
  end

  it "enqueues only after the surrounding database transaction commits" do
    expect {
      ActiveRecord::Base.transaction do
        expect { described_class.perform_later }.not_to have_enqueued_job(described_class)
      end
    }.to have_enqueued_job(described_class).exactly(:once)
  end

  it "discards jobs when the surrounding database transaction rolls back" do
    expect {
      ActiveRecord::Base.transaction do
        described_class.perform_later
        raise ActiveRecord::Rollback
      end
    }.not_to have_enqueued_job(described_class)
  end
end
