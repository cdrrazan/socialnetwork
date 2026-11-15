json.extract! question, :id, :title, :body, :created_at, :updated_at
json.author question.user.display_name
json.url question_url(question, format: :json)
