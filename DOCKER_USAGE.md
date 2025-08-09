# Docker 使用指南

## 快速开始

### 1. 使用 env_for_docker 配置文件启动服务

```bash
# 使用启动脚本（推荐）
./docker-start.sh

# 或者直接使用 docker-compose
docker-compose --env-file env_for_docker up -d
```

### 2. 启动脚本选项

```bash
# 构建并启动所有服务（默认）
./docker-start.sh

# 强制重新构建镜像
./docker-start.sh --build

# 重启服务
./docker-start.sh --restart

# 查看日志
./docker-start.sh --logs

# 停止服务
./docker-start.sh --stop
```

## 服务架构

```
┌─────────────────────────────────────────────────┐
│              Docker Network                      │
│                                                  │
│  ┌──────────────┐      ┌──────────────┐        │
│  │  RabbitMQ    │      │  ClickHouse  │        │
│  │  Port: 5672  │      │  Port: 9001  │        │
│  │  UI: 15672   │      │  HTTP: 8123  │        │
│  └──────┬───────┘      └──────┬───────┘        │
│         │                      │                 │
│         └──────┬───────────────┘                │
│                │                                 │
│       ┌────────▼────────┐                       │
│       │ Crypto Processor│                       │
│       │   (主应用)       │                       │
│       └─────────────────┘                       │
└─────────────────────────────────────────────────┘
```

## 配置说明

### env_for_docker 文件结构

```env
# RabbitMQ 配置
RABBITMQ_DEFAULT_USER=admin
RABBITMQ_DEFAULT_PASS=password

# ClickHouse 配置
CLICKHOUSE_USER=admin
CLICKHOUSE_PASSWORD=password
CLICKHOUSE_DATABASE=crypto_ticks

# 应用配置
ENV=production
LOG_LEVEL=info
BATCH_SIZE=5000
```

## 服务访问

| 服务 | 用途 | 访问地址 | 用户名/密码 |
|------|------|----------|-------------|
| RabbitMQ 管理界面 | 消息队列管理 | http://localhost:15672 | admin/password |
| ClickHouse HTTP | 数据库查询 | http://localhost:8123 | admin/password |
| ClickHouse Native | 数据库连接 | localhost:9001 | admin/password |

## 数据持久化

数据存储在以下目录：
- RabbitMQ 数据: `./data/rabbitmq/`
- ClickHouse 数据: `./data/clickhouse/data/`
- ClickHouse 日志: `./data/clickhouse/logs/`
- 应用日志: `./logs/crypto-processor/`

## 常用命令

### 查看服务状态
```bash
docker-compose --env-file env_for_docker ps
```

### 查看实时日志
```bash
# 所有服务
docker-compose --env-file env_for_docker logs -f

# 特定服务
docker-compose --env-file env_for_docker logs -f crypto-ticks-processor
```

### 进入容器调试
```bash
# 进入应用容器
docker exec -it fs-crypto-processor sh

# 进入 ClickHouse 容器
docker exec -it fs-clickhouse clickhouse-client --user admin --password password

# 进入 RabbitMQ 容器
docker exec -it fs-rabbitmq rabbitmqctl status
```

### 查看资源使用
```bash
docker stats
```

## 故障排查

### 1. 服务无法启动
```bash
# 检查端口占用
netstat -tulpn | grep -E '(5672|15672|8123|9001)'

# 查看详细错误
docker-compose --env-file env_for_docker logs
```

### 2. 连接问题
```bash
# 测试 RabbitMQ 连接
docker exec fs-rabbitmq rabbitmq-diagnostics ping

# 测试 ClickHouse 连接
docker exec fs-clickhouse clickhouse-client --query "SELECT 1"
```

### 3. 清理并重新开始
```bash
# 停止并删除所有容器、网络、卷
docker-compose --env-file env_for_docker down -v

# 清理 Docker 系统
docker system prune -a

# 重新构建并启动
./docker-start.sh --build
```

## 生产环境注意事项

1. **修改默认密码**: 编辑 `env_for_docker` 文件，更改默认的用户名和密码
2. **资源限制**: 根据实际需求调整 docker-compose.yml 中的资源限制
3. **备份策略**: 定期备份 `./data/` 目录下的数据
4. **监控**: 考虑添加 Prometheus + Grafana 进行监控
5. **日志管理**: 配置日志轮转，避免磁盘空间耗尽

## 扩展功能

### 启用数据生产者（可选）
```bash
# 包含数据生产者服务
docker-compose --env-file env_for_docker --profile with-producer up -d
```

### 性能调优
编辑 `env_for_docker` 文件调整以下参数：
- `BATCH_SIZE`: 批处理大小
- `WORKER_COUNT`: 工作线程数
- `BUFFER_SIZE`: 缓冲区大小
- `CLICKHOUSE_MEM_LIMIT`: ClickHouse 内存限制

## 更新和维护

### 更新镜像
```bash
# 拉取最新基础镜像
docker-compose --env-file env_for_docker pull

# 重新构建应用镜像
./docker-start.sh --build
```

### 备份数据
```bash
# 备份脚本示例
tar -czf backup-$(date +%Y%m%d).tar.gz ./data/
```

---

**注意**: 确保 Docker 和 Docker Compose 已正确安装，且当前用户有 Docker 权限。