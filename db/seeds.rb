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
    "ruby, community, nepal" ],
  [ code, "Hotwire: Turbo Frames vs. Turbo Streams",
    "<p>Turbo Frames update one part of a page from a normal request. Turbo Streams push many small changes, even over WebSockets. Here's when I reach for each in Rails.</p>",
    "rails, hotwire" ],
  [ world, "Writing fast Ruby with YJIT",
    "<p>Ruby's YJIT compiler makes real Rails apps noticeably faster. A few habits help it: keep methods small, avoid needless object allocation and measure before optimising.</p>",
    "ruby, performance" ]
]

posts.each do |author, title, body, tags|
  post = author.posts.find_or_create_by!(title: title) do |new_post|
    new_post.body = body
    new_post.tag_list = tags
  end
  post.create_activity(:create, owner: author) unless PublicActivity::Activity.exists?(trackable: post, key: "post.create")
end

first_post = Post.find_by!(title: "Getting started with Ruby on Rails 8")
members.each { |member| first_post.upvote_from(member) unless member == code }
[ [ world, "Great write-up! Solid Queue has been rock solid for me." ],
  [ rubynepal, "Sharing this with our meetup group." ] ].each do |author, body|
  comment = first_post.comments.find_or_create_by!(user: author, body: body)
  comment.create_activity(:create, owner: author) unless PublicActivity::Activity.exists?(trackable: comment, key: "comment.create")
end

question = code.questions.find_or_create_by!(title: "How do I run a single Minitest test?") do |q|
  q.body = "I have a big test file and only want to run one test while I work on it. Is that possible?"
end
question.answers.find_or_create_by!(user: world) do |answer|
  answer.body = "Yes: `bin/rails test test/models/user_test.rb:42` runs the test defined on line 42."
end
question.answers.find_or_create_by!(user: rubynepal) do |answer|
  answer.body = "You can also filter by name: `bin/rails test -n /signing_up/`."
end

code.questions.find_or_create_by!(title: "SQLite in production: is it ready?") do |q|
  q.body = "Rails 8 defaults to SQLite in production. Has anyone run it with real traffic? What about backups?"
end
world.questions.find_or_create_by!(title: "Best way to learn Stimulus?") do |q|
  q.body = "I know Rails but I'm new to Stimulus. Any good resources or small projects to start with?"
end

code.friendships.find_or_create_by!(friend: world)
code.friendships.find_or_create_by!(friend: rubynepal)
world.friendships.find_or_create_by!(friend: code)
world.friendships.find_or_create_by!(friend: rubynepal)

conversation = Conversation.between(code.id, world.id).first ||
               Conversation.create!(author: code, receiver: world)
if conversation.personal_messages.none?
  conversation.personal_messages.create!(user: code, body: "Hey! Loved your post about Rails.")
  conversation.personal_messages.create!(user: world, body: "Thanks! Are you coming to the next meetup?")
  conversation.personal_messages.create!(user: code, body: "Definitely. I'm giving a lightning talk on Hotwire.")
end

puts "Seeded #{User.count} users, #{Post.count} posts and #{Question.count} questions."
puts "Log in as code@example.com / password, or at /admin as admin@example.com / password."
