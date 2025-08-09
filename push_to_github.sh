#!/bin/bash

# GitHub 推送脚本
# 使用前请先确保 GitHub CLI 已认证

set -e

echo "========================================="
echo "推送 FinancialStreamsJ 到 GitHub"
echo "========================================="

# 检查是否已经认证
if ! gh auth status &>/dev/null; then
    echo "❌ 请先运行 'gh auth login' 进行 GitHub 认证"
    exit 1
fi

# 创建远程仓库（如果不存在）
echo "📦 创建 GitHub 私有仓库..."
if gh repo create FinancialStreamsJ --private --description "Crypto data processing system with RabbitMQ and ClickHouse" 2>/dev/null; then
    echo "✅ 仓库创建成功"
else
    echo "ℹ️ 仓库可能已存在，继续..."
fi

# 添加远程仓库
echo "🔗 配置远程仓库..."
if git remote | grep -q origin; then
    git remote set-url origin https://github.com/zhangmjcn/FinancialStreamsJ.git
else
    git remote add origin https://github.com/zhangmjcn/FinancialStreamsJ.git
fi

# 推送到远程
echo "🚀 推送代码到 GitHub..."
git push -u origin main

echo "========================================="
echo "✅ 推送完成！"
echo "========================================="
echo "仓库地址: https://github.com/zhangmjcn/FinancialStreamsJ"
echo "设置为私有仓库"