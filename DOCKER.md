# Running JBot with Docker

This guide covers running the JBot web interface locally using Docker, without needing Ruby installed.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

## Setup

### 1. Configure your environment

Copy the example env file if you haven't already:

```bash
cp .env.example .env
```

Open `.env` and set at minimum:

| Variable | Description |
|---|---|
| `SHOWBOT_LOCALE` | Locale for the bot (e.g. `en`) |
| `DATA_JSON_URL` | URL to your `data.json` file, or leave blank to use a local file at `public/data.json` |

The database is SQLite by default — no `SHOWBOT_DATABASE_URL` needed for local development.

### 2. Build the image

```bash
docker compose build
```

This installs all Ruby gems inside the container. It will take a few minutes the first time.

### 3. Run the web server

```bash
docker compose up
```

The app will automatically run any pending database migrations on startup, then start the web server.

Open your browser to [http://localhost:5000](http://localhost:5000).

## Common Commands

| Command | Description |
|---|---|
| `docker compose up` | Start the web server |
| `docker compose up --build` | Rebuild the image and start |
| `docker compose down` | Stop and remove the container |
| `docker compose run web bash` | Open a shell inside the container |
| `docker compose run web bundle exec rake db:seed` | Seed the database with fake suggestions |
| `docker compose run web bundle exec rake db:migrate` | Run migrations manually |
| `docker compose run web bundle exec rake api_key:generate` | Generate an API key |

## Data Persistence

The `db/` directory is mounted as a Docker volume, so your SQLite database persists between container restarts. To start fresh, delete `db/development.db`.

## Troubleshooting

**`bundle install` fails with a gem conflict**
The `activesupport` version pin in the Gemfile may conflict with `activerecord ~> 7.1`. Remove or update the `activesupport` line in the Gemfile and rebuild.

**Port 5000 already in use**
Change the host port in `docker-compose.yml`:
```yaml
ports:
  - "5001:5000"   # access via localhost:5001
```

**`rake db:migrate` fails on startup**
Run it manually to see the full error:
```bash
docker compose run web bundle exec rake db:migrate
```
