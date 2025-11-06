import { page } from "$app/state";

/**
 * 检查用户是否已登录
 * @returns true表示需要登录(未登录), false表示已登录
 */
export function requireAuthUser(): boolean {
	// 检查是否未登录
	return !page.data.user;
}
