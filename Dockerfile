FROM ruby:3.0.2-alpine3.13 AS builder

LABEL maintener='yirbah@qovery.com'

# Minimal requirements to run a Rails app
RUN apk add --no-cache --update build-base \
  linux-headers \
  git \
  postgresql-dev=~13 \
  # Rails SQL schema format requires `pg_dump(1)` and `psql(1)`
  postgresql=~13 \
  # Install same version of pg_dump
  postgresql-client=~13 \
  nodejs \
  yarn \
  # Needed for nodejs / node-gyp
  python2 \
  tzdata

ENV BUNDLER_VERSION 2.2.24
ENV BUNDLE_JOBS 8
ENV BUNDLE_RETRY 5
ENV BUNDLE_WITHOUT development:test
ENV BUNDLE_CACHE_ALL true
ENV RAILS_ENV production
ENV RACK_ENV production
ENV NODE_ENV production
ENV APP_PATH /work

WORKDIR $APP_PATH

# Gems installation
COPY Gemfile Gemfile.lock ./

RUN gem install bundler -v $BUNDLER_VERSION

RUN bundle config --global frozen 1 && \
  bundle install && \
  rm -rf /usr/local/bundle/cache/*.gem && \
  find /usr/local/bundle/gems/ -name "*.c" -delete && \
  find /usr/local/bundle/gems/ -name "*.o" -delete

# NPM packages installation
COPY package.json yarn.lock ./

RUN yarn install --frozen-lockfile --non-interactive --production

ADD . $APP_PATH

RUN SECRET_KEY_BASE=`bin/rake secret` rails assets:precompile --trace && \
  yarn cache clean && \
  rm -rf node_modules tmp/cache vendor/assets test

FROM ruby:3.0.2-alpine3.13

RUN mkdir -p /work
WORKDIR /work

ENV RAILS_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true

# Some native extensions required by gems such as pg or mysql2.
COPY --from=builder /usr/lib /usr/lib

# Timezone data is required at runtime
COPY --from=builder /usr/share/zoneinfo/ /usr/share/zoneinfo/

# Ruby gems
COPY --from=builder /usr/local/bundle /usr/local/bundle

COPY --from=builder /work /work

COPY docker-entrypoint.sh ./

EXPOSE 3000

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["rails", "server",  "-p",  "3000", "-b", "0.0.0.0"]