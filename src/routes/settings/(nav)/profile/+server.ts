import { json, type RequestHandler } from "@sveltejs/kit";
import { collections } from "$lib/server/database";
import { z } from "zod";

const updateProfileSchema = z.object({
	nickname: z.string().min(1).max(50).optional(),
	avatarUrl: z.string().url().optional().or(z.literal("")),
});

export const POST: RequestHandler = async ({ request, locals }) => {
	if (!locals.user) {
		return json({ error: "未登录" }, { status: 401 });
	}

	try {
		const body = await request.json();
		const updates = updateProfileSchema.parse(body);

		// 构建更新对象
		const updateFields: Record<string, unknown> = {
			updatedAt: new Date(),
		};

		if (updates.nickname !== undefined) {
			updateFields.nickname = updates.nickname;
		}

		if (updates.avatarUrl !== undefined) {
			updateFields.avatarUrl = updates.avatarUrl || undefined;
		}

		// 更新用户信息
		await collections.users.updateOne({ _id: locals.user._id }, { $set: updateFields });

		// 获取更新后的用户信息
		const updatedUser = await collections.users.findOne({ _id: locals.user._id });

		return json({
			success: true,
			user: {
				_id: updatedUser?._id.toString(),
				username: updatedUser?.username,
				nickname: updatedUser?.nickname,
				email: updatedUser?.email,
				avatarUrl: updatedUser?.avatarUrl,
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

		console.error("更新用户信息失败:", error);
		return json({ error: "更新失败,请稍后再试" }, { status: 500 });
	}
};
