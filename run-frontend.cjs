#!/usr/bin/env node

/**
 * 前端服务启动包装器
 * 解决 MongoMemoryServer 在 ES 模块中 __dirname 未定义的问题
 */

// 设置环境变量
process.env.NODE_ENV = process.env.NODE_ENV || 'production';

// 为 ES 模块环境提供 __dirname 和 __filename
global.__dirname = __dirname;
global.__filename = __filename;

// 导入并运行前端服务器
import('./build/index.js').catch((err) => {
	console.error('前端服务启动失败:', err);
	process.exit(1);
});
