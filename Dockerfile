FROM ruby:3.4.2-slim

# System dependencies
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libsqlite3-dev \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install gems first (layer cached separately from app code)
# BUNDLE_WITHOUT controls which gem groups are excluded at build time.
# Override this arg in docker-compose to include test gems for the test service.
ARG BUNDLE_WITHOUT="test production backup irc"
COPY Gemfile ./
RUN bundle config set --local without "${BUNDLE_WITHOUT}" \
 && bundle install --jobs 4 --retry 3

# Copy the rest of the app
COPY . .

# Create the db directory for SQLite
RUN mkdir -p db

EXPOSE 5000

RUN chmod +x docker-entrypoint.sh
ENTRYPOINT ["./docker-entrypoint.sh"]
