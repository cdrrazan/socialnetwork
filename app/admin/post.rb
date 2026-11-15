ActiveAdmin.register Post do
  menu priority: 3
  permit_params :title, :body

  scope :all, default: true
  scope :published
  scope :unpublished

  filter :title
  filter :body
  filter :state, as: :select, collection: [ "published", "unpublished" ]
  filter :created_at

  # Posts written from the admin panel are drafted as "unpublished" and
  # attributed to a member account matching the admin's email, if any.
  before_build do |post|
    post.state ||= "unpublished"
    post.user ||= User.find_by(email: current_admin_user.email) || User.first
  end

  member_action :publish, method: :put do
    resource.publish!
    redirect_to resource_path, notice: "Post published."
  end

  action_item :publish, only: :show, if: proc { resource.state == "unpublished" } do
    link_to "Publish", publish_admin_post_path(resource), method: :put
  end

  batch_action :publish do |ids|
    batch_action_collection.find(ids).each(&:publish!)
    redirect_to collection_path, notice: "#{ids.size} post(s) published."
  end

  index do
    selectable_column
    id_column
    column :title
    column(:author) { |post| post.user.display_name }
    column(:state) { |post| status_tag(post.state || "published") }
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :title
      row(:author) { |post| post.user.display_name }
      row(:state) { |post| status_tag(post.state || "published") }
      row :tag_list
      row :created_at
      row(:body) { |post| sanitize(post.body) }
    end
  end

  form do |f|
    f.inputs "Details" do
      f.input :title
      f.input :body
    end
    f.actions
  end
end
