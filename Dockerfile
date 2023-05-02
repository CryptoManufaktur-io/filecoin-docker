# Build Lotus in a stock Go build container
FROM golang:1.19-bullseye as builder

ARG BUILD_TARGET

RUN apt-get update && apt-get install -y mesa-opencl-icd ocl-icd-opencl-dev ntpdate gcc git bzr jq pkg-config curl clang build-essential hwloc libhwloc-dev wget
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /src
RUN bash -c "git clone https://github.com/filecoin-project/lotus.git && cd lotus && git config advice.detachedHead false && git fetch --all --tags && git checkout ${BUILD_TARGET} && make clean all && make install"

FROM ghcr.io/tomwright/dasel:v2.2.0-alpine as dasel

# Pull all binaries into a second stage deploy container
FROM debian:bullseye-slim

ARG USER=filecoin
ARG UID=10000

RUN apt-get update && apt-get install -y ca-certificates bash tzdata hwloc libhwloc-dev wget

# See https://stackoverflow.com/a/55757473/12429735RUN
RUN adduser \
    --disabled-password \
    --gecos "" \
    --shell "/sbin/nologin" \
    --uid "${UID}" \
    "${USER}"

RUN mkdir -p /home/${USER}/.lotus && chown -R ${USER}:${USER} /home/${USER}
# Copy executable
COPY --from=builder /usr/local/bin/lotus /usr/local/bin/
COPY ./docker-entrypoint.sh /usr/local/bin/
COPY --from=dasel /usr/local/bin/dasel /usr/local/bin/

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["lotus"]
