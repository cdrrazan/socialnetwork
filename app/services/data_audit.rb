# Looks for rows that break the app's data rules: missing required values,
# references to rows that no longer exist, duplicate or invalid usernames,
# self-follows, and counter caches that have drifted.
#
# It works both before and after the 2026 schema upgrade (checks for columns
# that don't exist yet are skipped), so it can be run against an old 2017
# database to see what needs cleaning up before migrating.
#
#   audit = DataAudit.new
#   audit.problems     # => [#<DataAudit::Problem ...>, ...]
#   audit.clean?       # => false
#   puts audit.report
#
# Run it from the command line with `bin/rails data:audit`.
class DataAudit
  Problem = Data.define(:check, :description, :count, :sample_ids) do
    def to_s
      ids = sample_ids.any? ? " (e.g. ids #{sample_ids.join(", ")})" : ""
      "#{description}: #{count}#{ids}"
    end
  end

  SAMPLE_SIZE = 5

  REQUIRED_COLUMNS = {
    "posts" => %w[title body user_id],
    "comments" => %w[body user_id post_id],
    "questions" => %w[title body user_id],
    "answers" => %w[body user_id question_id],
    "friendships" => %w[user_id friend_id],
    "conversations" => %w[author_id receiver_id],
    "personal_messages" => %w[body conversation_id user_id]
  }.freeze

  # table => { column => referenced table }
  REFERENCES = {
    "posts" => { "user_id" => "users" },
    "comments" => { "user_id" => "users", "post_id" => "posts" },
    "questions" => { "user_id" => "users" },
    "answers" => { "user_id" => "users", "question_id" => "questions" },
    "friendships" => { "user_id" => "users", "friend_id" => "users" },
    "conversations" => { "author_id" => "users", "receiver_id" => "users" },
    "personal_messages" => { "user_id" => "users", "conversation_id" => "conversations" }
  }.freeze

  COUNTER_CACHES = [
    { table: "posts", column: "comments_count", child_table: "comments", foreign_key: "post_id" },
    { table: "questions", column: "answers_count", child_table: "answers", foreign_key: "question_id" }
  ].freeze

  def initialize(connection: ActiveRecord::Base.connection)
    @connection = connection
  end

  def problems
    @problems ||= [
      *missing_required_values,
      *orphaned_rows,
      *username_problems,
      *self_references,
      *duplicate_friendships,
      *invalid_post_states,
      *counter_cache_drift
    ]
  end

  def clean?
    problems.empty?
  end

  def report
    return "No problems found." if clean?

    lines = problems.map { |problem| "- #{problem}" }
    "Found #{problems.size} problem(s):\n#{lines.join("\n")}"
  end

  # Recalculates the comment, answer and vote counter caches from the rows
  # themselves. Returns the number of rows updated.
  def self.reset_counters!
    updated = 0
    Post.find_each do |post|
      Post.reset_counters(post.id, :comments)
      post.update_cached_votes
      updated += 1
    end
    Question.find_each do |question|
      Question.reset_counters(question.id, :answers)
      updated += 1
    end
    updated
  end

  private

  attr_reader :connection

  def missing_required_values
    REQUIRED_COLUMNS.flat_map do |table, columns|
      columns.filter_map do |column|
        next unless column?(table, column)

        problem_from(:missing_value, "#{table}.#{column} is empty",
                     table, "#{quote(column)} IS NULL")
      end
    end
  end

  def orphaned_rows
    REFERENCES.flat_map do |table, references|
      references.filter_map do |column, parent|
        next unless column?(table, column)

        condition = "#{quote(column)} IS NOT NULL AND #{quote(column)} NOT IN (SELECT id FROM #{quote_table(parent)})"
        problem_from(:orphan, "#{table}.#{column} points to a missing #{parent.singularize}", table, condition)
      end
    end
  end

  def username_problems
    return [] unless column?("users", "username")

    [
      problem_from(:missing_username, "users without a username", "users",
                   "username IS NULL OR username = ''"),
      problem_from(:invalid_username, "usernames with characters other than letters, numbers, _ . -", "users",
                   "username IS NOT NULL AND username <> '' AND username NOT REGEXP '^[A-Za-z0-9_.-]+$'"),
      duplicate_usernames
    ].compact
  end

  def duplicate_usernames
    names = connection.select_values(<<~SQL.squish)
      SELECT LOWER(username) FROM users
      WHERE username IS NOT NULL AND username <> ''
      GROUP BY LOWER(username) HAVING COUNT(*) > 1
    SQL
    return if names.empty?

    list = names.map { |name| connection.quote(name) }.join(", ")
    problem_from(:duplicate_username, "accounts sharing a username (case-insensitive)", "users",
                 "LOWER(username) IN (#{list})")
  end

  def self_references
    [
      (problem_from(:self_follow, "users following themselves", "friendships", "user_id = friend_id") if column?("friendships", "user_id", "friend_id")),
      (problem_from(:self_conversation, "conversations with yourself", "conversations", "author_id = receiver_id") if column?("conversations", "author_id", "receiver_id"))
    ].compact
  end

  def duplicate_friendships
    return [] unless column?("friendships", "user_id", "friend_id")

    count = connection.select_value(<<~SQL.squish).to_i
      SELECT COALESCE(SUM(c - 1), 0) FROM (
        SELECT COUNT(*) AS c FROM friendships GROUP BY user_id, friend_id HAVING COUNT(*) > 1
      ) duplicates
    SQL
    return [] if count.zero?

    [ Problem.new(check: :duplicate_friendship, description: "duplicate follows", count: count, sample_ids: []) ]
  end

  def invalid_post_states
    return [] unless column?("posts", "state")

    [ problem_from(:invalid_state, "posts with an unknown state", "posts",
                   "state IS NOT NULL AND state NOT IN ('published', 'unpublished')") ].compact
  end

  def counter_cache_drift
    COUNTER_CACHES.filter_map do |cache|
      next unless column?(cache[:table], cache[:column])

      condition = <<~SQL.squish
        #{quote(cache[:column])} <> (
          SELECT COUNT(*) FROM #{quote_table(cache[:child_table])} children
          WHERE children.#{quote(cache[:foreign_key])} = #{quote_table(cache[:table])}.id
        )
      SQL
      problem_from(:counter_drift,
                   "#{cache[:table]}.#{cache[:column]} out of date (fix with bin/rails data:reset_counters)",
                   cache[:table], condition)
    end
  end

  def problem_from(check, description, table, condition)
    return unless connection.table_exists?(table)

    count = connection.select_value("SELECT COUNT(*) FROM #{quote_table(table)} WHERE #{condition}").to_i
    return if count.zero?

    ids = connection.select_values(
      "SELECT id FROM #{quote_table(table)} WHERE #{condition} ORDER BY id LIMIT #{SAMPLE_SIZE}"
    )
    Problem.new(check: check, description: description, count: count, sample_ids: ids)
  end

  def column?(table, *columns)
    connection.table_exists?(table) && columns.all? { |column| connection.column_exists?(table, column) }
  end

  def quote(column)
    connection.quote_column_name(column)
  end

  def quote_table(table)
    connection.quote_table_name(table)
  end
end
