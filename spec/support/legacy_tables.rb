# Lets a spec recreate a table the way it looked in a 2017 database: no NOT
# NULL, foreign key or check constraints, so the rows DataAudit looks for can
# actually be inserted.
#
# MySQL TEMPORARY tables shadow the real table of the same name for the
# current connection only, and creating or dropping them doesn't commit the
# transaction each example runs in, so nothing leaks between examples.
module LegacyTables
  def with_legacy_table(name, columns)
    connection = ActiveRecord::Base.connection
    definition = columns.map { |column, type| "#{connection.quote_column_name(column)} #{type}" }.join(", ")
    connection.execute("CREATE TEMPORARY TABLE #{connection.quote_table_name(name)} (#{definition})")
    yield
  ensure
    connection.execute("DROP TEMPORARY TABLE IF EXISTS #{connection.quote_table_name(name)}")
  end

  def legacy_insert(table, rows)
    connection = ActiveRecord::Base.connection
    Array.wrap(rows).each do |row|
      columns = row.keys.map { |column| connection.quote_column_name(column) }.join(", ")
      values = row.values.map { |value| connection.quote(value) }.join(", ")
      connection.execute("INSERT INTO #{connection.quote_table_name(table)} (#{columns}) VALUES (#{values})")
    end
  end
end

RSpec.configure do |config|
  config.include LegacyTables, :legacy_tables
end
