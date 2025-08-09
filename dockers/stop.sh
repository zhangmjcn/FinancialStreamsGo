#!/bin/bash

# Stop script for Financial Streams Docker containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Stopping Financial Streams Docker containers..."

# Stop and remove containers
docker-compose down

echo "Containers stopped successfully!"
echo ""
echo "Data is preserved in ../data/ directory"
echo "To remove all data as well, run: docker-compose down -v"