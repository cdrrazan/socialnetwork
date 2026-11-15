ActiveAdmin.register Question do
  menu priority: 4
  permit_params :title, :body

  filter :title
  filter :body
  filter :created_at

  index do
    selectable_column
    id_column
    column :title
    column(:author) { |question| question.user.display_name }
    column(:answers) { |question| question.answers.size }
    column :created_at
    actions
  end
end
