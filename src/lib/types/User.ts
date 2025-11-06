import type { ObjectId } from "mongodb";
import type { Timestamps } from "./Timestamps";

export interface User extends Timestamps {
	_id: ObjectId;

	username: string; // 必填: 登录用户名
	password: string; // 新增: 密码哈希值
	nickname: string; // 新增: 显示昵称
	email: string; // 必填: 邮箱
	avatarUrl?: string; // 可选: 头像URL
	isAdmin?: boolean;
	isEarlyAccess?: boolean;
}
