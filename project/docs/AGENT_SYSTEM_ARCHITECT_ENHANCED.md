# System Architect Agent 增强规范

## 概述
本文档定义了 system-architect agent 的增强职责，特别是在目录结构维护和临时文件管理方面的新增职责。

## 增强职责定义

### 1. 目录结构维护职责

system-architect 负责：
- **结构设计**：设计和维护清晰的项目目录结构
- **功能集中**：确保相关功能代码集中在适当的目录中
- **命名规范**：执行一致的文件和目录命名规范
- **定期审查**：定期审查和优化目录结构

### 2. 临时文件清理职责

system-architect 负责识别和清理以下类型的临时文件：

#### 需要清理的文件模式
- `test_*.go`, `test_*.log` - 临时测试文件
- `debug_*.go`, `debug_*.log` - 调试文件
- `tmp_*`, `temp_*` - 临时文件
- `*.bak`, `*.tmp` - 备份和临时文件
- `old_*`, `deprecated_*` - 过时文件

#### 目标位置映射
```
原位置                    →  目标位置
src/test_*.go            →  tests/temp/
src/debug_*.go           →  debug/
scenarios/*/tmp_*        →  tmp/
任意位置/old_*           →  archive/
```

### 3. 生产环境优先原则

system-architect 确保：
- **默认生产模式**：系统默认运行在生产模式
- **禁用 Mock 数据**：除非明确指定，否则不使用 mock 或测试数据
- **直接就绪**：程序启动即可处理真实数据
- **配置验证**：验证所有配置指向生产资源（如真实的 RabbitMQ、ClickHouse）

## 执行策略

### 自动清理脚本

```bash
#!/bin/bash
# clean_temp_files.sh - 由 system-architect 维护的清理脚本

# 创建必要的目录
mkdir -p tests/temp debug tmp archive

# 清理测试文件
find ./src ./scenarios -name "test_*" -type f | while read file; do
    echo "Moving $file to tests/temp/"
    mv "$file" tests/temp/
done

# 清理调试文件
find ./src ./scenarios -name "debug_*" -type f | while read file; do
    echo "Moving $file to debug/"
    mv "$file" debug/
done

# 清理临时文件
find . -name "tmp_*" -o -name "temp_*" -o -name "*.tmp" | while read file; do
    echo "Moving $file to tmp/"
    mv "$file" tmp/
done

# 归档旧文件
find . -name "old_*" -o -name "deprecated_*" | while read file; do
    echo "Archiving $file"
    mv "$file" archive/
done
```

### 目录结构模板

```
FinancialStreamsJ/
├── project/
│   ├── src/                 # 核心业务逻辑
│   ├── lib/                 # 共享库
│   ├── scenarios/           # 场景实现（生产代码）
│   │   └── crypto_ticks_to_db/
│   ├── tests/               # 测试文件
│   │   ├── unit/           # 单元测试
│   │   ├── integration/    # 集成测试
│   │   └── temp/           # 临时测试文件
│   ├── debug/              # 调试相关
│   ├── tmp/                # 临时文件
│   ├── archive/            # 归档文件
│   └── docs/               # 文档
├── docker/                  # Docker 配置
├── data/                   # 数据存储
└── logs/                   # 日志文件
```

## 实施检查清单

system-architect 在执行职责时应检查：

- [ ] 所有生产代码目录中无临时文件
- [ ] 测试文件正确分类在 tests/ 目录
- [ ] 调试文件隔离在 debug/ 目录
- [ ] 临时文件集中在 tmp/ 目录
- [ ] 功能模块按职责清晰分组
- [ ] 命名规范一致性
- [ ] 无 mock 数据在生产配置中
- [ ] 默认配置指向真实服务

## 与其他 Agent 的协作

### 协作流程

1. **代码修改前**：system-architect 审查目录结构
2. **代码修改中**：相关 agent（如 go-code-maintainer）遵循结构规范
3. **代码修改后**：system-architect 清理临时文件
4. **测试完成后**：system-architect 归档测试产物

### 协作示例

```yaml
工作流:
  1. system-architect: 审查并规划目录结构
  2. go-code-maintainer: 在正确位置创建代码
  3. go-test-runner: 运行测试，生成临时文件
  4. system-architect: 清理和归档临时文件
```

## 监控和报告

system-architect 应定期生成报告：

```markdown
## 目录健康报告
- 临时文件数量: X
- 错误位置文件: Y
- 建议清理项: Z
- Mock 数据使用: 已禁用/已启用
```

---

**生效日期**: 2025-08-08
**维护者**: system-architect agent
**版本**: 1.0