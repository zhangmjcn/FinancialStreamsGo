# Docker Configuration for FinancialStreamsJ

This directory contains Docker configurations optimized for the `crypto_ticks_to_db` business scenario.

## Services

### RabbitMQ (Message Broker)
- **Image**: `rabbitmq:3-management-alpine`
- **Ports**: 
  - 5672 (AMQP)
  - 15672 (Management UI)
- **Credentials**: admin/admin123
- **Management UI**: http://localhost:15672

### ClickHouse (Analytics Database)
- **Image**: `clickhouse/clickhouse-server:latest`
- **Ports**: 
  - 9000 (Native TCP)
  - 8123 (HTTP Interface)
- **Credentials**: admin/admin123
- **HTTP Interface**: http://localhost:8123

## Quick Start

### Start Services
```bash
cd dockers/
./start.sh
```

### Stop Services
```bash
cd dockers/
./stop.sh
```

### Manual Docker Compose Commands
```bash
# Start services in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes (WARNING: deletes all data)
docker-compose down -v
```

## Network Configuration

If you experience network connectivity issues with docker.io:

1. Enable proxy mode by setting environment variable:
   ```bash
   export USE_PROXY=true
   ./start.sh
   ```

2. Or manually edit `.env` file and uncomment proxy settings:
   ```env
   HTTP_PROXY=socks5h://localhost:1080
   HTTPS_PROXY=socks5h://localhost:1080
   ```

## Data Persistence

All data is persisted in the `../data/` directory:
- `../data/rabbitmq/` - RabbitMQ data and configuration
- `../data/clickhouse/data/` - ClickHouse database files
- `../data/clickhouse/logs/` - ClickHouse server logs

## Resource Configuration

### Production Limits (ClickHouse)
- Memory: 4GB limit, 2GB reserved
- CPU: 2.0 cores limit, 1.0 core reserved

### Development
For development, you can remove or adjust the resource limits in `docker-compose.yml`.

## Health Checks

Both services include health checks:
- RabbitMQ: `rabbitmq-diagnostics ping`
- ClickHouse: `clickhouse-client --query "SELECT 1"`

## Configuration

### ClickHouse
Custom configuration is provided in `../project/scenarios/crypto_ticks_to_db/config/clickhouse-config.xml`:
- Optimized for high-frequency tick data ingestion
- Async inserts enabled
- Memory and merge settings tuned for financial data

### RabbitMQ
Default configuration with management plugin enabled. Additional configuration can be added via volume mounts.

## Security Notes

**Important**: Default credentials are used for development. For production:

1. Change default passwords in `.env` file
2. Use proper authentication mechanisms
3. Configure network security
4. Enable TLS/SSL for external connections

## Troubleshooting

### Port Conflicts
If ports are already in use, modify the port mappings in `docker-compose.yml`.

### Network Issues
1. Check if Docker daemon is running
2. Try enabling proxy mode with `USE_PROXY=true`
3. Check firewall settings

### Data Permission Issues
Ensure proper ownership:
```bash
sudo chown -R $(whoami):$(whoami) ../data/
```

### View Container Status
```bash
docker-compose ps
docker-compose logs [service_name]
```