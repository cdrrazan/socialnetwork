# expect { ... }.to make_database_queries(count: 2)
# expect { ... }.not_to make_database_queries(matching: /taggings/)
RSpec::Matchers.define :make_database_queries do |count: nil, matching: nil|
  supports_block_expectations

  match do |block|
    @queries = []
    callback = lambda do |*, payload|
      next if payload[:name].in?(%w[SCHEMA CACHE]) || payload[:cached]

      @queries << payload[:sql] if matching.nil? || payload[:sql].match?(matching)
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)

    count ? @queries.size == count : @queries.any?
  end

  failure_message do
    "expected #{count || "some"} matching queries, got #{@queries.size}:\n#{@queries.join("\n")}"
  end

  failure_message_when_negated do
    "expected no matching queries, got #{@queries.size}:\n#{@queries.join("\n")}"
  end
end
