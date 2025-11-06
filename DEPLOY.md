# 易诚融智 AI 系统部署指南

## 🚀 一键部署

### 1. 快速开始

```bash
# 执行部署脚本
./deploy.sh
```

就这么简单! 脚本会自动完成:
- ✅ 检查 Node.js 和 npm
- ✅ 自动安装 PM2(如果未安装)
- ✅ 检查并安装项目依赖
- ✅ 构建前端项目
- ✅ 启动后端代理服务(端口 8090,仅内网访问)
- ✅ 启动前端服务(端口 3000,对外开放)
- ✅ 配置 PM2 自动重启

### 2. 访问地址

部署成功后:
- **本地访问**: http://localhost:3000
- **外网访问**: http://YOUR_SERVER_IP:3000

### 3. 服务管理

```bash
# 查看服务状态
pm2 status

# 查看实时日志
pm2 logs

# 查看后端日志
pm2 logs ynet-proxy

# 查看前端日志
pm2 logs ynet-frontend

# 重启所有服务
pm2 restart all

# 停止所有服务
pm2 stop all

# 删除所有服务
pm2 delete all

# 实时监控
pm2 monit
```

## 📝 系统架构

```
外网用户
    ↓
[前端服务:3000] (对外开放,监听 0.0.0.0)
    ↓ (内网访问)
[后端代理:8090] (仅监听 127.0.0.1)
    ↓
[豆包API] (上游服务)
```

### 关键设计:
1. **后端代理仅监听 127.0.0.1** - 外网无法直接访问
2. **前端服务对外开放 0.0.0.0** - 可从外网访问
3. **前端通过内网 127.0.0.1:8090 访问后端** - 无跨域问题
4. **所有外部请求都经过前端服务** - 统一入口

## 🔧 手动部署(高级)

如果需要手动部署或自定义配置:

### 1. 安装依赖
```bash
npm install
```

### 2. 安装 PM2(如果未安装)
```bash
npm install -g pm2
```

### 3. 构建前端
```bash
npm run build
```

### 4. 启动后端代理
```bash
pm2 start doubao-proxy.cjs --name ynet-proxy
```

### 5. 启动前端服务
```bash
pm2 start npm --name ynet-frontend -- run start
```

### 6. 保存进程列表
```bash
pm2 save
pm2 startup
```

## 🔒 安全说明

1. **后端代理安全**:
   - 仅监听 127.0.0.1,外网无法访问
   - API Key 不会暴露给前端用户

2. **前端服务**:
   - 所有 API 请求在服务端完成
   - 用户只能访问前端界面和 API 路由

3. **防火墙建议**:
   ```bash
   # 只开放前端端口 3000
   ufw allow 3000

   # 后端端口 8090 不要开放
   # ufw deny 8090  (默认已拒绝)
   ```

## 📊 日志位置

- **后端日志**: `logs/proxy.log`
- **后端错误日志**: `logs/proxy-error.log`
- **前端日志**: `logs/frontend.log`
- **前端错误日志**: `logs/frontend-error.log`

## 🛠️ 故障排查

### 问题1: 端口被占用
```bash
# 查看端口占用
lsof -i:3000
lsof -i:8090

# 停止占用端口的进程
pm2 delete all
```

### 问题2: 前端无法访问后端
```bash
# 检查后端代理是否运行
pm2 logs ynet-proxy

# 测试后端连接
curl http://127.0.0.1:8090/models
```

### 问题3: 依赖安装失败
```bash
# 清除缓存重新安装
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### 问题4: 构建失败
```bash
# 检查 Node.js 版本(需要 v18+)
node -v

# 清理构建缓存
rm -rf .svelte-kit build
npm run build
```

## 🔄 更新部署

代码更新后重新部署:

```bash
# 方式1: 重新运行部署脚本
./deploy.sh

# 方式2: 手动更新
git pull
npm install
npm run build
pm2 restart all
```

## 📞 技术支持

如有问题,请联系技术团队。
