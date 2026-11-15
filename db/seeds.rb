# Development seed data. Safe to run repeatedly: `bin/rails db:seed`.
#
# Creates an admin for /admin, a few members with posts, questions, answers,
# follows and a conversation so every page has something to show.

AdminUser.find_or_create_by!(email: "admin@example.com") do |admin|
  admin.password = admin.password_confirmation = "password"
end

members = {
  "code" => "code@example.com",
  "world" => "world@example.com",
  "rubynepal" => "rubynepal@example.com"
}.map do |username, email|
  User.find_or_create_by!(email: email) do |user|
    user.username = username
    user.password = user.password_confirmation = "password"
  end
end

code, world, rubynepal = members

posts = [
  [ code, "Getting started with Ruby on Rails 8",
    "<p>Rails 8 ships with SQLite in production, Solid Queue, Solid Cache and Kamal. Here is how I set up my first app.</p>",
    "ruby, rails" ],
  [ world, "Why I moved my side project to Rails",
    "<p>After years of JavaScript frameworks, Rails and Hotwire let me ship features faster than ever.</p>",
    "rails, hotwire, javascript" ],
  [ rubynepal, "Ruby meetup Kathmandu recap",
    "<p>Thanks to everyone who came to the Ruby meetup! Slides about Ruby performance and YJIT are below.</p>",
    "ruby, community, nepal" ]
]

posts.each do |author, title, body, tags|
  author.posts.find_or_create_by!(title: title) do |post|
    post.body = body
    post.tag_list = tags
  end
end

question = code.questions.find_or_create_by!(title: "How do I run a single Minitest test?") do |q|
  q.body = "I have a big test file and only want to run one test while I work on it. Is that possible?"
end
question.answers.find_or_create_by!(user: world) do |answer|
  answer.body = "Yes: `bin/rails test test/models/user_test.rb:42` runs the test defined on line 42."
end

code.friendships.find_or_create_by!(friend: world)
code.friendships.find_or_create_by!(friend: rubynepal)
world.friendships.find_or_create_by!(friend: code)

conversation = Conversation.between(code.id, world.id).first ||
               Conversation.create!(author: code, receiver: world)
if conversation.personal_messages.none?
  conversation.personal_messages.create!(user: code, body: "Hey! Loved your post about Rails.")
  conversation.personal_messages.create!(user: world, body: "Thanks! Are you coming to the next meetup?")
end

puts "Seeded #{User.count} users, #{Post.count} posts and #{Question.count} questions."
puts "Log in as code@example.com / password, or at /admin as admin@example.com / password."
