FROM node:18.12.0-alpine
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
# Install Alpine dependencies and Docker CLI
RUN apk add --no-cache \
    curl \
    ca-certificates \
    gnupg \
    unzip \
    docker-cli \
    dumb-init \
    git \
    && npm install pnpm -g \
    && pnpm install -g tsx

# Set environment variables to prevent native module issues
ENV ROLLUP_NATIVE_DISABLE=true \
    SKIP_NATIVE_BUILD=true \
    npm_config_ignore_scripts=true \
    npm_config_optional=false \
    UV_USE_IO_URING=0
