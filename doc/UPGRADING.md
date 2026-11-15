# Upgrading from the 2017 version

The 2026 revamp moved DevStory from Ruby 2.4 / Rails 5.0 / MySQL to
Ruby 4.0 / Rails 8.1 / SQLite and replaced several abandoned gems. A fresh
install needs nothing special (see the [README](../README.md)). This page is
for anyone with an **existing database** from the old version.

## 1. Rotate leaked secrets

The old repository committed a `.env` file with live Google reCAPTCHA keys and
`config/secrets.yml` with development/test `secret_key_base` values. They have
been removed, but they remain in the git history. Generate new reCAPTCHA keys
in the [reCAPTCHA admin console](https://www.google.com/recaptcha/admin),
delete the old ones, and keep the new ones in `.env` (git-ignored) or your
deployment's environment.

## 2. Choose a database

The app now defaults to SQLite. You can either keep MySQL or move your data.

### Option A: keep MySQL

The application code doesn't depend on SQLite. To stay on MySQL:

1. Add `gem "mysql2"` to the `Gemfile` and run `bundle install`.
2. Change `config/database.yml` to use `adapter: mysql2` with your existing
   credentials (or set `DATABASE_URL`, e.g.
   `mysql2://user:password@localhost/socialnetwork_production`).
3. Continue with step 3 below.

### Option B: move to SQLite

1. Back up the MySQL database.
2. Export each table and import it into the SQLite databases created by
   `bin/rails db:prepare`, keeping primary keys. Any MySQL-to-SQLite
   conversion tool works; afterwards check that row counts match.
3. Copy `public/system/` (the old Paperclip uploads) into the new checkout so
   step 3 can migrate them.

## 3. Run the new migrations

```bash
bin/rails db:migrate
```

Three migrations run on an existing database:

| Migration                                         | What it does                                                                                     |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `CreateActiveStorageTables`                       | Adds the Active Storage tables.                                                                  |
| `MigratePaperclipUserImagesToActiveStorage`       | Copies each profile picture from `public/system/users/user_images/…/original/` into Active Storage, then drops the `user_image_*` columns. Missing files are skipped. |
| `TidyUpLegacySchema`                              | Drops the unused `relationships` table and the `answers.post_id` column, and adds indexes and foreign keys. |

`TidyUpLegacySchema` adds **foreign keys** and a **unique index on
`users.username`**. It will fail if your data has:

- comments, answers, questions, friendships or conversations pointing at
  users, posts or questions that no longer exist;
- two users with the same username (usernames are now required, unique and
  limited to letters, numbers, `_`, `.` and `-`);
- duplicate follows (the same `user_id`/`friend_id` pair twice).

Clean these rows up first. For example, to find orphaned comments:

```sql
SELECT * FROM comments WHERE user_id NOT IN (SELECT id FROM users)
                          OR post_id NOT IN (SELECT id FROM posts);
```

Existing users without a username can still log in, but will be asked for one
the next time they edit their profile.

## 4. Behaviour changes

- **Post bodies** were written in the Froala editor, which has been replaced by
  Trix. Existing HTML is still displayed, but it is now passed through Rails'
  `sanitize`, so scripts, inline event handlers and unusual tags are removed.
- **Answers** now belong to questions. Under Rails 5 answers silently failed to
  save, because they were declared as belonging to a post.
- **Authorization** is enforced everywhere with Pundit. Previously anyone could
  delete any answer or comment by crafting a request.
- **Moderators**: the `users.admin` flag (editable in the admin panel) now lets
  a member edit or delete anyone's posts and questions and delete comments
  and answers.
- **Activity feed**: entries are recorded for new posts and comments again.
  Nothing was recorded before, so the feed starts empty.
- **Landing page**: the static `public/index.html` page has been replaced by a
  Rails view. Signed-in members go straight to the blog.
- **reCAPTCHA** on new posts is enabled automatically when
  `RECAPTCHA_SITE_KEY`/`RECAPTCHA_SECRET_KEY` are set.
- **Following** uses `POST /friendships` instead of `POST /add_friends`.

## 5. Gem replacements

| Old                              | New                                    |
| -------------------------------- | -------------------------------------- |
| paperclip                        | Active Storage + image_processing      |
| cancan                           | pundit                                 |
| state_machine                    | plain scopes (`Post.published`/`unpublished`, `Post#publish!`) |
| turbolinks, jquery_ujs           | turbo-rails, stimulus-rails            |
| coffee-rails, uglifier           | import maps (no compilation)           |
| wysiwyg-rails (Froala)           | Trix                                   |
| bootstrap 4.0.0.alpha            | bootstrap 5.3                          |
| mysql2                           | sqlite3                                |
| redis (Action Cable)             | solid_cable                            |
| thin, spring                     | puma, bootsnap                         |
| byebug, pry, better_errors       | debug                                  |
| railroady, rails-erd             | Mermaid diagram in `doc/architecture.md` |
