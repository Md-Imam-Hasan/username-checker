# Dockerfile
FROM ruby:3.4.3-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs postgresql-client libyaml-dev

# Set working directory
WORKDIR /username_checker

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the entire app
COPY . .

# Expose port 3000 for Rails
EXPOSE 3000

# Start Rails server
CMD ["rails", "s", "-b", "0.0.0.0"]