# Build Geth in a stock Go build container
FROM golang:1.16-bullseye as builder

ARG BUILD_TARGET

RUN apt-get update && apt-get install -y mesa-opencl-icd ocl-icd-opencl-dev ntpdate gcc git bzr jq pkg-config curl clang build-essential hwloc libhwloc-dev wget
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
WORKDIR /src
RUN bash -c "git clone https://github.com/filecoin-project/lotus.git && cd lotus && git config advice.detachedHead false && git fetch --all --tags && git checkout ${BUILD_TARGET} && make clean all && make install"

# Pull all binaries into a second stage deploy container
FROM debian:bullseye-slim

ARG USER=filecoin
ARG UID=10000

RUN apt-get update && apt-get install -y ca-certificates bash tzdata hwloc libhwloc-dev wget
RUN wget -qO /usr/local/bin/dasel https://github.com/TomWright/dasel/releases/download/v1.21.2/dasel_linux_amd64
RUN chmod +x /usr/local/bin/dasel

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

USER ${USER}
WORKDIR /home/${USER}

ENTRYPOINT ["lotus"]
