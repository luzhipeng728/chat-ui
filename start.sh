#!/bin/bash
# 快速启动脚本

echo "🚀 启动易诚融智 AI 服务..."

# 启动后端代理
pm2 start doubao-proxy.cjs --name ynet-proxy 2>/dev/null || pm2 restart ynet-proxy

# 启动前端服务
pm2 start npm --name ynet-frontend -- run start 2>/dev/null || pm2 restart ynet-frontend

echo "✅ 服务已启动"
pm2 list
