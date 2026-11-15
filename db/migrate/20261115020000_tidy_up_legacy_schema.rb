# Cleans up a few leftovers from the original 2017 schema:
#
# * answers belonged to a post by mistake; they belong to questions.
# * several foreign keys were plain integers without indexes or constraints.
# * an unused `relationships` table existed in some databases without a
#   migration ever creating it.
class TidyUpLegacySchema < ActiveRecord::Migration[8.1]
  def up
    drop_table :relationships, if_exists: true

    remove_reference :answers, :post, index: true, foreign_key: true if column_exists?(:answers, :post_id)
    add_index :answers, :question_id unless index_exists?(:answers, :question_id)
    add_foreign_key :answers, :questions

    add_index :questions, :user_id unless index_exists?(:questions, :user_id)
    add_foreign_key :questions, :users

    add_foreign_key :comments, :users
    add_foreign_key :comments, :posts

    add_foreign_key :friendships, :users
    add_foreign_key :friendships, :users, column: :friend_id
    add_index :friendships, %i[user_id friend_id], unique: true

    add_foreign_key :conversations, :users, column: :author_id
    add_foreign_key :conversations, :users, column: :receiver_id

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
end
