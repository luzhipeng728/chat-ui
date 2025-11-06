# 易诚融智 AI - 快速部署指南

## 🎯 最简单的部署方式

### 一键部署

```bash
./deploy.sh
```

**就这么简单!** 脚本会自动完成所有配置和部署工作。

---

## 📋 部署后管理

### 快捷命令

```bash
# 启动服务
./start.sh

# 停止服务
./stop.sh

# 重启服务
./restart.sh

# 查看状态
pm2 status

# 查看日志
pm2 logs
```

---

## 🌐 访问地址

部署成功后,访问以下地址:

- **本地**: http://localhost:3000
- **外网**: http://YOUR_SERVER_IP:3000

---

## 🏗️ 系统架构

```
                     外网用户
                        ↓
              ┌─────────────────┐
              │   前端服务:3000   │  ← 对外开放 (0.0.0.0)
              └─────────────────┘
                        ↓ (内网 127.0.0.1:8090)
              ┌─────────────────┐
              │  后端代理:8090   │  ← 仅内网访问
              └─────────────────┘
                        ↓
              ┌─────────────────┐
              │    豆包 API      │
              └─────────────────┘
```

### 关键特性:
✅ **前端对外开放** - 外网可访问
✅ **后端仅内网** - 安全隔离
✅ **无跨域问题** - 前端服务端访问后端
✅ **API Key 隐藏** - 不暴露给用户

---

## 🔧 系统要求

- **Node.js**: v18.0.0 或更高版本
- **npm**: v8.0.0 或更高版本
- **内存**: 至少 1GB 可用内存
- **磁盘**: 至少 500MB 可用空间

---

## 📊 PM2 常用命令

```bash
# 查看所有进程
pm2 list

# 查看实时日志
pm2 logs

# 查看某个服务的日志
pm2 logs ynet-proxy
pm2 logs ynet-frontend

# 实时监控
pm2 monit

# 重启所有服务
pm2 restart all

# 停止所有服务
pm2 stop all

# 删除所有服务
pm2 delete all

# 保存进程列表
pm2 save

# 查看详细信息
pm2 show ynet-proxy
```

---

## 🔒 安全配置

### 防火墙设置(推荐)

```bash
# Ubuntu/Debian
sudo ufw allow 3000/tcp
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

**注意**: 不要开放 8090 端口,保持后端代理仅内网访问!

---

## 🛠️ 故障排查

### 问题1: 命令未找到
```bash
# 安装 PM2
npm install -g pm2

# 检查 PATH
echo $PATH
```

### 问题2: 端口被占用
```bash
# 查看端口占用
lsof -i:3000
lsof -i:8090

# 停止服务后重新部署
pm2 delete all
./deploy.sh
```

### 问题3: 服务无法访问
```bash
# 检查服务状态
pm2 status

# 查看日志查找错误
pm2 logs

# 重启服务
./restart.sh
```

### 问题4: 构建失败
```bash
# 清理并重新构建
rm -rf node_modules .svelte-kit build
npm install
npm run build
```

---

## 📝 日志位置

- **后端日志**: `logs/proxy.log`
- **后端错误**: `logs/proxy-error.log`
- **前端日志**: `logs/frontend.log`
- **前端错误**: `logs/frontend-error.log`

---

## 🔄 代码更新

当代码更新后:

```bash
# 拉取最新代码
git pull

# 重新部署
./deploy.sh
```

---

## 📞 技术支持

**详细文档**: 查看 `DEPLOY.md` 获取完整部署文档

**常见问题**:
- 端口配置问题
- 跨域问题
- PM2 进程管理
- 日志查看方法

如有其他问题,请联系技术团队。

---

## 🎉 快速开始示例

```bash
# 1. 克隆项目
git clone <your-repo-url>
cd chat-ui

# 2. 一键部署
./deploy.sh

# 3. 等待部署完成后访问
# http://localhost:3000

# 完成! 🎊
```
