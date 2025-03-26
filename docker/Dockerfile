############################################
# Healthcheck Binary
############################################
FROM golang:1.21.4-bookworm AS build_healthcheck

WORKDIR /app
ARG TARGETPLATFORM

# Copy only the Go file to optimize build caching
COPY ./extra/healthcheck.go ./extra/healthcheck.go

# Compile healthcheck.go with optimizations
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o ./healthcheck ./extra/healthcheck.go

############################################
# Build
############################################
FROM node:18.12.0-alpine AS build

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Install essential build dependencies
RUN apt update && apt install --yes --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && npm install pnpm -g

WORKDIR /app
COPY --chown=node:node ./package.json ./package.json
COPY --chown=node:node ./pnpm-lock.yaml ./pnpm-lock.yaml
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --no-frozen-lockfile

############################################
# ⭐ Main Image
############################################
FROM node:22-bookworm-slim AS release

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Install runtime dependencies
RUN apt update && apt install --yes --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    dumb-init \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo \
         "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
         "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
         tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt update \
    && apt --yes --no-install-recommends install \
         docker-ce-cli \
         docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/* \
    && npm install pnpm -g \
    && pnpm install -g tsx

WORKDIR /app
COPY --chown=node:node --from=build_healthcheck /app/healthcheck /app/extra/healthcheck
COPY --from=build /app/node_modules /app/node_modules
COPY --chown=node:node . .
RUN mkdir -p ./data


# Disable IO_URING for stability
# Read more:
# - https://github.com/sagemathinc/cocalc/issues/6963
# - https://github.com/microsoft/node-pty/issues/630#issuecomment-1987212447
ENV UV_USE_IO_URING=0

# Set Rackge environment variables
ENV RACKGE_HOST=0.0.0.0
ENV RACKGE_PORT=5050

VOLUME /app/data
EXPOSE 5050

# Use the updated healthcheck
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 CMD /app/extra/healthcheck

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["tsx", "./backend/index.ts"]

############################################
# Mark as Nightly
############################################
FROM release AS nightly
LABEL org.opencontainers.image.title="Rackge Nightly"
LABEL org.opencontainers.image.description="Nightly build of Rackge - Docker Compose stack manager"
RUN pnpm run mark-as-nightly

############################################
# Development Environment
############################################
FROM node:18.12.0-alpine AS development

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Install development dependencies including SQLite build tools
RUN apk add --no-cache \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    dumb-init \
    python3 \
    make \
    g++ \
    git \
    docker-cli \
    && npm install -g pnpm \
    && pnpm install -g tsx concurrently wait-on cross-env

WORKDIR /app

# Disable IO_URING for stability
ENV UV_USE_IO_URING=0

# Set Rackge environment variables
ENV RACKGE_HOST=0.0.0.0
ENV RACKGE_PORT=5050

VOLUME /app/data
EXPOSE 5000 5050

# Use dumb-init as PID 1 to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
