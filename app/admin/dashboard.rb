ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "At a glance" do
          ul do
            li "#{User.count} members"
            li "#{Post.count} posts (#{Post.unpublished.count} awaiting publication)"
            li "#{Question.count} questions, #{Answer.count} answers"
          end
        end
      end
    end

    columns do
      column do
        panel "Recent posts" do
          ul do
            Post.newest_first.limit(10).each do |post|
              li link_to(post.title, admin_post_path(post))
            end
          end
        end
      end

      column do
        panel "Recently signed up" do
          ul do
            User.order(created_at: :desc).limit(10).each do |user|
              li link_to(user.display_name, admin_user_path(user))
            end
          end
        end
      end

      column do
        panel "Recent questions" do
          ul do
            Question.newest_first.limit(10).each do |question|
              li link_to(question.title, admin_question_path(question))
            end
          end
        end
      end
    end
  end
end
