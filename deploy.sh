#!/bin/bash

###############################################################################
# 易诚融智 AI 一键部署脚本
# 功能: 自动安装依赖、构建项目、使用 PM2 启动服务
###############################################################################

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印标题
print_header() {
    echo ""
    echo "=========================================="
    echo "  易诚融智 AI 系统部署"
    echo "  Ynet NexMind Deployment"
    echo "=========================================="
    echo ""
}

print_header

# 1. 检查 Node.js 和 npm
log_info "检查 Node.js 和 npm..."
if ! command -v node &> /dev/null; then
    log_error "未找到 Node.js，请先安装 Node.js (推荐 v18+)"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    log_error "未找到 npm，请先安装 npm"
    exit 1
fi

NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)
log_success "Node.js 版本: $NODE_VERSION"
log_success "npm 版本: $NPM_VERSION"

# 2. 检查并安装 PM2
log_info "检查 PM2..."
if ! command -v pm2 &> /dev/null; then
    log_warning "未找到 PM2，正在安装..."
    npm install -g pm2
    log_success "PM2 安装完成"
else
    PM2_VERSION=$(pm2 -v)
    log_success "PM2 已安装，版本: $PM2_VERSION"
fi

# 3. 检查并安装项目依赖
log_info "检查项目依赖..."
if [ ! -d "node_modules" ]; then
    log_warning "未找到 node_modules，正在安装依赖..."
    npm install
    log_success "依赖安装完成"
else
    log_info "检查依赖是否需要更新..."
    npm install
    log_success "依赖检查完成"
fi

# 4. 创建必要的目录
log_info "创建必要的目录..."
mkdir -p db
mkdir -p logs
log_success "目录创建完成"

# 5. 检查环境配置文件
log_info "检查环境配置..."
if [ ! -f ".env.local" ]; then
    log_error "未找到 .env.local 配置文件"
    log_error "请复制 .env.proxy.example 为 .env.local 并填入真实配置"
    log_error ""
    log_error "执行: cp .env.proxy.example .env.local"
    log_error "然后编辑 .env.local 填入 UPSTREAM_API_KEY"
    exit 1
fi

# 检查是否配置了API Key
if ! grep -q "UPSTREAM_API_KEY=" .env.local || grep -q "UPSTREAM_API_KEY=your-" .env.local; then
    log_error "未配置 UPSTREAM_API_KEY"
    log_error "请在 .env.local 中设置真实的 API Key"
    exit 1
fi

log_success "环境配置检查完成"

# 6. 停止旧的服务(如果存在)
log_info "停止旧的服务..."
pm2 delete ynet-proxy 2>/dev/null || true
pm2 delete ynet-frontend 2>/dev/null || true
log_success "旧服务已停止"

# 7. 临时启动后端代理服务用于构建
log_info "临时启动后端代理服务用于构建..."
# 加载环境变量
export $(grep -v '^#' .env.local | xargs)
# 后台启动
node doubao-proxy.cjs > logs/proxy-build.log 2>&1 &
PROXY_PID=$!
log_success "后端代理服务已临时启动 (PID: $PROXY_PID)"

# 等待服务启动
sleep 2

# 8. 构建前端项目
log_info "构建前端项目..."
npm run build
BUILD_STATUS=$?

# 停止临时的后端代理
kill $PROXY_PID 2>/dev/null || true
sleep 1

if [ $BUILD_STATUS -ne 0 ]; then
    log_error "前端构建失败"
    exit 1
fi
log_success "前端构建完成"

# 9. 启动后端代理服务 (仅监听 localhost)
log_info "启动后端代理服务 (端口: 8090)..."

# 创建 PM2 生态系统配置文件
cat > ecosystem.config.cjs <<EOF
module.exports = {
  apps: [
    {
      name: 'ynet-proxy',
      script: './doubao-proxy.cjs',
      env: {
        NODE_ENV: 'production',
        UPSTREAM_API_KEY: '$(grep UPSTREAM_API_KEY .env.local | cut -d= -f2)',
        UPSTREAM_BASE_URL: '$(grep UPSTREAM_BASE_URL .env.local | cut -d= -f2)',
        PROXY_PORT: '$(grep PROXY_PORT .env.local | cut -d= -f2 || echo 8090)'
      },
      log_file: './logs/proxy.log',
      error_file: './logs/proxy-error.log',
      out_file: './logs/proxy-out.log',
      time: true
    },
    {
      name: 'ynet-frontend',
      script: './run-frontend.cjs',
      env: {
        NODE_ENV: 'production',
        ORIGIN: 'http://localhost:3000',
        HOST: '0.0.0.0',
        PORT: '3000',
        OPENAI_BASE_URL: 'http://127.0.0.1:8090',
        OPENAI_API_KEY: 'yichengrongzhi-internal',
        MONGODB_URL: '',
        MONGODB_DB_NAME: 'chat-ui',
        MONGODB_DIRECT_CONNECTION: 'false',
        MONGO_STORAGE_PATH: './db',
        PUBLIC_APP_NAME: '易诚融智',
        PUBLIC_APP_ASSETS: 'chatui',
        PUBLIC_APP_DESCRIPTION: "Making the community's best AI chat models available to everyone.",
        COOKIE_NAME: 'hf-chat',
        COUPLE_SESSION_WITH_COOKIE_NAME: '',
        COOKIE_SAMESITE: 'lax',
        COOKIE_SECURE: 'false'
      },
      log_file: './logs/frontend.log',
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      time: true
    }
  ]
};
EOF

pm2 start ecosystem.config.cjs
log_success "前后端服务已启动"

# 10. 保存 PM2 进程列表
log_info "保存 PM2 进程列表..."
pm2 save
log_success "PM2 进程列表已保存"

# 11. 设置 PM2 开机自启(可选)
log_info "配置 PM2 开机自启..."
pm2 startup 2>/dev/null || log_warning "PM2 开机自启配置失败，可能需要 root 权限"

# 12. 显示服务状态
echo ""
log_success "=========================================="
log_success "  部署完成！"
log_success "=========================================="
echo ""
log_info "服务状态:"
pm2 list
echo ""
log_info "访问地址:"
echo "  • 前端页面: http://localhost:3000"
echo "  • 前端页面 (外网): http://YOUR_SERVER_IP:3000"
echo ""
log_info "查看日志:"
echo "  • 后端日志: pm2 logs ynet-proxy"
echo "  • 前端日志: pm2 logs ynet-frontend"
echo "  • 所有日志: pm2 logs"
echo ""
log_info "常用命令:"
echo "  • 重启服务: pm2 restart all"
echo "  • 停止服务: pm2 stop all"
echo "  • 删除服务: pm2 delete all"
echo "  • 查看状态: pm2 status"
echo "  • 查看监控: pm2 monit"
echo ""
log_success "部署脚本执行完成! 🎉"
