# Character set clean-up, for old and new databases alike.
#
# 1. Databases created in 2017 used MySQL's three-byte `utf8` (utf8mb3)
#    character set, which can't store emoji or other characters outside the
#    Basic Multilingual Plane. Every table that isn't utf8mb4 yet is
#    converted. CONVERT TO has side effects that are undone afterwards so an
#    upgraded database ends up identical to a freshly built one:
#    - it promotes TEXT columns to MEDIUMTEXT (to keep their byte capacity),
#    - it resets every column collation (tags.name must stay utf8mb4_bin),
#    - CHECK constraints keep their old `_utf8mb3'...'` string literals.
#
# 2. A TEXT column holds 65,535 *bytes*, but posts and questions may be 65,535
#    *characters* long; with four-byte characters a valid post wouldn't fit.
#    Body columns become MEDIUMTEXT (16 MB) on every database, and gem-owned
#    text columns are pinned to TEXT.
#
# On InnoDB with the DYNAMIC row format (the default since MySQL 5.7.7),
# 255-character utf8mb4 columns still fit in indexes.
class ConvertLegacyTablesToUtf8mb4 < ActiveRecord::Migration[8.1]
  CHARSET = "utf8mb4".freeze
  COLLATION = "utf8mb4_unicode_ci".freeze

  # Text columns owned by gems, pinned to plain TEXT so every database ends up
  # with the same types whatever its history.
  GEM_TEXT_COLUMNS = {
    "active_admin_comments" => "body",
    "activities" => "parameters",
    "active_storage_blobs" => "metadata"
  }.freeze

  BODY_COLUMNS = {
    "posts" => "body",
    "comments" => "body",
    "questions" => "body",
    "answers" => "body",
    "personal_messages" => "body"
  }.freeze

  def up
    tables = legacy_tables

    tables.each do |table|
      text_columns = columns(table).select { |column| column.sql_type == "text" }
      constraints = check_constraints(table)

      execute "ALTER TABLE #{quote_table_name(table)} CONVERT TO CHARACTER SET #{CHARSET} COLLATE #{COLLATION}"

      restore_text_columns(table, text_columns)
      rebuild_check_constraints(table, constraints)
    end

    change_column :tags, :name, :string, collation: "utf8mb4_bin", null: false if tables.include?("tags")

    GEM_TEXT_COLUMNS.each do |table, column|
      change_column table, column, :text
    end

    BODY_COLUMNS.each do |table, column|
      change_column table, column, :text, size: :medium, null: false
    end
  end

  def down
    BODY_COLUMNS.each do |table, column|
      change_column table, column, :text, null: false
    end
    # Tables stay utf8mb4: converting back could lose characters utf8mb3 can't
    # hold, and utf8mb4 stores everything utf8mb3 could.
  end

  private

  def legacy_tables
    select_values(<<~SQL.squish)
      SELECT table_name FROM information_schema.tables
      WHERE table_schema = DATABASE()
        AND table_type = 'BASE TABLE'
        AND table_collation NOT LIKE '#{CHARSET}\\_%'
    SQL
  end

  def restore_text_columns(table, text_columns)
    text_columns.each do |column|
      change_column table, column.name, :text, null: column.null
    end
  end

  def rebuild_check_constraints(table, constraints)
    constraints.each do |constraint|
      remove_check_constraint table, name: constraint.name
      add_check_constraint table, constraint.expression.gsub("_utf8mb3'", "'"), name: constraint.name
    end
  end
end
