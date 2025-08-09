#!/bin/bash

# FinancialStreamsJ Docker 启动脚本
# 使用 env_for_docker 配置文件启动所有服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 和 Docker Compose
check_dependencies() {
    print_info "检查依赖..."
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
        print_error "Docker Compose 未安装或不支持"
        exit 1
    fi
    
    print_info "依赖检查通过"
}

# 检查配置文件
check_config() {
    print_info "检查配置文件..."
    
    if [ ! -f "env_for_docker" ]; then
        print_error "env_for_docker 配置文件不存在"
        exit 1
    fi
    
    print_info "配置文件检查通过"
}

# 停止现有服务
stop_services() {
    print_info "停止现有服务..."
    docker compose --env-file env_for_docker down || true
}

# 构建镜像
build_images() {
    print_info "构建 Docker 镜像..."
    docker compose --env-file env_for_docker build
}

# 启动服务
start_services() {
    print_info "启动服务..."
    docker compose --env-file env_for_docker up -d
    
    print_info "等待服务健康检查..."
    sleep 10
    
    # 检查服务状态
    docker compose --env-file env_for_docker ps
}

# 显示日志
show_logs() {
    print_info "显示最近的日志..."
    docker compose --env-file env_for_docker logs --tail=20
}

# 主函数
main() {
    print_info "========================================="
    print_info "FinancialStreamsJ Docker 启动"
    print_info "========================================="
    
    check_dependencies
    check_config
    
    # 解析命令行参数
    case "${1:-}" in
        --build)
            print_info "强制重新构建镜像"
            stop_services
            build_images
            start_services
            ;;
        --restart)
            print_info "重启服务"
            stop_services
            start_services
            ;;
        --logs)
            show_logs
            exit 0
            ;;
        --stop)
            stop_services
            exit 0
            ;;
        *)
            # 默认行为：构建并启动
            stop_services
            build_images
            start_services
            ;;
    esac
    
    print_info "========================================="
    print_info "服务启动完成！"
    print_info "========================================="
    print_info "RabbitMQ 管理界面: http://localhost:15672"
    print_info "ClickHouse HTTP: http://localhost:8123"
    print_info ""
    print_info "查看日志: ./docker-start.sh --logs"
    print_info "停止服务: ./docker-start.sh --stop"
    print_info "重启服务: ./docker-start.sh --restart"
}

# 运行主函数
main "$@"