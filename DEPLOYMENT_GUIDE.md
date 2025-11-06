# 易诚融智 AI 系统 - 线上部署指南

## 前置要求
- Node.js v18+ 
- npm
- Git

## 部署步骤

### 1. 克隆代码
```bash
git clone https://github.com/luzhipeng728/chat-ui.git
cd chat-ui
```

### 2. 创建配置文件
```bash
cp .env.proxy.example .env.local
```

### 3. 编辑配置文件
```bash
vim .env.local  # 或使用 nano
```

**必须修改的配置项:**
```bash
UPSTREAM_API_KEY=你的真实API密钥
UPSTREAM_BASE_URL=https://ark.cn-beijing.volces.com/api/v3
PROXY_PORT=8090
```

### 4. 一键部署
```bash
chmod +x deploy.sh
./deploy.sh
```

部署脚本会自动:
- ✅ 检查并安装 Node.js、npm、PM2
- ✅ 安装项目依赖
- ✅ 创建必要目录 (db、logs)
- ✅ 验证环境配置
- ✅ 构建前端项目
- ✅ 启动前后端服务

### 5. 验证部署
```bash
# 检查服务状态
pm2 list

# 查看日志
pm2 logs

# 测试访问
curl http://localhost:3000
```

## 访问地址
- **本地访问**: http://localhost:3000
- **外网访问**: http://你的服务器IP:3000

## 常用命令
```bash
# 重启服务
pm2 restart all

# 停止服务
pm2 stop all

# 查看日志
pm2 logs ynet-frontend  # 前端日志
pm2 logs ynet-proxy     # 后端日志

# 查看监控
pm2 monit
```

## 安全提示
⚠️ **重要**: 
- `.env.local` 文件包含 API 密钥,已添加到 `.gitignore`
- 生产环境建议配置防火墙,只开放必要端口
- 后端代理仅监听 127.0.0.1:8090 (内网)
- 前端服务监听 0.0.0.0:3000 (公网可访问)

## 故障排查
如果遇到问题:
```bash
# 查看详细日志
tail -f logs/frontend-error.log
tail -f logs/proxy-error.log

# 重新部署
pm2 delete all
./deploy.sh
```

## 文件清单
**需要复制到服务器的文件:**
- ✅ 整个项目目录 (通过 git clone 获取)
- ✅ `.env.local` (需要手动创建并配置)

**不需要复制:**
- ❌ `node_modules/` (部署脚本会自动安装)
- ❌ `.env.local` (包含密钥,不应提交到仓库)
- ❌ `ecosystem.config.cjs` (部署脚本会自动生成)
- ❌ `db/` 和 `logs/` (自动创建)
