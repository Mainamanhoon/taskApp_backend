# syntax=docker/dockerfile:1

FROM hexpm/elixir:1.14.5-erlang-26.2.5-alpine as build

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
COPY assets assets
RUN cd assets && npm install && npm run deploy
RUN mix phx.digest

# build project
COPY lib lib
COPY priv priv
RUN mix compile

# release
RUN mix release

# app image
FROM alpine:3.18 AS app

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

ENV LANG=C.UTF-8
ENV REPLACE_OS_VARS=true
ENV MIX_ENV=prod

COPY --from=build /app/_build/prod/rel/shader_backend ./

CMD ["bin/shader_backend", "start"]
