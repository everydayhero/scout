# -------------
# Build Stage
#--------------

# Create a basic elixir/node build environment
FROM elixir:1.6-alpine as build
RUN apk add --update nodejs nodejs-npm
RUN mix local.hex --force
RUN mix local.rebar --force

# /build for source code, and /rel for extracted release archive
RUN mkdir /build /rel

# Fetch and build dependencies
WORKDIR /build
ENV MIX_ENV=prod
COPY mix.* /build/
RUN mix deps.get
COPY config /build/config
RUN mix deps.compile

# Copy sources into image
COPY lib /build/lib
COPY priv /build/priv
COPY rel /build/rel

# Build elixir OTP release, extracted to /rel
RUN mix phx.digest
RUN mix release
RUN tar -xvzf _build/prod/rel/*/releases/*/*.tar.gz -C /rel


#-----------------
# Deploy Stage
#-----------------

# Vanilla alpine base, ERTS is bundled with release
FROM alpine

# install required system dependencies
RUN apk add --no-cache bash openssl ncurses-libs

# Add the release binaries
COPY --from=build /rel /app

# Run app in foreground
WORKDIR /app
CMD bin/scout foreground
