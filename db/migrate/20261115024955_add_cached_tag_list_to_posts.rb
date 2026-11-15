# acts-as-taggable-on reads and maintains a `cached_tag_list` column when one
# exists, so listing posts with their tags no longer needs two queries per
# post. Existing posts are back-filled from their taggings.
class AddCachedTagListToPosts < ActiveRecord::Migration[8.1]
  def up
    add_column :posts, :cached_tag_list, :string, limit: 1024

    execute <<~SQL.squish
      UPDATE posts
      JOIN (
        SELECT taggings.taggable_id AS post_id,
               GROUP_CONCAT(tags.name ORDER BY taggings.id SEPARATOR ', ') AS names
        FROM taggings
        JOIN tags ON tags.id = taggings.tag_id
        WHERE taggings.taggable_type = 'Post' AND taggings.context = 'tags'
        GROUP BY taggings.taggable_id
      ) tag_lists ON tag_lists.post_id = posts.id
      SET posts.cached_tag_list = tag_lists.names
    SQL
  end

  def down
    remove_column :posts, :cached_tag_list
  end
end
