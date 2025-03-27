#!/bin/bash
# Script for building and running the Rackge nightly version
# Created: March 26, 2025

set -e

echo "🚀 Building Rackge Nightly Version"

# Set environment variables
export VERSION=$(node ./extra/get-version.js)-nightly
export NODE_ENV=production
export RACKGE_PORT=5050

echo "📦 Version: $VERSION"

# Build frontend assets
echo "🔨 Building frontend assets..."
pnpm run build:frontend

# Mark as nightly version
echo "🌙 Marking as nightly version..."
pnpm run mark-as-nightly

# Build Docker image with optimized settings
echo "🐳 Building Docker image..."
docker compose -f compose.yaml --profile build build --no-cache

# Start the container
echo "🚀 Starting Rackge nightly container..."
docker compose -f compose.yaml up -d

echo "✅ Rackge nightly version is now running!"
echo "🌐 Access the application at http://localhost:$RACKGE_PORT"
