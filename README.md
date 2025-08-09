# FinancialStreamsGo

基于Go语言开发的实时加密货币数据处理系统，专注于高性能的实时市场数据采集、处理和存储。

## 系统概述

FinancialStreamsGo 是一个生产级的加密货币数据流处理系统，采用微服务架构设计，实现了从数据源到存储的完整数据管道。

### 核心特性

- **实时数据处理**: 支持高频实时市场数据流处理
- **高可用架构**: 基于RabbitMQ和ClickHouse的分布式架构
- **容器化部署**: 完整的Docker容器化解决方案
- **生产就绪**: 生产优先原则设计，默认生产模式运行
- **可扩展设计**: 支持多交易所数据源和水平扩展

### 系统架构

```
[加密货币交易所] → [数据连接器] → [RabbitMQ] → [数据处理器] → [ClickHouse]
                                    ↓              ↓             ↓
                              [消息队列]    [Go处理管道]   [时序数据库]
```

## 技术栈

- **编程语言**: Go 1.21+
- **消息队列**: RabbitMQ
- **数据库**: ClickHouse (时序数据库)
- **容器化**: Docker & Docker Compose
- **配置管理**: 环境变量配置

## 快速开始

### 环境要求

- Docker 20.10+
- Docker Compose 2.0+
- Go 1.21+ (开发环境)

### 1. 克隆项目

```bash
git clone https://github.com/yourusername/FinancialStreamsGo.git
cd FinancialStreamsGo
```

### 2. 配置环境

```bash
# 复制配置模板
cp sample.env .env

# 编辑配置文件，修改数据库和消息队列的密码
vim .env
```

**重要**: 请务必修改默认密码，确保生产环境安全！

### 3. 启动服务

```bash
# 使用Docker Compose启动完整服务栈
./docker-start.sh

# 或者手动启动
docker-compose --env-file env_for_docker up -d
```

### 4. 验证服务

访问以下地址验证服务正常运行：

- **RabbitMQ管理界面**: http://localhost:15672 (admin/password)
- **ClickHouse HTTP接口**: http://localhost:8123

## 项目结构

```
FinancialStreamsGo/
├── project/                          # 主项目代码
│   ├── scenarios/
│   │   └── crypto_ticks_to_db/       # 加密货币数据处理场景
│   │       ├── main.go               # 主程序入口
│   │       ├── adapters/             # 适配器模式实现
│   │       ├── config/               # 配置管理
│   │       └── docs/                 # 详细文档
│   ├── src/                          # 源代码
│   │   ├── models/                   # 数据模型
│   │   └── processors/               # 数据处理器
│   └── docs/                         # 项目文档
├── docker-compose.yml                # Docker服务编排
├── sample.env                        # 配置模板
└── README.md                         # 项目说明
```

## 核心组件

### 1. 数据处理管道 (crypto_ticks_to_db)

实时处理加密货币市场数据的核心组件：

- **数据来源**: RabbitMQ消息队列
- **处理逻辑**: 批量处理、数据验证、格式转换
- **数据输出**: ClickHouse时序数据库
- **监控指标**: 处理速度、错误率、延迟统计

### 2. 适配器架构

采用适配器模式实现组件解耦：

- **Source Adapter**: 支持多种数据源（当前：RabbitMQ）
- **Database Adapter**: 支持多种数据库（当前：ClickHouse）
- **扩展性**: 易于添加新的数据源和存储后端

### 3. 配置管理

统一的环境变量配置管理：

- **数据库连接**: ClickHouse连接配置
- **消息队列**: RabbitMQ连接配置  
- **应用参数**: 批处理大小、工作线程数等
- **监控配置**: 指标收集和健康检查

## 开发指南

### 构建项目

```bash
cd project/scenarios/crypto_ticks_to_db
go mod download
go build -o crypto_ticks_to_db ./main.go
```

### 运行测试

```bash
go test ./...
```

### 本地开发

```bash
# 启动基础服务
docker-compose --env-file env_for_docker up -d rabbitmq clickhouse

# 本地运行应用
cd project/scenarios/crypto_ticks_to_db
./crypto_ticks_to_db
```

## 部署指南

### Docker部署（推荐）

使用提供的Docker Compose配置进行一键部署：

```bash
# 启动所有服务
./docker-start.sh

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 生产环境部署

1. **配置安全**: 修改所有默认密码
2. **资源调优**: 根据负载调整内存和CPU限制
3. **数据备份**: 配置ClickHouse和RabbitMQ数据备份
4. **监控告警**: 部署监控系统和告警机制
5. **负载均衡**: 配置多实例负载均衡

## 监控和维护

### 健康检查

```bash
# 检查RabbitMQ状态
docker exec fs-rabbitmq rabbitmqctl status

# 检查ClickHouse状态
docker exec fs-clickhouse clickhouse-client --query "SELECT 1"

# 检查应用日志
docker logs fs-crypto-processor
```

### 性能调优

编辑配置文件调整性能参数：

- `BATCH_SIZE`: 批处理大小（默认5000）
- `WORKER_COUNT`: 工作线程数（默认5）  
- `BUFFER_SIZE`: 内存缓冲区大小（默认10000）

## API文档

详细的API文档和配置说明请参考：

- [系统架构文档](project/docs/ARCHITECTURE.md)
- [Docker使用指南](DOCKER_USAGE.md)
- [部署文档](project/scenarios/crypto_ticks_to_db/docs/deployment/)

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证。详情请参见 [LICENSE](LICENSE) 文件。

## 联系方式

如有问题或建议，欢迎通过以下方式联系：

- 提交 Issue: [GitHub Issues](https://github.com/yourusername/FinancialStreamsGo/issues)
- 项目Wiki: [GitHub Wiki](https://github.com/yourusername/FinancialStreamsGo/wiki)

## 发展路线图

### 即将发布的功能

- [ ] 支持更多加密货币交易所 (Binance, Coinbase, Kraken)
- [ ] 实时WebSocket数据连接器
- [ ] Grafana监控仪表板
- [ ] Kubernetes部署配置
- [ ] 数据质量验证和异常检测

### 长期目标

- [ ] 机器学习数据管道集成
- [ ] 多资产类别支持（股票、外汇等）
- [ ] 实时风险管理模块
- [ ] 高级数据分析API

---

**注意**: 这是一个生产级系统，在生产环境使用前请充分测试并配置适当的安全措施。