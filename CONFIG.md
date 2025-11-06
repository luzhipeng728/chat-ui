# 易诚融智 AI - 配置指南

## 📝 必需配置文件

### 1. 后端代理配置 (`.env.local`)

**作用**: 配置后端代理服务的 API Key 和其他敏感信息

**创建步骤**:
```bash
# 复制示例文件
cp .env.proxy.example .env.local

# 编辑配置文件
vim .env.local  # 或使用其他编辑器
```

**必需配置项**:
```bash
# 豆包 API Key (必需)
UPSTREAM_API_KEY=fa89fd52-9fa3-4be7-bd36-5aa08000ece7

# 上游 API 地址 (可选,默认为豆包)
UPSTREAM_BASE_URL=https://ark.cn-beijing.volces.com/api/v3

# 代理服务端口 (可选,默认 8090)
PROXY_PORT=8090
```

### 2. 前端环境配置 (`.env.production`)

**作用**: 配置前端应用的环境变量

**已包含在代码库中**,默认配置:
```bash
# AI Model Configuration - 使用内网地址访问后端代理
OPENAI_BASE_URL=http://127.0.0.1:8090
OPENAI_API_KEY=yichengrongzhi-internal

# MongoDB Configuration (本地文件存储)
MONGODB_URL=
MONGO_STORAGE_PATH=./db

# App Configuration
PUBLIC_APP_NAME=易诚融智
PUBLIC_APP_DESCRIPTION=基于先进大语言模型的智能对话系统

# Feature Flags
LLM_SUMMARIZATION=true
ENABLE_DATA_EXPORT=true
ALLOW_IFRAME=true
ENABLE_CONFIG_MANAGER=true

# Rate Limits
USAGE_LIMITS={"conversations": 100, "messages": 100, "messageLength": 10000, "messagesPerMinute": 10}

# Production Settings
LOG_LEVEL=info
NODE_ENV=production

# 服务器配置
ORIGIN=http://localhost:3000
HOST=0.0.0.0
PORT=3000
```

---

## 🚀 快速开始

### 步骤1: 创建配置文件

```bash
# 复制示例配置
cp .env.proxy.example .env.local

# 编辑并填入真实的 API Key
vim .env.local
```

### 步骤2: 运行部署脚本

```bash
./deploy.sh
```

部署脚本会自动:
- 检查配置文件
- 安装依赖
- 构建项目
- 启动服务

---

## 📂 配置文件说明

### 配置文件列表

| 文件 | 用途 | 是否提交到Git | 说明 |
|------|------|---------------|------|
| `.env.proxy.example` | 配置示例 | ✅ 提交 | 示例配置,不含敏感信息 |
| `.env.local` | 后端代理配置 | ❌ 不提交 | 包含API Key,不提交到代码库 |
| `.env.production` | 前端生产配置 | ✅ 提交 | 不含敏感信息,可以提交 |

### 为什么`.env.local`不提交?

`.env.local` 包含敏感的 API Key,提交到代码库会导致安全风险。每个环境需要各自配置。

---

## 🔐 密码配置 (可选)

如果需要修改默认密码,编辑 `src/lib/server/password.ts`:

```typescript
export const USERS = [
  {
    username: 'admin',
    password: 'your-new-password',  // 修改为你的密码
    displayName: '管理员',
    email: 'admin@example.com'
  }
];
```

**注意**: 修改密码后需要重新构建和部署:
```bash
npm run build
pm2 restart all
```

---

## 🌐 域名和端口配置

### 修改端口

**后端端口 (默认8090)**:
编辑 `.env.local`:
```bash
PROXY_PORT=8090  # 改为你需要的端口
```

**前端端口 (默认3000)**:
编辑 `.env.production`:
```bash
PORT=3000  # 改为你需要的端口
```

### 配置域名

如果使用域名访问,修改 `.env.production`:
```bash
ORIGIN=https://your-domain.com
HOST=0.0.0.0
PORT=3000
```

---

## 📊 数据库配置

默认使用本地文件存储 (`./db` 目录)。

如果需要使用 MongoDB:
1. 编辑 `.env.production`
2. 设置 `MONGODB_URL`:
```bash
MONGODB_URL=mongodb://localhost:27017/chat-ui
```

---

## 🔄 配置修改后重启

修改配置后需要重启服务:

```bash
# 重启所有服务
pm2 restart all

# 或使用快捷脚本
./restart.sh
```

---

## 🛡️ 安全建议

1. **不要提交 `.env.local`**: 确保 `.gitignore` 中包含 `.env.local`
2. **定期更换 API Key**: 定期更新豆包 API Key
3. **使用强密码**: 修改默认管理员密码
4. **配置防火墙**: 只开放必要端口(3000)
5. **使用 HTTPS**: 生产环境建议配置 SSL 证书

---

## 📝 配置检查清单

部署前检查:
- [ ] 创建 `.env.local` 文件
- [ ] 配置 `UPSTREAM_API_KEY`
- [ ] 修改默认管理员密码(可选)
- [ ] 检查端口是否被占用
- [ ] 确认防火墙规则
- [ ] 测试服务是否正常启动

---

## 💡 常见问题

### Q: 忘记配置 `.env.local` 会怎样?
A: 部署脚本会检测并提示错误,不会启动服务。

### Q: 可以使用其他 AI 提供商吗?
A: 可以,修改 `.env.local` 中的 `UPSTREAM_BASE_URL` 和 `UPSTREAM_API_KEY`。

### Q: 如何查看当前配置?
A: 查看日志: `pm2 logs ynet-proxy`

---

## 📞 技术支持

配置相关问题请参考:
- 部署文档: `DEPLOY.md`
- 快速开始: `README_DEPLOY.md`
