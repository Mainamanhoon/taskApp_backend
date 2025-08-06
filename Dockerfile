# syntax=docker/dockerfile:1

FROM hexpm/elixir:1.15.8-erlang-26.2.5.14-alpine-3.21.4 as build

# install build dependencies
RUN apk add --no-cache build-base npm git

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only prod
RUN mix deps.compile

# build assets
# COPY assets assets
# RUN cd assets && npm install && npm run deploy
# RUN mix phx.digest

# build project
COPY lib lib
COPY priv priv
RUN mix compile

# release
RUN mix release

# app image
FROM alpine:3.21.4 AS app
RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app
COPY --from=build /app/_build/prod/rel/shader_backend ./

ENV LANG=en_US.UTF-8 \
    LC_CTYPE=en_US.UTF-8 \
    HOME=/app \
    MIX_ENV=prod \
    PHX_SERVER=true \
    PORT=${PORT}

CMD ["sh", "-c", "ls -l ./bin && ./bin/shader_backend start"]
