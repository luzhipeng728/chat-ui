#!/bin/bash
# 快速启动脚本

echo "🚀 启动易诚融智 AI 服务..."

# 检查 ecosystem 配置文件是否存在
if [ ! -f "ecosystem.config.cjs" ]; then
    echo "❌ 错误: ecosystem.config.cjs 不存在"
    echo "请先运行 ./deploy.sh 完成初始部署"
    exit 1
fi

# 启动所有服务
pm2 start ecosystem.config.cjs 2>/dev/null || pm2 restart ecosystem.config.cjs

echo "✅ 服务已启动"
pm2 list
