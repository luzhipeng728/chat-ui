import { json, type RequestHandler } from "@sveltejs/kit";
import { collections } from "$lib/server/database";
import { verifyPassword } from "$lib/server/password";
import { refreshSessionCookie } from "$lib/server/auth";
import { sha256 } from "$lib/utils/sha256";
import { z } from "zod";

const loginSchema = z.object({
	username: z.string(),
	password: z.string(),
});

export const POST: RequestHandler = async ({ request, cookies }) => {
	try {
		const body = await request.json();
		const { username, password } = loginSchema.parse(body);

		// 查找用户
		const user = await collections.users.findOne({ username });
		if (!user) {
			return json({ error: "用户名或密码错误" }, { status: 401 });
		}

		// 验证密码
		const isValid = await verifyPassword(password, user.password);
		if (!isValid) {
			return json({ error: "用户名或密码错误" }, { status: 401 });
		}

		// 生成新的session ID
		const secretSessionId = crypto.randomUUID();
		const sessionId = await sha256(secretSessionId);

		// 创建session
		await collections.sessions.insertOne({
			sessionId,
			userId: user._id,
			createdAt: new Date(),
			updatedAt: new Date(),
		});

		// 设置cookie
		refreshSessionCookie(cookies, secretSessionId);

		return json({
			success: true,
			user: {
				_id: user._id.toString(),
				username: user.username,
				nickname: user.nickname,
				email: user.email,
				avatarUrl: user.avatarUrl,
			},
		});
	} catch (error) {
		if (error instanceof z.ZodError) {
			return json(
				{
					error: "输入验证失败",
					details: error.errors,
				},
				{ status: 400 }
			);
		}

		console.error("登录失败:", error);
		return json({ error: "登录失败,请稍后再试" }, { status: 500 });
	}
};
