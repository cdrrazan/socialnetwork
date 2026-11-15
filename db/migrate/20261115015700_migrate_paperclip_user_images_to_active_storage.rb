# Moves profile pictures uploaded through Paperclip (stored under
# public/system/users/user_images/:id_partition/original/) into Active Storage
# as the User#avatar attachment, then drops the old Paperclip columns.
class MigratePaperclipUserImagesToActiveStorage < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    MigrationUser.reset_column_information

    MigrationUser.where.not(user_image_file_name: nil).find_each do |legacy|
      path = paperclip_path(legacy)
      next unless File.exist?(path)

      user = User.find(legacy.id)
      next if user.avatar.attached?

      File.open(path, "rb") do |file|
        user.avatar.attach(io: file,
                           filename: legacy.user_image_file_name,
                           content_type: legacy.user_image_content_type)
      end
    end

    change_table :users, bulk: true do |t|
      t.remove :user_image_file_name, :user_image_content_type,
               :user_image_file_size, :user_image_updated_at
    end
  end

  def down
    change_table :users, bulk: true do |t|
      t.string   :user_image_file_name
      t.string   :user_image_content_type
      t.integer  :user_image_file_size
      t.datetime :user_image_updated_at
    end
  end

  private

  def paperclip_path(user)
    partition = format("%09d", user.id).scan(/\d{3}/).join("/")
    Rails.root.join("public/system/users/user_images", partition, "original", user.user_image_file_name).to_s
  end
end
