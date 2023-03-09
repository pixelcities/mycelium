ARG GITHUB_NPM_TOKEN

ARG ELIXIR_VERSION=1.14.3
ARG OTP_VERSION=24.3.4.9
ARG ALPINE_VERSION=3.17
ARG ALPINE_PATCH=2

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION}.${ALPINE_PATCH}"
ARG RUNNER_IMAGE="alpine:${ALPINE_VERSION}.${ALPINE_PATCH}"

FROM rust:alpine${ALPINE_VERSION} as RUST
FROM ${BUILDER_IMAGE} as BUILDER

ENV MIX_ENV="prod"
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

WORKDIR /srv

RUN apk update && \
    apk add build-base protobuf-dev curl inotify-tools nodejs npm && \
    npm install -g sass

COPY --from=RUST /usr/local/cargo /usr/local/cargo
COPY --from=RUST /usr/local/rustup /usr/local/rustup

# Install hex + rebar
RUN rm -Rf _build && \
    mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
COPY mix.exs mix.lock ./
COPY apps apps
RUN mix deps.get

RUN mkdir config
COPY config/config.exs config/${MIX_ENV}.exs config/
COPY config/runtime.exs config/

# Compile
RUN RUSTFLAGS="-C target-feature=-crt-static" mix compile
RUN ln -s /usr/local/bin/sass /srv/_build/sass-linux-x64 # Fix sass on alpine
RUN cd apps/content_server && \
    echo '//npm.pkg.github.com/:_authToken=${GITHUB_NPM_TOKEN}' >> assets/.npmrc && \
    mix setup && \
    mix assets.deploy

# Create release
RUN mix release && \
    rm /srv/_build/${MIX_ENV}/rel/mycelium/releases/COOKIE # Force the use of RELEASE_COOKIE

#---
FROM ${RUNNER_IMAGE}

RUN apk update && \
    apk add --no-cache libstdc++ openssl ncurses-libs musl-locales

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV MIX_ENV="prod"

WORKDIR "/srv"
RUN chown nobody /srv

COPY --from=BUILDER --chown=nobody:root /srv/_build/${MIX_ENV}/rel/mycelium ./

USER nobody

CMD ["/srv/bin/mycelium", "start"]
