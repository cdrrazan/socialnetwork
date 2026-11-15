# Changelog

## 2026-11: MySQL, schema upgrade and RSpec

### Database

- Back on **MySQL** (8.0.16+, tested on 8.0 and 8.4) instead of SQLite, with
  utf8mb4, strict SQL mode and connection settings from `DB_*` variables.
  Production keeps Solid Cache/Queue/Cable in their own MySQL databases.
- Schema brought up to date: `BIGINT` keys everywhere, `NOT NULL` on every
  required column, microsecond timestamps, foreign keys on every reference,
  CHECK constraints (post states, no self-follows or self-conversations),
  indexes for the blog, forum and activity feed, `utf8mb4` for 2017 tables,
  `MEDIUMTEXT` bodies so 65,535-character posts fit in any script, and the
  unused `posts.slug` removed.
- Counter caches for comments, answers and votes, and a cached tag list on
  posts, all back-filled from existing rows. The blog index now runs the same
  number of queries however many posts it shows.
- `bin/rails data:audit` reports rows that break the rules (and works on a
  2017 database before migrating); `bin/rails data:reset_counters` fixes
  counters. The schema migration refuses to run while required columns
  contain NULLs.
- `script/rehearse_upgrade` (also a CI job) upgrades a 2017-style database
  with 2017-style data and checks it ends up identical to a fresh install.

### Tests

- Minitest replaced by **RSpec**: 448 examples across models, policies,
  services, requests, ActiveAdmin, MySQL constraints, seeds, channels, jobs,
  mailers, rake tasks and real-browser system specs (Cuprite).
- **100% line and branch coverage**, enforced by SimpleCov on every full run.
- CI runs the suite on Ruby 3.3, 3.4 and 4.0 against MySQL 8.4, and on MySQL
  8.0, checks migrations from scratch reproduce `db/schema.rb`, and audits the
  seeded data.

### Fixes found by the new specs

- Failed log-ins and sign-ups returned 200, so Turbo never showed the error
  messages; Devise now answers 422/303.
- A rejected (non-image) avatar upload crashed the profile form.
- "Similar posts" matched unrelated posts through words like "the" and "and";
  stop words are now ignored.
- The blog index ran two tag queries per post.
- `DataAudit` crashed on databases without a `posts.state` column.
- Seven 2017 migrations used `def self.up`, which skipped the Rails 5.0
  compatibility layer and produced different column types from run to run.
- `db:prepare` seeded demo accounts with the password "password" into a new
  production database; demo data now needs `SEED_DEMO_DATA=true`.

### Other

- `ApplicationJob` retries MySQL deadlocks; Action Cable connections are
  authenticated with the Devise session; emails are sent from `MAILER_FROM`
  through `ApplicationMailer`.
- The blog can be sorted by top-voted posts; tags are stored lowercase and
  unused tags are deleted.
- Docker Compose runs the app together with MySQL 8.4; `bin/setup` explains
  how to create the MySQL user when it can't connect.

## 2026-11: Rails 8.1 revamp

A complete modernisation of the 2017 codebase. See
[doc/UPGRADING.md](doc/UPGRADING.md) for how to migrate an existing
installation.

### Platform

- Ruby 2.4 → **Ruby 4.0** (3.3+ supported); Rails 5.0 → **Rails 8.1**.
- MySQL → **SQLite**, with Solid Queue, Solid Cache and Solid Cable in
  production.
- Turbolinks, jQuery UJS and CoffeeScript → **Hotwire** (Turbo + Stimulus)
  with import maps; no Node.js toolchain.
- Bootstrap 4 alpha → **Bootstrap 5.3**; Froala → **Trix**.
- Paperclip → **Active Storage**, with a data migration for existing uploads.
- CanCan → **Pundit**; state_machine removed.
- Devise 5, ActiveAdmin 3.5 (with Ransack 4 allowlists), acts-as-taggable-on 13,
  public_activity 3.
- New production Dockerfile and docker-compose setup.

### Fixes

- Answers could never be saved (they were declared as belonging to posts).
- Anyone could delete any answer or comment; authorization now covers every
  write action.
- Stored XSS: post bodies were rendered with `html_safe`; they are now
  sanitized.
- SQL `LIKE` wildcards in user search are escaped.
- The "similar posts" list included the post itself and ran one query per post.
- The static `public/index.html` hid the app's root route.
- Broken public_activity templates, duplicate root routes, `redirect_to :back`
  calls removed in Rails 5.1, and flash typos (`flash[:notice] ==`).
- Live reCAPTCHA keys and `secret_key_base` values removed from the repository.

### Features

- Comment editing, tag filtering, moderator role, publish workflow for
  admin-drafted posts, avatars throughout, empty states, `/up` health check.
- Activity feed entries are recorded for new posts and comments.
- Idempotent seed data.

### Development

- Test suite rewritten: model, policy, service, integration and Cuprite system
  tests.
- RuboCop (rails-omakase), Brakeman, bundler-audit and importmap audit, run by
  GitHub Actions on Ruby 3.3, 3.4 and 4.0; Dependabot enabled.
- New README, architecture notes with an ER diagram, recommendation algorithm
  write-up and upgrade guide.

## 2017: Initial version

Final-year project: blog with votes, tags and comments; Q&A forum; following;
private messaging; TF-IDF post recommendations; ActiveAdmin panel.
