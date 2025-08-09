#!/bin/bash

# Start script for Financial Streams Docker containers
# Optimized for crypto_ticks_to_db scenario

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Starting Financial Streams Docker containers..."

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if we need to use proxy settings
if [ -n "${USE_PROXY}" ] && [ "${USE_PROXY}" = "true" ]; then
    echo "Using proxy configuration..."
    export HTTP_PROXY="socks5h://localhost:1080"
    export HTTPS_PROXY="socks5h://localhost:1080"
    export NO_PROXY="localhost,127.0.0.1"
fi

# Pull images first (with retry logic for network issues)
echo "Pulling Docker images..."
for image in rabbitmq:3-management-alpine clickhouse/clickhouse-server:latest; do
    echo "Pulling $image..."
    retries=3
    while [ $retries -gt 0 ]; do
        if docker pull "$image"; then
            break
        else
            echo "Failed to pull $image, retries remaining: $((retries-1))"
            retries=$((retries-1))
            if [ $retries -gt 0 ]; then
                echo "Waiting 5 seconds before retry..."
                sleep 5
            fi
        fi
    done
    if [ $retries -eq 0 ]; then
        echo "Failed to pull $image after 3 attempts"
        exit 1
    fi
done

# Create required directories
echo "Creating data directories..."
mkdir -p ../data/rabbitmq
mkdir -p ../data/clickhouse/data
mkdir -p ../data/clickhouse/logs
mkdir -p ../logs

# Set proper permissions for ClickHouse
chmod 755 ../data/clickhouse/data
chmod 755 ../data/clickhouse/logs

# Start services
echo "Starting services with docker-compose..."
docker-compose up -d

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
docker-compose ps

echo ""
echo "Services started successfully!"
echo ""
echo "RabbitMQ Management UI: http://localhost:15672"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "ClickHouse HTTP Interface: http://localhost:8123"
echo "  Username: admin" 
echo "  Password: admin123"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop services: docker-compose down"