# Financial Streams System Architecture

## PRODUCTION-FIRST PRINCIPLE 🏭

**CRITICAL ARCHITECTURAL MANDATE**: The entire Financial Streams system operates under the **PRODUCTION-FIRST PRINCIPLE** - a fundamental architectural constraint that ensures the system defaults to processing real, production data exclusively.

### Core Production Requirements

The system **MUST** enforce these requirements by default:

1. **FORBID Mock Data Sources**: No test data generators, simulators, or mock sources are permitted
2. **FORBID Test Databases**: No in-memory databases, temporary databases, or test storage backends
3. **MANDATORY Real Data**: All data processing must originate from legitimate cryptocurrency exchanges
4. **MANDATORY Production Infrastructure**: RabbitMQ for data ingestion, ClickHouse for data storage
5. **DEFAULT Production Mode**: When users start any program without explicit configuration, it must enter production data processing state

### Enforcement Mechanisms

#### 1. Configuration Validation
- Environment variable validation in `/project/scenarios/crypto_ticks_to_db/config/config.go`
- Runtime validation in `/project/scenarios/crypto_ticks_to_db/main.go:validateProductionConfig()`
- Factory pattern restrictions preventing non-production adapter instantiation

#### 2. Code-Level Enforcement
```go
// PRODUCTION-ONLY validation examples
if cfg.Source.Type != "rabbitmq" {
    return fmt.Errorf("FORBIDDEN: Source type '%s' is not allowed in production")
}
if cfg.Database.Type != "clickhouse" {
    return fmt.Errorf("FORBIDDEN: Database type '%s' is not allowed in production")
}
```

#### 3. Default Configuration
- All configuration defaults point to production infrastructure
- No development or test mode configurations in production deployments
- Automatic rejection of mock or test components during initialization

---

## System Architecture Overview

### High-Level Architecture

```
[REAL CRYPTO EXCHANGES] 
         ↓
[EXCHANGE CONNECTORS] → [RabbitMQ] → [crypto_ticks_to_db] → [ClickHouse]
         ↓                    ↓              ↓                  ↓
    [WebSocket/REST]     [Message Queue]  [Processing]    [Time-Series DB]
```

### Component Architecture

#### 1. Data Source Layer
**Current State**: RabbitMQ message queue consumer (production-ready)
**Missing Component**: Real cryptocurrency exchange data connectors

**Required Architecture**:
```
[Exchange APIs] → [Exchange Connectors] → [RabbitMQ Exchange]
     ↓                    ↓                      ↓
[Binance WS]        [Binance Connector]    [crypto.ticks]
[Coinbase WS]       [Coinbase Connector]   [Topic Exchange]
[Kraken WS]         [Kraken Connector]     [Routing Keys]
[OKX WS]            [OKX Connector]        [Persistent Queue]
```

#### 2. Message Queue Infrastructure
**Implementation**: RabbitMQ with topic exchange
- **Exchange**: `crypto.ticks`
- **Routing Pattern**: `{exchange}.{symbol}`
- **Message Format**: Standardized JSON tick data
- **Durability**: Persistent messages and durable queues
- **Scaling**: Clustered RabbitMQ for high availability

#### 3. Processing Pipeline
**Implementation**: Go-based stream processor with adapter pattern
- **Source Adapter**: RabbitMQ consumer
- **Database Adapter**: ClickHouse writer
- **Pipeline Features**: Batching, circuit breaker, metrics, graceful shutdown
- **Concurrency**: Configurable worker pools for throughput optimization

#### 4. Storage Layer
**Implementation**: ClickHouse time-series database
- **Engine**: MergeTree with date partitioning
- **Schema**: Optimized for time-series crypto tick data
- **Performance**: Columnar storage, compression, parallel processing
- **Retention**: Configurable data retention policies

---

## Data Flow Architecture

### 1. Real-Time Data Ingestion Flow
```
[Exchange WebSocket] → [Connector Process] → [RabbitMQ] → [Consumer] → [ClickHouse]
                                ↓
                        [Error Handling/Retry]
                                ↓
                        [Dead Letter Queue]
```

### 2. Message Processing Flow
```
[RabbitMQ Message] → [JSON Parse] → [Validation] → [StandardTick] → [Batch] → [ClickHouse]
                                         ↓
                                   [Schema Validation]
                                         ↓
                                   [Data Enrichment]
```

### 3. Monitoring and Metrics Flow
```
[Processing Pipeline] → [Metrics Collection] → [Log Output]
                                ↓
[Performance Metrics] → [Health Checks] → [Alerting]
```

---

## Required Real Data Producer Architecture

### CRITICAL MISSING COMPONENT: Exchange Data Connectors

The system currently lacks real cryptocurrency exchange data producers. The following architecture must be implemented:

#### 1. Exchange Connector Service
```
crypto_exchange_connectors/
├── main.go                 # Multi-exchange connector orchestrator
├── exchanges/
│   ├── binance/
│   │   ├── websocket.go    # Binance WebSocket client
│   │   ├── rest.go         # Binance REST API client
│   │   └── types.go        # Binance-specific data types
│   ├── coinbase/
│   │   ├── websocket.go    # Coinbase Pro WebSocket
│   │   ├── rest.go         # Coinbase Pro REST API
│   │   └── types.go        # Coinbase-specific data types
│   ├── kraken/
│   │   └── ...             # Kraken implementation
│   └── okx/
│       └── ...             # OKX implementation
├── publishers/
│   └── rabbitmq.go         # RabbitMQ publisher
├── config/
│   └── exchanges.yaml      # Exchange configuration
└── monitoring/
    └── metrics.go          # Connector metrics
```

#### 2. Exchange Data Normalization
All exchange-specific data must be normalized to the `StandardTick` format:
```go
type StandardTick struct {
    Symbol      string    // "BTC/USDT"
    Exchange    string    // "binance"
    Price       float64   // Last trade price
    Volume      float64   // Trade volume
    Timestamp   time.Time // Trade timestamp
    BidPrice    float64   // Best bid
    BidVolume   float64   // Bid volume
    AskPrice    float64   // Best ask
    AskVolume   float64   // Ask volume
    TradeID     string    // Exchange trade ID
}
```

#### 3. Publisher Integration
Exchange connectors must publish normalized tick data to RabbitMQ:
```go
// Routing key format: {exchange}.{base}.{quote}
// Examples: "binance.BTC.USDT", "coinbase.ETH.USDT"
publisher.Publish(exchangeName, symbol, standardTick)
```

---

## Security and Reliability Architecture

### 1. Connection Security
- **TLS/SSL**: All exchange connections use encrypted WebSocket/HTTPS
- **API Authentication**: Secure storage and rotation of API keys
- **Rate Limiting**: Respect exchange rate limits and implement backoff
- **IP Whitelisting**: Configure exchange API access restrictions

### 2. Error Handling and Resilience
- **Circuit Breaker**: Prevent cascade failures during exchange outages
- **Exponential Backoff**: Graceful handling of temporary connection failures
- **Dead Letter Queues**: Capture and analyze failed message processing
- **Health Checks**: Continuous monitoring of all system components

### 3. Data Quality Assurance
- **Schema Validation**: Strict validation of incoming tick data
- **Duplicate Detection**: Prevent duplicate tick processing
- **Timestamp Validation**: Ensure data freshness and ordering
- **Price Validation**: Detect and filter anomalous price data

---

## Scalability and Performance Architecture

### 1. Horizontal Scaling
```
[Load Balancer] → [Multiple Connector Instances] → [RabbitMQ Cluster]
                                ↓
[Multiple Processing Instances] → [ClickHouse Cluster]
```

### 2. Performance Optimization
- **Connection Pooling**: Reuse connections to exchanges and databases
- **Batch Processing**: Aggregate ticks for efficient database writes
- **Memory Management**: Efficient tick data structures and garbage collection
- **Concurrent Processing**: Multi-worker pipeline processing

### 3. Monitoring and Observability
- **Real-time Metrics**: Processing rate, error rate, latency measurements
- **Health Dashboards**: System component health visualization
- **Alerting System**: Automated alerts for system degradation
- **Performance Profiling**: Continuous performance monitoring and optimization

---

## Deployment Architecture

### 1. Production Environment
```
[Kubernetes Cluster]
├── [Exchange Connectors Pod]
├── [RabbitMQ StatefulSet]
├── [Crypto Ticks Processor Deployment]
├── [ClickHouse StatefulSet]
└── [Monitoring Stack]
```

### 2. Infrastructure Requirements
- **High Availability**: Multi-node deployment with failover
- **Resource Allocation**: CPU and memory optimization for each component
- **Network Configuration**: Secure internal communication
- **Storage**: Persistent volumes for database and queue storage

### 3. Configuration Management
- **Environment Variables**: Centralized configuration management
- **Secrets Management**: Secure storage of sensitive configuration
- **Feature Flags**: Runtime configuration control
- **Version Control**: Infrastructure as code practices

---

## Next Steps for Implementation

### Priority 1: Real Data Producer Implementation
1. **Design Exchange Connector Architecture**
2. **Implement Binance WebSocket Connector**
3. **Implement Coinbase Pro WebSocket Connector**
4. **Create Multi-Exchange Orchestrator**
5. **Integrate with Existing RabbitMQ Infrastructure**

### Priority 2: Production Deployment
1. **Container Orchestration Setup**
2. **Production Environment Configuration**
3. **Monitoring and Alerting Implementation**
4. **Performance Testing and Optimization**

### Priority 3: Additional Exchanges
1. **Kraken Integration**
2. **OKX Integration**
3. **Additional Exchange Expansion**

This architecture ensures the Financial Streams system operates exclusively with real cryptocurrency market data while maintaining high performance, reliability, and scalability characteristics required for production financial data processing.