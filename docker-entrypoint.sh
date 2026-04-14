#!/bin/sh
set -e

echo "Running database migrations..."
bundle exec rake db:migrate

echo "Starting web server..."
exec bundle exec thin start -p "${DEVELOPMENT_PORT:-5000}" -e development
