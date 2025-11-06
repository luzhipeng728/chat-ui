import { json, type RequestHandler } from "@sveltejs/kit";
import { collections } from "$lib/server/database";
import { hashPassword } from "$lib/server/password";
import { z } from "zod";
import { ObjectId } from "mongodb";

const registerSchema = z.object({
	username: z.string().min(3).max(20),
	password: z.string().min(6).max(50),
	email: z.string().email(),
	nickname: z.string().min(1).max(50),
});

export const POST: RequestHandler = async ({ request }) => {
	try {
		const body = await request.json();
		const { username, password, email, nickname } = registerSchema.parse(body);

		// 检查用户名是否已存在
		const existingUser = await collections.users.findOne({ username });
		if (existingUser) {
			return json({ error: "用户名已存在" }, { status: 400 });
		}

		// 检查邮箱是否已存在
		const existingEmail = await collections.users.findOne({ email });
		if (existingEmail) {
			return json({ error: "邮箱已被注册" }, { status: 400 });
		}

		// 对密码进行哈希加密
		const passwordHash = await hashPassword(password);

		// 创建新用户
		const newUser = {
			_id: new ObjectId(),
			username,
			password: passwordHash,
			email,
			nickname,
			avatarUrl: undefined,
			createdAt: new Date(),
			updatedAt: new Date(),
		};

		await collections.users.insertOne(newUser);

		return json({
			success: true,
			message: "注册成功",
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

		console.error("注册失败:", error);
		return json({ error: "注册失败,请稍后再试" }, { status: 500 });
	}
};
