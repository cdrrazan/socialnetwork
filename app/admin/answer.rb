ActiveAdmin.register Answer do
  menu parent: "Questions"
  actions :all, except: %i[new edit]

  filter :body
  filter :created_at

  index do
    selectable_column
    id_column
    column(:question) { |answer| link_to answer.question.title, admin_question_path(answer.question) }
    column(:author) { |answer| answer.user&.display_name }
    column(:body) { |answer| truncate(answer.body, length: 80) }
    column :created_at
    actions
  end
end
