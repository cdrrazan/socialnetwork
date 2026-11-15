# Changelog

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
