FROM bitwalker/alpine-elixir:1.4.5
ENV MIX_ENV prod
ADD ./mix.* /app/
WORKDIR /app
RUN mix do deps.get
ADD ./rel /app/rel
ADD ./config /app/config
ADD ./priv /app/priv
ADD ./lib /app/lib
RUN mix release --no-tar

FROM alpine:3.6
RUN apk add --no-cache openssl ncurses-libs
ENV REPLACE_OS_VARS true
ENV PORT 8080
EXPOSE 8080
COPY --from=0 /app/_build/prod/rel/scout /app
WORKDIR /app
CMD ./bin/scout foreground
