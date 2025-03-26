############################################
# Build in Golang
############################################
FROM golang:1.21.4-bookworm AS builder

WORKDIR /app
ARG TARGETPLATFORM

# Copy only the Go file to optimize build caching
COPY ./extra/healthcheck.go ./extra/healthcheck.go

# Compile healthcheck.go with optimizations
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o ./healthcheck ./extra/healthcheck.go

############################################
# Create minimal image for the healthcheck binary
############################################
FROM scratch

# Copy the healthcheck binary from the builder stage
COPY --from=builder /app/healthcheck /healthcheck

# Document that this is the Rackge healthcheck tool
LABEL org.opencontainers.image.title="Rackge Healthcheck"
LABEL org.opencontainers.image.description="Healthcheck utility for Rackge"

# Set the healthcheck binary as the entrypoint
ENTRYPOINT ["/healthcheck"]
