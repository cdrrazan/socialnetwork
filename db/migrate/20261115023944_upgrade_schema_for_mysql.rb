# Brings the 2017-era schema up to modern Rails/MySQL conventions.
#
# 1. 64-bit keys: every primary key and every column that references one
#    (including polymorphic *_id columns) becomes BIGINT, the Rails default
#    since 5.1. Foreign keys are dropped first and re-created afterwards,
#    because MySQL won't change the type of a column a constraint uses.
# 2. NOT NULL on columns the models already require, so the database
#    enforces the same rules as the validations.
# 3. Microsecond timestamps (DATETIME(6)), the Rails default since 7.0.
# 4. utf8mb4_bin for tag names, so tags are compared case-sensitively and
#    emoji work (the original migration used the 3-byte utf8mb3_bin).
# 5. Counter caches for comments, answers and votes, back-filled from the
#    existing rows, so list pages don't need a COUNT query per row.
# 6. CHECK constraints for post states and self-follows/self-conversations.
# 7. Indexes for the queries the app actually runs.
# 8. Removes posts.slug, left over from friendly_id and never populated.
#
# The migration refuses to run if existing rows would violate the new NOT NULL
# constraints. Run `bin/rails data:audit` to see which rows need fixing.
class UpgradeSchemaForMysql < ActiveRecord::Migration[8.1]
  # Tables owned by the app or by gems whose ids are still 32-bit.
  TABLES = %w[
    users admin_users posts comments questions answers friendships
    conversations personal_messages votes tags taggings activities
    active_admin_comments
  ].freeze

  # Columns holding the id of another row.
  REFERENCE_COLUMNS = {
    "posts" => %w[user_id],
    "comments" => %w[user_id post_id],
    "questions" => %w[user_id],
    "answers" => %w[user_id question_id],
    "friendships" => %w[user_id friend_id],
    "conversations" => %w[author_id receiver_id],
    "personal_messages" => %w[conversation_id user_id],
    "votes" => %w[votable_id voter_id],
    "taggings" => %w[tag_id taggable_id tagger_id],
    "activities" => %w[trackable_id owner_id recipient_id],
    "active_admin_comments" => %w[resource_id author_id]
  }.freeze

  # Columns the models validate as present.
  REQUIRED_COLUMNS = {
    "posts" => %w[title body user_id],
    "comments" => %w[body user_id post_id],
    "questions" => %w[title body user_id],
    "answers" => %w[body user_id question_id],
    "friendships" => %w[user_id friend_id],
    "conversations" => %w[author_id receiver_id],
    "personal_messages" => %w[body conversation_id user_id]
  }.freeze

  TIMESTAMPED_TABLES = %w[
    users admin_users posts comments questions answers friendships
    conversations personal_messages votes activities active_admin_comments
  ].freeze

  def up
    ensure_required_columns_are_filled!

    foreign_keys = TABLES.flat_map { |table| foreign_keys(table) }
    foreign_keys.each { |fk| remove_foreign_key fk.from_table, name: fk.name }

    TABLES.each { |table| widen_keys(table) }
    REQUIRED_COLUMNS.each { |table, columns| require_columns(table, columns) }
    TIMESTAMPED_TABLES.each { |table| use_microsecond_timestamps(table) }

    foreign_keys.each do |fk|
      add_foreign_key fk.from_table, fk.to_table, column: fk.column, primary_key: fk.primary_key, name: fk.name
    end

    change_table :users, bulk: true do |t|
      t.change :admin, :boolean, default: false, null: false
    end

    change_table :tags, bulk: true do |t|
      t.change :name, :string, collation: "utf8mb4_bin", null: false
      t.change :taggings_count, :integer, default: 0, null: false
    end

    add_counter_caches
    add_check_constraints
    add_query_indexes

    remove_index :posts, :slug
    remove_column :posts, :slug, :string
  end

  def down
    add_column :posts, :slug, :string
    add_index :posts, :slug, unique: true

    remove_index :activities, name: "index_activities_on_owner_and_created_at"
    remove_index :questions, :created_at
    remove_index :posts, %i[state created_at]

    remove_check_constraint :conversations, name: "conversations_distinct_participants"
    remove_check_constraint :friendships, name: "friendships_no_self_follow"
    remove_check_constraint :posts, name: "posts_valid_state"

    remove_column :questions, :answers_count
    change_table :posts, bulk: true do |t|
      t.remove :comments_count, :cached_votes_total, :cached_votes_score, :cached_votes_up, :cached_votes_down
    end

    change_table :tags, bulk: true do |t|
      t.change :name, :string, collation: "utf8mb3_bin", null: true
      t.change :taggings_count, :integer, default: 0, null: true
    end

    change_table :users, bulk: true do |t|
      t.change :admin, :boolean, default: false, null: true
    end

    REQUIRED_COLUMNS.each do |table, columns|
      columns.each { |column| change_column_null table, column, true }
    end

    # 64-bit keys and microsecond timestamps are left in place: they hold
    # every value the old types could, so there's nothing to undo.
  end

  private

  def ensure_required_columns_are_filled!
    problems = REQUIRED_COLUMNS.flat_map do |table, columns|
      columns.filter_map do |column|
        count = select_value("SELECT COUNT(*) FROM #{quote_table_name(table)} WHERE #{quote_column_name(column)} IS NULL").to_i
        "#{table}.#{column}: #{count} row(s) are NULL" if count.positive?
      end
    end
    return if problems.empty?

    raise ActiveRecord::MigrationError, <<~MESSAGE
      Some rows are missing required values and would break the new NOT NULL constraints:

        #{problems.join("\n  ")}

      Run `bin/rails data:audit` for details, fix or delete those rows, then migrate again.
    MESSAGE
  end

  def widen_keys(table)
    columns = columns(table).index_by(&:name)

    change_table table, bulk: true do |t|
      if columns["id"]&.sql_type&.start_with?("int")
        t.change :id, :bigint, null: false, auto_increment: true
      end

      Array(REFERENCE_COLUMNS[table]).each do |name|
        column = columns.fetch(name)
        t.change name, :bigint, null: column.null if column.sql_type.start_with?("int")
      end
    end
  end

  def require_columns(table, names)
    columns = columns(table).index_by(&:name)

    change_table table, bulk: true do |t|
      names.each do |name|
        column = columns.fetch(name)
        t.change name, column.type, limit: column.limit, null: false
      end
    end
  end

  def use_microsecond_timestamps(table)
    columns = columns(table).index_by(&:name)

    change_table table, bulk: true do |t|
      %w[created_at updated_at].each do |name|
        column = columns[name]
        next unless column && column.precision != 6

        t.change name, :datetime, precision: 6, null: column.null
      end
    end
  end

  def add_counter_caches
    change_table :posts, bulk: true do |t|
      t.integer :comments_count, default: 0, null: false
      # Maintained automatically by acts_as_votable.
      t.integer :cached_votes_total, default: 0, null: false
      t.integer :cached_votes_score, default: 0, null: false
      t.integer :cached_votes_up, default: 0, null: false
      t.integer :cached_votes_down, default: 0, null: false
    end
    add_column :questions, :answers_count, :integer, default: 0, null: false

    execute <<~SQL.squish
      UPDATE posts SET comments_count = (
        SELECT COUNT(*) FROM comments WHERE comments.post_id = posts.id
      )
    SQL
    execute <<~SQL.squish
      UPDATE questions SET answers_count = (
        SELECT COUNT(*) FROM answers WHERE answers.question_id = questions.id
      )
    SQL
    execute <<~SQL.squish
      UPDATE posts
      LEFT JOIN (
        SELECT votable_id,
               SUM(vote_flag = TRUE) AS up_votes,
               SUM(vote_flag = FALSE) AS down_votes
        FROM votes
        WHERE votable_type = 'Post' AND vote_scope IS NULL
        GROUP BY votable_id
      ) tallies ON tallies.votable_id = posts.id
      SET posts.cached_votes_up = COALESCE(tallies.up_votes, 0),
          posts.cached_votes_down = COALESCE(tallies.down_votes, 0),
          posts.cached_votes_total = COALESCE(tallies.up_votes, 0) + COALESCE(tallies.down_votes, 0),
          posts.cached_votes_score = COALESCE(tallies.up_votes, 0) - COALESCE(tallies.down_votes, 0)
    SQL
  end

  def add_check_constraints
    add_check_constraint :posts, "state IS NULL OR state IN ('published', 'unpublished')",
                         name: "posts_valid_state"
    add_check_constraint :friendships, "user_id <> friend_id", name: "friendships_no_self_follow"
    add_check_constraint :conversations, "author_id <> receiver_id", name: "conversations_distinct_participants"
  end

  def add_query_indexes
    # Blog index: published posts, newest first.
    add_index :posts, %i[state created_at]
    # Forum index: newest questions first.
    add_index :questions, :created_at
    # Activity feed: activities by the people you follow, newest first.
    add_index :activities, %i[owner_type owner_id created_at], name: "index_activities_on_owner_and_created_at"
  end
end
