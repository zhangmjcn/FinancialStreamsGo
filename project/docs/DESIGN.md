# Financial Streams System Design Document

## 系统概述

Financial Streams是一个用于处理金融市场实时数据的高性能系统，主要处理以下数据类型：
- Tick数据（实时行情数据）
- K线数据（蜡烛图数据）
- 交易信号

## 系统架构

### 目录结构
```
/
├── docker/              # Docker配置文件
│   ├── Dockerfile      # 应用程序Docker镜像定义
│   └── docker-compose.yml # 多容器编排配置
└── project/            # 项目源代码
    ├── src/           # Go源代码
    │   ├── main.go    # 程序入口
    │   ├── models/    # 数据模型
    │   │   ├── tick.go    # Tick数据结构
    │   │   ├── kline.go   # K线数据结构
    │   │   └── signal.go  # 信号数据结构
    │   └── processors/    # 数据处理器
    │       ├── tick_processor.go  # Tick处理器
    │       └── kline_builder.go   # K线构建器
    ├── lib/           # 第三方库和工具
    ├── docs/          # 文档
    └── go.mod         # Go模块定义
```

## 核心组件

### 1. 数据模型 (models/)

#### Tick数据模型
- **用途**: 存储实时市场行情数据
- **字段**: Symbol, Price, Volume, Timestamp, Bid/Ask价格和量
- **特点**: 高频数据，需要高效处理

#### K线数据模型
- **用途**: 存储不同时间周期的蜡烛图数据
- **字段**: OHLCV (Open, High, Low, Close, Volume)
- **支持周期**: 1分钟、5分钟、15分钟、1小时、1天等

#### 信号数据模型
- **用途**: 存储交易信号和策略输出
- **类型**: BUY, SELL, HOLD
- **附加信息**: 信号强度、来源策略、元数据

### 2. 数据处理器 (processors/)

#### TickProcessor
- **功能**: 处理原始tick数据
- **职责**: 
  - 数据验证
  - 数据标准化
  - 异常过滤
- **设计模式**: 管道模式，通过channel传递数据

#### KlineBuilder
- **功能**: 从tick数据构建K线
- **职责**:
  - 聚合tick数据到指定时间周期
  - 维护OHLCV数据
  - 定时输出完成的K线
- **并发处理**: 使用sync.RWMutex保证线程安全

## 技术栈

### 后端
- **语言**: Go 1.21
- **并发模型**: Goroutines + Channels
- **数据处理**: 流式处理架构

### 基础设施 - PRODUCTION-FIRST PRINCIPLE
- **消息队列**: RabbitMQ (实时数据流)
- **数据库**: ClickHouse (高性能时序数据库)
- **容器化**: Docker
- **编排**: Kubernetes (生产环境)

**重要**: 系统遵循PRODUCTION-FIRST PRINCIPLE，禁止使用测试数据库、内存数据库或模拟数据源

## 数据流设计

```
[真实加密货币交易所] → [Exchange Connectors] → [RabbitMQ] → [crypto_ticks_to_db] → [ClickHouse]
         ↓                    ↓                   ↓              ↓                ↓
    [WebSocket APIs]     [数据标准化]        [消息队列]       [批量处理]        [时序存储]
         ↓                    ↓                   ↓              ↓                ↓
    [实时行情数据]         [StandardTick]      [持久消息]      [性能优化]       [分析查询]
```

### RabbitMQ队列生命周期管理

为确保系统稳定性和防止队列积累，系统采用以下队列生命周期管理原则：

#### 1. 固定队列名称策略
- **队列名称**: 统一固定为 `crypto-ticks-to-db`
- **目的**: 防止程序重启时产生临时队列积累
- **一致性**: 确保所有组件使用相同的队列名称

#### 2. 队列初始化管理
在程序启动时执行：
- **存在性检查**: 验证队列是否已存在
- **绑定验证**: 确认队列已正确绑定到交换机
- **创建策略**: 队列不存在时按正确配置创建

#### 3. 队列长度控制
- **默认最大长度**: 5,000,000 条消息
- **环境变量配置**: `RABBITMQ_MAX_QUEUE_LENGTH`
- **溢出策略**: `x-overflow: drop-head` (删除旧消息，保留最新数据)
- **内存保护**: 防止队列无限增长导致系统资源耗尽

#### 4. 生产级配置
```bash
# 队列长度控制环境变量
export RABBITMQ_MAX_QUEUE_LENGTH=5000000

# 队列配置参数
x-max-length: 5000000          # 最大消息数量
x-overflow: drop-head          # 溢出时删除头部（旧消息）
x-message-ttl: 86400000        # 消息TTL: 24小时（毫秒）
```

## 性能考虑

1. **Channel缓冲**: 使用带缓冲的channel避免阻塞
2. **并发处理**: 利用Go的goroutine实现并发数据处理
3. **内存管理**: 及时清理过期数据，避免内存泄漏
4. **批量处理**: 适当批量处理数据以提高效率

## 扩展性设计

1. **模块化架构**: 各组件松耦合，便于独立扩展
2. **接口设计**: 定义清晰的接口，支持多种数据源和处理器
3. **配置驱动**: 支持通过配置文件调整系统行为
4. **水平扩展**: 支持多实例部署，通过消息队列协调

## 运行环境

### 开发环境启动
```bash
# 启动所有服务
cd docker
docker-compose up -d

# 运行应用
cd project
go run src/main.go
```

### 生产环境部署
```bash
# 构建并启动
cd docker
docker-compose up -d --build
```

### 服务停止
```bash
cd docker
docker-compose down
```

## 开发工作分配

### Agent专门化分工

#### Go代码相关工作
Go语言的代码开发、测试和运行工作应该由专门的Go相关Agent负责：

1. **go-code-maintainer**: 负责Go代码的编写、修改、优化和维护
   - 创建新的Go函数和模块
   - 修复Go代码中的bug
   - 优化Go代码性能
   - 更新Go依赖项
   - 确保Go代码符合项目规范

2. **go-test-runner**: 负责Go程序的测试和运行
   - 在代码修改后测试Go程序
   - 运行Go程序并捕获输出
   - 分析运行错误和调试信息
   - 验证Go程序的正确性
   - 协调其他Agent解决运行中的问题
   - 网络连接：遇到网络问题时可使用socks5h://localhost:1080代理

#### Docker容器相关工作
Docker相关的操作由专门的Agent负责：

**docker-operations-manager**: 负责Docker和Docker Compose的所有操作
- 创建和修改Dockerfile
- 管理Docker镜像的构建和优化
- 配置Docker网络和卷映射
- 处理Docker相关的故障排除

**重要工作规范**：
1. **容器添加原则**：
   - 在docker-compose.yml中添加新容器必须先获得用户确认
   - 不自动添加未明确需要的服务容器（如Redis、PostgreSQL、MongoDB等）
   - 仅在有明确使用场景和用户需求时才添加新容器
   
2. **最小化原则**：
   - 保持Docker配置精简，只包含必要的服务
   - 避免预先添加"可能会用到"的服务
   - 每个新增服务都应有明确的业务需求支撑

3. **变更管理**：
   - 所有Docker Compose配置变更需记录在文档中
   - 说明每个容器的用途和必要性
   - 定期审查并清理不再使用的容器配置

这种分工确保了专业化处理，提高了开发效率和代码质量。

## 业务场景架构

### 业务场景目录结构
所有业务场景独立存放在 `project/scenarios/` 目录下，每个场景拥有独立的目录结构：

```
project/scenarios/
└── [scenario_name]/
    ├── main.go           # 场景主程序
    ├── adapters/         # 适配器实现
    ├── config/           # 配置文件
    ├── tests/            # 测试文件
    └── README.md         # 场景说明文档
```

### crypto_ticks_to_db 场景

#### 场景概述
将来自真实加密货币交易所的tick数据存储到ClickHouse数据库中，采用适配器模式实现数据源和数据库的解耦。

**PRODUCTION-FIRST强制**: 
- 数据源: 仅允许RabbitMQ (连接真实交易所数据)
- 数据库: 仅允许ClickHouse (高性能时序存储)
- 禁止模拟数据、测试数据库或内存存储

#### 架构设计
**生产级适配器架构**：
1. **数据源适配器层**: RabbitMQ消息队列适配器，接收来自真实交易所的标准化tick数据
2. **数据库适配器层**: ClickHouse时序数据库适配器，提供高性能数据存储和查询

#### 标准Tick格式
```go
type StandardTick struct {
    Symbol      string    // 交易对 (BTC/USDT)
    Exchange    string    // 交易所名称
    Price       float64   // 成交价格
    Volume      float64   // 成交量
    Timestamp   time.Time // 时间戳
    BidPrice    float64   // 买一价
    BidVolume   float64   // 买一量
    AskPrice    float64   // 卖一价
    AskVolume   float64   // 卖一量
    TradeID     string    // 交易ID
}
```

#### 接口定义
```go
// 数据源适配器接口
type DataSourceAdapter interface {
    Connect(config map[string]string) error
    Subscribe(symbols []string) error
    ReadTick() (*StandardTick, error)
    Close() error
}

// 数据库适配器接口
type DatabaseAdapter interface {
    Connect(config map[string]string) error
    WriteTick(tick *StandardTick) error
    WriteBatch(ticks []*StandardTick) error
    Close() error
}
```

#### 数据流设计
```
[真实交易所] → [Exchange Connectors] → [RabbitMQ] → [RabbitMQ Adapter] → [StandardTick] → [Pipeline] → [ClickHouse Adapter] → [ClickHouse DB]
                                                            ↓
                                                    [批量处理/监控/日志]
```

#### RabbitMQ队列管理实现
- **固定队列名称**: `crypto-ticks-to-db`
- **队列参数配置**:
  ```go
  queueArgs := amqp091.Table{
      "x-max-length":   maxQueueLength,    // 由RABBITMQ_MAX_QUEUE_LENGTH环境变量控制
      "x-overflow":     "drop-head",       // 删除旧消息保留新数据
      "x-message-ttl":  86400000,          // 24小时TTL
  }
  ```
- **启动检查**: 程序启动时验证队列存在且正确配置
- **监控指标**: 队列深度、处理速率、溢出事件

#### 并发处理策略
- 使用Go Channel进行数据流控制
- 批量处理提高数据库写入效率
- 连接池管理优化资源使用
- 背压控制防止内存溢出

#### 错误处理
- 重试机制：指数退避策略
- 死信队列：处理失败的tick数据
- 监控告警：Prometheus metrics集成
- 优雅降级：数据源故障自动切换

## 未来扩展计划

1. 添加更多技术指标计算器
2. 实现策略回测引擎
3. 添加WebSocket API支持
4. 集成更多数据源适配器
5. 实现分布式处理能力