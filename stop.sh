#!/bin/bash
# 快速停止脚本

echo "🛑 停止易诚融智 AI 服务..."

pm2 stop ynet-proxy ynet-frontend

echo "✅ 服务已停止"
pm2 list
