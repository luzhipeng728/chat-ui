#!/bin/bash
# 快速重启脚本

echo "🔄 重启易诚融智 AI 服务..."

pm2 restart ynet-proxy ynet-frontend

echo "✅ 服务已重启"
pm2 list
