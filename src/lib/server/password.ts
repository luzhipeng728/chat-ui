import bcrypt from "bcryptjs";

const SALT_ROUNDS = 10;

/**
 * 对密码进行哈希加密
 * @param password 明文密码
 * @returns 哈希后的密码
 */
export async function hashPassword(password: string): Promise<string> {
	return bcrypt.hash(password, SALT_ROUNDS);
}

/**
 * 验证密码是否匹配
 * @param password 明文密码
 * @param hash 哈希值
 * @returns 是否匹配
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
	return bcrypt.compare(password, hash);
}
