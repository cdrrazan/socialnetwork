# DevStory

[![CI](https://github.com/cdrrazan/socialnetwork/actions/workflows/ci.yml/badge.svg)](https://github.com/cdrrazan/socialnetwork/actions/workflows/ci.yml)

DevStory (originally *Coders Sanjal*) is a social network for developers. It
began in 2017 as a final-year project meant to be a meeting point for
developers, mostly in Nepal, to discuss, share ideas and collaborate. In 2026
it was brought up to date on Ruby 4.0 and Rails 8.1.

## Features

- **Blog**: write posts in a rich text editor (Trix), tag them, vote on them
  and comment on them.
- **Similar posts**: each post suggests related posts using TF-IDF and cosine
  similarity ([how it works](doc/recommendations.md)).
- **Forum**: ask questions and answer them.
- **People**: search for members, follow them and see their posts and comments
  in an activity feed.
- **Private messages**: one-to-one conversations.
- **Profiles**: usernames and profile pictures.
- **Admin panel** at `/admin` (ActiveAdmin): manage members, posts, questions
  and answers, draft and publish announcements, and grant moderator rights.
- **Moderation**: members can edit and delete their own content; moderators
  can delete anyone's.

## Tech stack

| Concern            | Choice                                                      |
| ------------------ | ----------------------------------------------------------- |
| Language/framework | Ruby 4.0 (3.3+ supported), Rails 8.1                         |
| Database           | SQLite 3 (development, test and production)                 |
| Jobs/cache/cable   | Solid Queue, Solid Cache, Solid Cable                       |
| Front end          | Hotwire (Turbo + Stimulus), import maps, Bootstrap 5.3, Trix |
| Assets             | Sprockets + Dart Sass (no Node.js needed)                   |
| Authentication     | Devise (members), plus a separate Devise model for admins   |
| Authorization      | Pundit                                                      |
| Uploads            | Active Storage (libvips for image variants)                 |
| Admin              | ActiveAdmin 3                                               |
| Tests              | Minitest, Capybara + Cuprite for system tests                |
| Quality            | RuboCop (rails-omakase), Brakeman, bundler-audit            |

See [doc/architecture.md](doc/architecture.md) for the data model and how the
pieces fit together.

## Getting started

### Requirements

- Ruby 4.0 (see [`.ruby-version`](.ruby-version); any Ruby ≥ 3.3 works)
- SQLite 3
- [libvips](https://www.libvips.org/install.html) to resize profile pictures
  (`brew install vips` or `apt install libvips`)
- Chrome or Chromium, only for system tests

No Node.js, Yarn, MySQL or Redis is needed.

### Setup

```bash
git clone https://github.com/cdrrazan/socialnetwork.git
cd socialnetwork
bin/setup
```

`bin/setup` installs gems, creates the database, loads demo content from
`db/seeds.rb` and starts the development server. (Seeds are idempotent; run
`bin/rails db:seed` any time to restore them.)

Then open http://localhost:3000 and log in as `code@example.com` with the
password `password`. The admin panel is at http://localhost:3000/admin
(`admin@example.com` / `password`).

To start the server again later, run `bin/dev`.

### Configuration

Optional settings are read from environment variables. In development you can
put them in a `.env` file (see [`.env.example`](.env.example)); it is ignored
by git.

| Variable                                     | Purpose                                                                 |
| -------------------------------------------- | ----------------------------------------------------------------------- |
| `RECAPTCHA_SITE_KEY`, `RECAPTCHA_SECRET_KEY` | Turn on Google reCAPTCHA for new posts. Without them it is switched off. |
| `SECRET_KEY_BASE`                            | Required in production.                                                  |
| `APP_HOST`                                   | Host name used in links in emails (production).                         |
| `FORCE_SSL`                                  | Set to `false` to serve production over plain HTTP. Defaults to `true`.  |
| `SOLID_QUEUE_IN_PUMA`                        | Run background jobs inside the web server process.                      |
| `RAILS_MAX_THREADS`, `WEB_CONCURRENCY`, `PORT` | Puma tuning.                                                           |

## Running the tests

```bash
bin/rails test           # models, policies, services, controllers and integration tests
bin/rails test:system    # browser tests (needs Chrome/Chromium)
```

If Chrome isn't on your `PATH`, point the system tests at it with
`BROWSER_PATH=/path/to/chrome`. Set `HEADLESS=false` to watch them run.

Linting and security checks:

```bash
bin/rubocop
bin/brakeman
bin/bundler-audit
bin/importmap audit
```

`bin/ci` runs setup, all of the above and the tests in one go. GitHub Actions
runs the same checks on every push and pull request, with the test suite on
Ruby 3.3, 3.4 and 4.0.

## Docker

The `Dockerfile` builds a production image. To try it locally:

```bash
SECRET_KEY_BASE=$(bin/rails secret) docker compose up --build
```

Open http://localhost:3000. The SQLite databases and uploads live in the
`storage` volume. To add demo data:

```bash
docker compose exec web bin/rails db:seed
```

## Deployment

The app is a standard Rails 8 application and deploys anywhere that runs a
container or Ruby. Things to know:

- Mount persistent storage at `storage/`: it holds the four SQLite databases
  (`production`, `production_cache`, `production_queue`, `production_cable`)
  and Active Storage uploads.
- Set `SECRET_KEY_BASE` (generate one with `bin/rails secret`) and `APP_HOST`.
- The container runs `bin/rails db:prepare` on start, so migrations are applied
  automatically.
- Run background jobs with `bin/jobs`, or set `SOLID_QUEUE_IN_PUMA=true` to run
  them inside Puma on a single server.
- Create the first admin from a console:
  `AdminUser.create!(email: "you@example.com", password: "a-long-password")`.

Upgrading an existing 2017 installation? Read
[doc/UPGRADING.md](doc/UPGRADING.md) first.

## Project layout

```
app/
  admin/         ActiveAdmin resources and dashboard
  controllers/   Blog, forum, messaging, people, and static pages
  javascript/    Import-mapped JS entry point and Stimulus controllers
  models/        Active Record models
  policies/      Pundit authorization policies
  services/      PostRecommender (TF-IDF similar posts)
  views/         ERB templates (Bootstrap 5)
db/              Schema, migrations and seeds
doc/             Architecture, recommendation algorithm and upgrade notes
test/            Minitest suite (unit, integration and system tests)
```

## Contributing

1. Fork the repository and create a branch from `master`.
2. Make your change with tests.
3. Run `bin/ci` (or at least `bin/rails test` and `bin/rubocop`).
4. Open a pull request.

## Credits

Originally written in 2017 by the DevStory / Coders Sanjal team. See the git
history for all contributors. Changes are listed in [CHANGELOG.md](CHANGELOG.md).
