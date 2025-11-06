#!/bin/bash

###############################################################################
# MongoDB 锁文件修复脚本
# 用于解决 "Unable to lock the lock file" 错误
###############################################################################

echo "🔧 修复 MongoDB 锁文件问题..."

# 停止所有服务
echo "1. 停止 PM2 服务..."
pm2 delete all 2>/dev/null || true

# 清理锁文件
echo "2. 清理锁文件..."
rm -f db/mongod.lock
rm -f db/*.lock 2>/dev/null || true

# 杀死可能残留的 mongod 进程
echo "3. 清理残留进程..."
pkill -9 mongod 2>/dev/null || true

# 重新启动
echo "4. 重新启动服务..."
pm2 start ecosystem.config.cjs

echo ""
echo "✅ 修复完成！"
echo ""
echo "查看服务状态:"
pm2 list
