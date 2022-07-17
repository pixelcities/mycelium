ARG ELIXIR_VERSION=1.13.4
ARG OTP_VERSION=24.3.4.1
ARG DEBIAN_VERSION=bullseye
ARG DEBIAN_BUILD=20210902

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}-${DEBIAN_BUILD}-slim"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM rust:slim-${DEBIAN_VERSION} as RUST
FROM ${BUILDER_IMAGE} as BUILDER

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /srv

ENV MIX_ENV="prod"

# setup and transfer rustup and cargo
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

COPY --from=RUST /usr/local/cargo /usr/local/cargo
COPY --from=RUST /usr/local/rustup /usr/local/rustup

# install hex + rebar
RUN rm -Rf _build && \
    mix local.hex --force && \
    mix local.rebar --force

# install mix dependencies
COPY mix.exs mix.lock ./
COPY apps apps

RUN mix deps.get
RUN mkdir config

# copy compile-time config files before we compile dependencies
COPY config/config.exs config/${MIX_ENV}.exs config/

RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/srv"
RUN chown nobody /srv

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release from the build stage
COPY --from=BUILDER --chown=nobody:root /srv/_build/${MIX_ENV}/rel/mycelium ./

USER nobody

CMD ["/srv/bin/mycelium", "start"]
