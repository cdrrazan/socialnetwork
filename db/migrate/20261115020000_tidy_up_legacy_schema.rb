# Cleans up a few leftovers from the original 2017 schema:
#
# * answers belonged to a post by mistake; they belong to questions.
# * several foreign keys were plain integers without indexes or constraints.
# * an unused `relationships` table existed in some databases without a
#   migration ever creating it.
#
# MySQL only accepts a foreign key when both columns have exactly the same
# type. Databases created in 2017 use `int` primary keys, while tables created
# by these migrations today get `bigint` ones, so each referencing column is
# first converted to the type of the primary key it points at.
class TidyUpLegacySchema < ActiveRecord::Migration[8.1]
  def up
    drop_table :relationships, if_exists: true

    remove_reference :answers, :post, index: true, foreign_key: true if column_exists?(:answers, :post_id)
    add_index :answers, :question_id unless index_exists?(:answers, :question_id)
    add_matching_foreign_key :answers, :questions

    add_index :questions, :user_id unless index_exists?(:questions, :user_id)
    add_matching_foreign_key :questions, :users

    add_matching_foreign_key :comments, :users
    add_matching_foreign_key :comments, :posts

    add_matching_foreign_key :friendships, :users
    add_matching_foreign_key :friendships, :users, column: :friend_id
    add_index :friendships, %i[user_id friend_id], unique: true

    add_matching_foreign_key :conversations, :users, column: :author_id
    add_matching_foreign_key :conversations, :users, column: :receiver_id

    add_index :users, :username, unique: true
  end

  def down
    remove_index :users, :username

    remove_foreign_key :conversations, column: :receiver_id
    remove_foreign_key :conversations, column: :author_id

    remove_index :friendships, %i[user_id friend_id]
    remove_foreign_key :friendships, column: :friend_id
    remove_foreign_key :friendships, column: :user_id

    remove_foreign_key :comments, :posts
    remove_foreign_key :comments, :users

    remove_foreign_key :questions, :users
    remove_index :questions, :user_id

    remove_foreign_key :answers, :questions
    remove_index :answers, :question_id
    add_reference :answers, :post, index: true, foreign_key: true
  end

  private

  def add_matching_foreign_key(from_table, to_table, column: "#{to_table.to_s.singularize}_id")
    primary_key = connection.columns(to_table).find { |c| c.name == "id" }
    foreign_key = connection.columns(from_table).find { |c| c.name == column.to_s }

    if foreign_key.sql_type != primary_key.sql_type
      change_column from_table, column, primary_key.type, limit: primary_key.limit
    end

    add_foreign_key from_table, to_table, column: column
  end
end
