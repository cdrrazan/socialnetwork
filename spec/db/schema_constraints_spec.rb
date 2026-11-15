require "rails_helper"

# The schema enforces the most important rules itself, so bad data is
# rejected even when model validations are skipped (bulk imports, raw SQL,
# update_columns, a bug). These specs bypass validations on purpose.
RSpec.describe "Database constraints" do
  let(:user) { create(:user) }
  let(:other) { create(:user) }

  def insert(model, attributes)
    timestamps = { created_at: Time.current, updated_at: Time.current }
    model.insert!(attributes.merge(timestamps))
  end

  it "uses MySQL with utf8mb4" do
    connection = ActiveRecord::Base.connection
    expect(connection.adapter_name).to eq("Mysql2")
    expect(connection.charset).to eq("utf8mb4")
  end

  it "stores four-byte characters such as emoji" do
    post = create(:post, title: "Shipping it 🚀")
    expect(post.reload.title).to eq("Shipping it 🚀")
  end

  describe "NOT NULL" do
    {
      Post => { title: nil, body: "x" },
      Comment => { body: nil },
      Question => { title: "x", body: nil },
      Answer => { body: nil },
      PersonalMessage => { body: nil }
    }.each do |model, attributes|
      it "rejects a #{model.name.underscore.humanize.downcase} with a missing value" do
        record = create(model.name.underscore.to_sym)
        expect { record.update_columns(attributes) }.to raise_error(ActiveRecord::NotNullViolation)
      end
    end

    it "requires users.admin" do
      expect { user.update_columns(admin: nil) }.to raise_error(ActiveRecord::NotNullViolation)
    end
  end

  describe "foreign keys" do
    it "rejects a comment on a post that doesn't exist" do
      expect { insert(Comment, body: "x", user_id: user.id, post_id: 0) }
        .to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "rejects an answer to a question that doesn't exist" do
      expect { insert(Answer, body: "x", user_id: user.id, question_id: 0) }
        .to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "rejects a follow of a user that doesn't exist" do
      expect { insert(Friendship, user_id: user.id, friend_id: 0) }
        .to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "refuses to delete a post that still has comments without going through Rails" do
      comment = create(:comment)
      expect { Post.where(id: comment.post_id).delete_all }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "unique indexes" do
    it "rejects a duplicate username regardless of case" do
      create(:user, username: "taken")
      duplicate = build(:user, username: "TAKEN")
      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects a duplicate follow" do
      create(:friendship, user: user, friend: other)
      expect { insert(Friendship, user_id: user.id, friend_id: other.id) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "rejects a second conversation between the same two people" do
      create(:conversation, author: user, receiver: other)
      expect { insert(Conversation, author_id: user.id, receiver_id: other.id) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "check constraints" do
    it "rejects an unknown post state" do
      post = create(:post)
      expect { post.update_columns(state: "archived") }.to raise_error(ActiveRecord::CheckViolation)
    end

    it "rejects following yourself" do
      expect { insert(Friendship, user_id: user.id, friend_id: user.id) }
        .to raise_error(ActiveRecord::CheckViolation)
    end

    it "rejects a conversation with yourself" do
      expect { insert(Conversation, author_id: user.id, receiver_id: user.id) }
        .to raise_error(ActiveRecord::CheckViolation)
    end
  end

  describe "column types" do
    it "uses 64-bit primary and foreign keys" do
      columns = Comment.columns_hash
      expect(columns.fetch("id").sql_type).to eq("bigint")
      expect(columns.fetch("post_id").sql_type).to eq("bigint")
      expect(columns.fetch("user_id").sql_type).to eq("bigint")
    end

    it "stores timestamps with microsecond precision" do
      expect(Post.columns_hash.fetch("created_at").precision).to eq(6)
    end

    it "stores body columns as MEDIUMTEXT" do
      [ Post, Comment, Question, Answer, PersonalMessage ].each do |model|
        expect(model.columns_hash.fetch("body").sql_type).to eq("mediumtext"), "#{model.name}.body"
      end
    end

    it "fits a post body at the 65,535-character limit even when every character takes four bytes" do
      body = "\u{1F680}" * 65_535 # 262,140 bytes: too big for a TEXT column
      post = create(:post, body: body)
      expect(post.reload.body.length).to eq(65_535)
    end

    it "uses utf8mb4 for every table" do
      collations = ActiveRecord::Base.connection.select_values(<<~SQL)
        SELECT DISTINCT table_collation FROM information_schema.tables
        WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE'
      SQL
      expect(collations).to all(start_with("utf8mb4_"))
    end

    it "compares tag names case-sensitively" do
      expect(ActsAsTaggableOn::Tag.columns_hash.fetch("name").collation).to eq("utf8mb4_bin")
    end
  end
end
