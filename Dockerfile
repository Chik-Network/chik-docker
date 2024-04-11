# CHIK BUILD STEP
FROM python:3.11-slim AS chik_build

ARG BRANCH=latest
ARG COMMIT=""

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        lsb-release sudo git

WORKDIR /chik-blockchain

RUN echo "cloning ${BRANCH}" && \
    if [ -z "$COMMIT" ]; then \
        DEPTH_FLAG="--depth 1"; \
    else \
        DEPTH_FLAG=""; \
    fi && \
    git clone ${DEPTH_FLAG} --branch ${BRANCH} --recurse-submodules=mozilla-ca https://github.com/Chik-Network/chik-blockchain.git . && \
    # If COMMIT is set, check out that commit, otherwise just continue
    ( [ ! -z "$COMMIT" ] && git fetch origin $COMMIT && git checkout $COMMIT ) || true && \
    echo "running build-script" && \
    /bin/sh ./install.sh -s

# Get yq for chik config changes
FROM mikefarah/yq:4 AS yq

# IMAGE BUILD
FROM python:3.11-slim

EXPOSE 9789 9678

ENV CHIK_ROOT=/root/.chik/mainnet
ENV keys="generate"
ENV service="farmer"
ENV plots_dir="/plots"
ENV farmer_address=
ENV farmer_port=
ENV testnet="false"
ENV TZ="UTC"
ENV upnp="true"
ENV log_to_file="true"
ENV healthcheck="true"
ENV chik_args=
ENV full_node_peer=

# Deprecated legacy options
ENV harvester="false"
ENV farmer="false"

# Minimal list of software dependencies
#   sudo: Needed for alternative plotter install
#   tzdata: Setting the timezone
#   curl: Health-checks
#   netcat: Healthchecking the daemon
#   yq: changing config settings
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y sudo tzdata curl netcat-traditional jq && \
    rm -rf /var/lib/apt/lists/* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata

COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=chik_build /chik-blockchain /chik-blockchain

ENV PATH=/chik-blockchain/venv/bin:$PATH
WORKDIR /chik-blockchain

COPY docker-start.sh /usr/local/bin/
COPY docker-entrypoint.sh /usr/local/bin/
COPY docker-healthcheck.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/docker-start.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-healthcheck.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=20m \
  CMD /bin/bash /usr/local/bin/docker-healthcheck.sh || exit 1

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-start.sh"]
