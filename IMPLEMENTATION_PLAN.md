# 易诚融智 Chat UI - 账号密码登录系统实施计划

## 项目目标
将 chat-ui 从 OpenID Connect (OIDC) 认证系统改造为简单的账号密码登录系统，并添加用户管理功能。

## 技术栈
- **后端**: SvelteKit Server Routes
- **数据库**: MongoDB
- **密码加密**: bcryptjs
- **会话管理**: Cookie-based sessions
- **前端**: Svelte 5 + TypeScript

---

## 阶段 1: 数据模型修改

### 任务 1.1: 修改 User 类型定义
**文件**: `/src/lib/types/User.ts`

**当前结构**:
```typescript
export interface User extends Timestamps {
  _id: ObjectId;
  username?: string;
  name: string;
  email?: string;
  avatarUrl: string | undefined;
  hfUserId: string;  // OIDC 特定
  isAdmin?: boolean;
  isEarlyAccess?: boolean;
}
```

**修改为**:
```typescript
export interface User extends Timestamps {
  _id: ObjectId;
  username: string;           // 必填：登录用户名
  password: string;           // 新增：密码哈希
  nickname: string;           // 新增：显示昵称
  email: string;              // 必填：邮箱
  avatarUrl?: string;         // 可选：头像 URL
  isAdmin?: boolean;
  isEarlyAccess?: boolean;
}
```

**验证步骤**:
1. 确认所有引用 `User` 类型的文件
2. 移除 `hfUserId` 的所有使用
3. 将 `name` 改为 `nickname`

---

### 任务 1.2: 修改 Session 类型
**文件**: `/src/lib/types/Session.ts`

**修改**:
```typescript
export interface Session extends Timestamps {
  _id: ObjectId;
  sessionId: string;
  userId: User["_id"];
  userAgent?: string;
  ip?: string;
  expiresAt: Date;
  admin?: boolean;
  // 删除 oauth 相关字段
}
```

---

## 阶段 2: 认证核心逻辑

### 任务 2.1: 创建密码工具函数
**新建文件**: `/src/lib/server/password.ts`

```typescript
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 10;

/**
 * 哈希密码
 */
export async function hashPassword(password: string): Promise<string> {
  return await bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * 验证密码
 */
export async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  return await bcrypt.compare(password, hash);
}

/**
 * 验证密码强度
 * 至少8个字符，包含大小写字母和数字
 */
export function validatePasswordStrength(password: string): {
  valid: boolean;
  message?: string;
} {
  if (password.length < 8) {
    return { valid: false, message: '密码长度至少8个字符' };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: '密码必须包含小写字母' };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: '密码必须包含大写字母' };
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: '密码必须包含数字' };
  }
  return { valid: true };
}
```

**验证**:
- 运行单元测试确认密码哈希和验证正常工作

---

### 任务 2.2: 修改 auth.ts - 移除 OIDC
**文件**: `/src/lib/server/auth.ts`

**删除以下内容**:
- `OIDConfig` 相关配置 (第 41-55 行)
- `getOIDCClient()` 函数 (第 548-596 行)
- `getOIDCAuthorizationUrl()` 函数 (第 598-646 行)
- `getOIDCUserData()` 函数 (第 648-728 行)
- `triggerOauthFlow()` 函数 (第 505-546 行)
- 所有 OAuth 令牌刷新逻辑 (第 116-153 行)

**保留以下内容**:
- `refreshSessionCookie()` - 设置会话 Cookie
- `requiresUser()` - 验证用户必须登录
- `authenticateRequest()` - 验证请求（简化版本）

**新增函数**:
```typescript
/**
 * 创建新用户会话
 */
export async function createUserSession(
  userId: ObjectId,
  userAgent?: string,
  ip?: string
): Promise<string> {
  const sessionId = await sha256(crypto.randomUUID());
  const expiresAt = addWeeks(new Date(), 2);

  await collections.sessions.insertOne({
    _id: new ObjectId(),
    sessionId,
    userId,
    userAgent,
    ip,
    expiresAt,
    createdAt: new Date(),
    updatedAt: new Date(),
  });

  return sessionId;
}

/**
 * 通过用户名或邮箱查找用户
 */
export async function findUserByCredentials(
  usernameOrEmail: string
): Promise<User | null> {
  return await collections.users.findOne({
    $or: [{ username: usernameOrEmail }, { email: usernameOrEmail }],
  });
}
```

---

## 阶段 3: 注册功能

### 任务 3.1: 创建注册 API
**新建文件**: `/src/routes/register/+server.ts`

```typescript
import { json, error as svelteError } from '@sveltejs/kit';
import { collections } from '$lib/server/database';
import { hashPassword, validatePasswordStrength } from '$lib/server/password';
import { createUserSession, refreshSessionCookie } from '$lib/server/auth';
import { ObjectId } from 'mongodb';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, cookies, getClientAddress }) => {
  try {
    const { username, email, password, nickname } = await request.json();

    // 1. 验证输入
    if (!username || !email || !password) {
      throw svelteError(400, '用户名、邮箱和密码不能为空');
    }

    // 2. 验证密码强度
    const passwordValidation = validatePasswordStrength(password);
    if (!passwordValidation.valid) {
      throw svelteError(400, passwordValidation.message!);
    }

    // 3. 验证邮箱格式
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw svelteError(400, '邮箱格式不正确');
    }

    // 4. 检查用户名是否已存在
    const existingUser = await collections.users.findOne({ username });
    if (existingUser) {
      throw svelteError(409, '用户名已被使用');
    }

    // 5. 检查邮箱是否已存在
    const existingEmail = await collections.users.findOne({ email });
    if (existingEmail) {
      throw svelteError(409, '邮箱已被注册');
    }

    // 6. 创建新用户
    const passwordHash = await hashPassword(password);
    const newUser = {
      _id: new ObjectId(),
      username,
      password: passwordHash,
      nickname: nickname || username,
      email,
      avatarUrl: undefined,
      isAdmin: false,
      isEarlyAccess: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    await collections.users.insertOne(newUser);

    // 7. 创建会话
    const sessionId = await createUserSession(
      newUser._id,
      request.headers.get('user-agent') || undefined,
      getClientAddress()
    );

    // 8. 设置 Cookie
    refreshSessionCookie(cookies, sessionId);

    return json({
      success: true,
      user: {
        id: newUser._id.toString(),
        username: newUser.username,
        nickname: newUser.nickname,
        email: newUser.email,
      },
    });
  } catch (err: any) {
    if (err.status) throw err;
    console.error('注册错误:', err);
    throw svelteError(500, '注册失败，请稍后重试');
  }
};
```

**验证**:
1. 使用 curl 测试注册 API
2. 确认用户在数据库中正确创建
3. 确认密码已加密存储

---

### 任务 3.2: 创建注册页面
**新建文件**: `/src/routes/register/+page.svelte`

```svelte
<script lang="ts">
  import { goto } from '$app/navigation';
  import { base } from '$app/paths';

  let username = '';
  let email = '';
  let password = '';
  let nickname = '';
  let loading = false;
  let errorMessage = '';

  async function handleRegister() {
    if (!username || !email || !password) {
      errorMessage = '请填写所有必填项';
      return;
    }

    loading = true;
    errorMessage = '';

    try {
      const response = await fetch(`${base}/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, email, password, nickname }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || '注册失败');
      }

      // 注册成功，跳转到首页
      await goto(`${base}/`);
    } catch (err: any) {
      errorMessage = err.message;
    } finally {
      loading = false;
    }
  }
</script>

<div class="flex min-h-screen items-center justify-center bg-gray-50">
  <div class="w-full max-w-md space-y-8 rounded-lg bg-white p-8 shadow-md">
    <div>
      <h2 class="text-center text-3xl font-bold text-gray-900">
        注册易诚融智账号
      </h2>
      <p class="mt-2 text-center text-sm text-gray-600">
        已有账号？
        <a href="{base}/login" class="text-orange-600 hover:text-orange-500">
          立即登录
        </a>
      </p>
    </div>

    <form class="mt-8 space-y-6" on:submit|preventDefault={handleRegister}>
      {#if errorMessage}
        <div class="rounded-md bg-red-50 p-4">
          <p class="text-sm text-red-800">{errorMessage}</p>
        </div>
      {/if}

      <div class="space-y-4">
        <div>
          <label for="username" class="block text-sm font-medium text-gray-700">
            用户名 *
          </label>
          <input
            id="username"
            type="text"
            bind:value={username}
            required
            class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-orange-500 focus:outline-none focus:ring-orange-500"
            placeholder="输入用户名"
          />
        </div>

        <div>
          <label for="email" class="block text-sm font-medium text-gray-700">
            邮箱 *
          </label>
          <input
            id="email"
            type="email"
            bind:value={email}
            required
            class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-orange-500 focus:outline-none focus:ring-orange-500"
            placeholder="输入邮箱"
          />
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-gray-700">
            密码 *
          </label>
          <input
            id="password"
            type="password"
            bind:value={password}
            required
            class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-orange-500 focus:outline-none focus:ring-orange-500"
            placeholder="至少8位，包含大小写字母和数字"
          />
        </div>

        <div>
          <label for="nickname" class="block text-sm font-medium text-gray-700">
            昵称（可选）
          </label>
          <input
            id="nickname"
            type="text"
            bind:value={nickname}
            class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-orange-500 focus:outline-none focus:ring-orange-500"
            placeholder="不填则使用用户名"
          />
        </div>
      </div>

      <button
        type="submit"
        disabled={loading}
        class="w-full rounded-md bg-orange-600 px-4 py-2 text-white hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 disabled:opacity-50"
      >
        {loading ? '注册中...' : '注册'}
      </button>
    </form>
  </div>
</div>
```

---

## 阶段 4: 登录功能

### 任务 4.1: 创建登录 API
**新建文件**: `/src/routes/login/+server.ts`

```typescript
import { json, error as svelteError } from '@sveltejs/kit';
import { collections } from '$lib/server/database';
import { verifyPassword } from '$lib/server/password';
import { createUserSession, refreshSessionCookie } from '$lib/server/auth';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, cookies, getClientAddress }) => {
  try {
    const { usernameOrEmail, password } = await request.json();

    // 1. 验证输入
    if (!usernameOrEmail || !password) {
      throw svelteError(400, '用户名和密码不能为空');
    }

    // 2. 查找用户
    const user = await collections.users.findOne({
      $or: [{ username: usernameOrEmail }, { email: usernameOrEmail }],
    });

    if (!user) {
      throw svelteError(401, '用户名或密码错误');
    }

    // 3. 验证密码
    const isValidPassword = await verifyPassword(password, user.password);
    if (!isValidPassword) {
      throw svelteError(401, '用户名或密码错误');
    }

    // 4. 创建会话
    const sessionId = await createUserSession(
      user._id,
      request.headers.get('user-agent') || undefined,
      getClientAddress()
    );

    // 5. 设置 Cookie
    refreshSessionCookie(cookies, sessionId);

    return json({
      success: true,
      user: {
        id: user._id.toString(),
        username: user.username,
        nickname: user.nickname,
        email: user.email,
        avatarUrl: user.avatarUrl,
      },
    });
  } catch (err: any) {
    if (err.status) throw err;
    console.error('登录错误:', err);
    throw svelteError(500, '登录失败，请稍后重试');
  }
};
```

---

### 任务 4.2: 创建登录页面
**新建文件**: `/src/routes/login/+page.svelte`

```svelte
<script lang="ts">
  import { goto } from '$app/navigation';
  import { base } from '$app/paths';

  let usernameOrEmail = '';
  let password = '';
  let loading = false;
  let errorMessage = '';

  async function handleLogin() {
    if (!usernameOrEmail || !password) {
      errorMessage = '请输入用户名和密码';
      return;
    }

    loading = true;
    errorMessage = '';

    try {
      const response = await fetch(`${base}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ usernameOrEmail, password }),
      });

      if (!response.ok) {
        const data = await response.json();
        throw new Error(data.message || '登录失败');
      }

      // 登录成功，跳转到首页
      await goto(`${base}/`);
    } catch (err: any) {
      errorMessage = err.message;
    } finally {
      loading = false;
    }
  }
</script>

<div class="flex min-h-screen items-center justify-center bg-gray-50">
  <div class="w-full max-w-md space-y-8 rounded-lg bg-white p-8 shadow-md">
    <div>
      <h2 class="text-center text-3xl font-bold text-orange-600">
        登录易诚融智
      </h2>
      <p class="mt-2 text-center text-sm text-gray-600">
        基于先进大语言模型的智能对话系统
      </p>
    </div>

    <form class="mt-8 space-y-6" on:submit|preventDefault={handleLogin}>
      {#if errorMessage}
        <div class="rounded-md bg-red-50 p-4">
          <p class="text-sm text-red-800">{errorMessage}</p>
        </div>
      {/if}

      <div class="space-y-4">
        <div>
          <label for="usernameOrEmail" class="block text-sm font-medium text-gray-700">
            用户名或邮箱
          </label>
          <input
            id="usernameOrEmail"
            type="text"
            bind:value={usernameOrEmail}
            required
            class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-orange-500 focus:outline-none focus:ring-orange-500"
            placeholder="输入用户名或邮箱"
          />
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-gray-700">
            密码
          </label>
          <input
            id="password"
            type="password"
            bind:value={password}
            required
            class="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-orange-500 focus:outline-none focus:ring-orange-500"
            placeholder="输入密码"
          />
        </div>
      </div>

      <button
        type="submit"
        disabled={loading}
        class="w-full rounded-md bg-orange-600 px-4 py-2 text-white hover:bg-orange-700 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2 disabled:opacity-50"
      >
        {loading ? '登录中...' : '登录'}
      </button>

      <p class="text-center text-sm text-gray-600">
        还没有账号？
        <a href="{base}/register" class="text-orange-600 hover:text-orange-500">
          立即注册
        </a>
      </p>
    </form>
  </div>
</div>
```

---

## 阶段 5: 用户设置页面

### 任务 5.1: 创建用户设置 API
**新建文件**: `/src/routes/settings/profile/+server.ts`

```typescript
import { json, error as svelteError } from '@sveltejs/kit';
import { collections } from '$lib/server/database';
import type { RequestHandler } from './$types';

export const PATCH: RequestHandler = async ({ request, locals }) => {
  if (!locals.user) {
    throw svelteError(401, '请先登录');
  }

  try {
    const { nickname, avatarUrl } = await request.json();

    const updateFields: any = {};
    if (nickname) updateFields.nickname = nickname;
    if (avatarUrl !== undefined) updateFields.avatarUrl = avatarUrl;

    if (Object.keys(updateFields).length === 0) {
      throw svelteError(400, '没有需要更新的字段');
    }

    updateFields.updatedAt = new Date();

    await collections.users.updateOne(
      { _id: locals.user._id },
      { $set: updateFields }
    );

    return json({ success: true });
  } catch (err: any) {
    if (err.status) throw err;
    console.error('更新用户信息错误:', err);
    throw svelteError(500, '更新失败');
  }
};
```

---

### 任务 5.2: 创建用户设置页面
**新建文件**: `/src/routes/settings/profile/+page.svelte`

```svelte
<script lang="ts">
  import { page } from '$app/stores';
  import { base } from '$app/paths';

  let nickname = $page.data.user?.nickname || '';
  let avatarUrl = $page.data.user?.avatarUrl || '';
  let loading = false;
  let message = '';

  async function handleSave() {
    loading = true;
    message = '';

    try {
      const response = await fetch(`${base}/settings/profile`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nickname, avatarUrl }),
      });

      if (!response.ok) {
        throw new Error('更新失败');
      }

      message = '保存成功！';
      setTimeout(() => (message = ''), 3000);
    } catch (err: any) {
      message = err.message;
    } finally {
      loading = false;
    }
  }
</script>

<div class="container mx-auto max-w-2xl p-6">
  <h1 class="text-2xl font-bold mb-6">个人设置</h1>

  <form class="space-y-6" on:submit|preventDefault={handleSave}>
    {#if message}
      <div class="rounded-md bg-green-50 p-4">
        <p class="text-sm text-green-800">{message}</p>
      </div>
    {/if}

    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        昵称
      </label>
      <input
        type="text"
        bind:value={nickname}
        class="w-full rounded-md border border-gray-300 px-3 py-2"
        placeholder="输入昵称"
      />
    </div>

    <div>
      <label class="block text-sm font-medium text-gray-700 mb-2">
        头像URL
      </label>
      <input
        type="url"
        bind:value={avatarUrl}
        class="w-full rounded-md border border-gray-300 px-3 py-2"
        placeholder="输入头像URL"
      />
    </div>

    <button
      type="submit"
      disabled={loading}
      class="rounded-md bg-orange-600 px-4 py-2 text-white hover:bg-orange-700 disabled:opacity-50"
    >
      {loading ? '保存中...' : '保存'}
    </button>
  </form>
</div>
```

---

## 阶段 6: 修改全局拦截器

### 任务 6.1: 修改 hooks.server.ts
**文件**: `/src/hooks.server.ts`

**主要修改**:
1. 删除自动 OAuth 重定向逻辑（第 141-172 行）
2. 简化 `authenticateRequest()` 函数
3. 添加公开路由白名单
4. 未登录用户访问受保护页面时重定向到登录页

```typescript
// 公开路由（无需登录）
const PUBLIC_ROUTES = [
  '/login',
  '/register',
  '/api/health',  // 健康检查
];

function isPublicRoute(pathname: string): boolean {
  return PUBLIC_ROUTES.some(route => pathname.startsWith(`${base}${route}`));
}

export const handle: Handle = async ({ event, resolve }) => {
  // ... 现有代码 ...

  // 验证请求
  const user = await authenticateRequest(
    sessionId,
    event.request.headers.get('user-agent') || undefined
  );

  if (user) {
    event.locals.user = user;
  } else if (!isPublicRoute(event.url.pathname)) {
    // 未登录且访问受保护页面 -> 重定向到登录页
    return redirect(302, `${base}/login?next=${encodeURIComponent(event.url.pathname)}`);
  }

  return await resolve(event);
};
```

---

## 阶段 7: 修改 NavMenu 组件

### 任务 7.1: 添加用户菜单
**文件**: `/src/lib/components/NavMenu.svelte`

**修改**:
在用户信息显示区域添加下拉菜单：

```svelte
{#if $page.data.user}
  <div class="relative">
    <button
      on:click={() => showUserMenu = !showUserMenu}
      class="flex items-center gap-2"
    >
      {#if $page.data.user.avatarUrl}
        <img
          src={$page.data.user.avatarUrl}
          alt="头像"
          class="h-8 w-8 rounded-full"
        />
      {:else}
        <div class="h-8 w-8 rounded-full bg-orange-500 flex items-center justify-center text-white">
          {$page.data.user.nickname?.[0] || 'U'}
        </div>
      {/if}
      <span>{$page.data.user.nickname}</span>
    </button>

    {#if showUserMenu}
      <div class="absolute right-0 mt-2 w-48 rounded-md bg-white shadow-lg">
        <a href="{base}/settings/profile" class="block px-4 py-2 hover:bg-gray-100">
          个人设置
        </a>
        <form method="POST" action="{base}/logout">
          <button type="submit" class="w-full text-left px-4 py-2 hover:bg-gray-100">
            退出登录
          </button>
        </form>
      </div>
    {/if}
  </div>
{/if}
```

---

## 验证清单

### 功能测试
- [ ] 用户可以成功注册新账号
- [ ] 注册时密码强度验证正常工作
- [ ] 用户可以使用用户名或邮箱登录
- [ ] 登录后会话Cookie正确设置
- [ ] 用户可以修改昵称和头像
- [ ] 用户可以退出登录
- [ ] 未登录用户访问受保护页面会重定向到登录页
- [ ] 登录后自动跳转回原页面（next参数）

### 安全测试
- [ ] 密码在数据库中已加密存储
- [ ] 不存在SQL注入风险
- [ ] Cookie设置了HttpOnly和Secure标志
- [ ] 会话过期时间正确（2周）

### 数据库测试
- [ ] Users集合索引正确创建
- [ ] Sessions集合正常清理过期数据

---

## 部署说明

1. **环境变量更新**:
   - 移除所有OIDC相关变量
   - 确认MongoDB连接字符串正确

2. **数据库迁移**:
   - 如果有现有用户数据，需要运行迁移脚本
   - 为username和email字段添加索引

3. **启动服务**:
   ```bash
   npm run build
   npm run preview
   ```

---

## 文件清单

### 新建文件
- `/src/lib/server/password.ts` - 密码工具函数
- `/src/routes/register/+server.ts` - 注册API
- `/src/routes/register/+page.svelte` - 注册页面
- `/src/routes/login/+server.ts` - 登录API
- `/src/routes/login/+page.svelte` - 登录页面
- `/src/routes/settings/profile/+server.ts` - 用户设置API
- `/src/routes/settings/profile/+page.svelte` - 用户设置页面

### 修改文件
- `/src/lib/types/User.ts` - 用户类型定义
- `/src/lib/types/Session.ts` - 会话类型定义
- `/src/lib/server/auth.ts` - 认证核心逻辑
- `/src/hooks.server.ts` - 全局请求拦截器
- `/src/lib/components/NavMenu.svelte` - 导航菜单组件

### 删除文件
- `/src/routes/login/callback/+server.ts` - OIDC回调处理
- `/src/routes/login/callback/updateUser.ts` - OIDC用户更新

---

## 估算时间

- 阶段1-2: 2小时（数据模型和认证核心）
- 阶段3-4: 3小时（注册和登录功能）
- 阶段5-6: 2小时（用户设置和拦截器）
- 阶段7: 1小时（UI组件修改）
- 测试和调试: 2小时

**总计**: 约10小时

---

## 依赖包

```json
{
  "dependencies": {
    "bcryptjs": "^2.4.3"
  },
  "devDependencies": {
    "@types/bcryptjs": "^2.4.6"
  }
}
```
