<script lang="ts">
	import { base } from "$app/paths";
	import { page } from "$app/state";

	let { data } = $props();

	let nickname = $state(data.user?.nickname || "");
	let avatarUrl = $state(data.user?.avatarUrl || "");
	let error = $state("");
	let success = $state("");
	let loading = $state(false);

	async function handleSubmit() {
		if (!nickname.trim()) {
			error = "昵称不能为空";
			return;
		}

		loading = true;
		error = "";
		success = "";

		try {
			const res = await fetch(`${base}/settings/profile`, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					nickname: nickname.trim(),
					avatarUrl: avatarUrl.trim() || "",
				}),
			});

			const result = await res.json();

			if (!res.ok) {
				error = result.error || "更新失败";
				loading = false;
				return;
			}

			success = "更新成功!";
			loading = false;
		} catch (err) {
			error = "网络错误,请稍后再试";
			loading = false;
		}
	}
</script>

<div class="flex flex-col gap-6">
	<div>
		<h2 class="text-xl font-bold text-gray-900 dark:text-gray-100">
			个人资料
		</h2>
		<p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
			更新您的个人信息
		</p>
	</div>

	{#if error}
		<div class="rounded-lg bg-red-50 dark:bg-red-900/20 p-3 text-sm text-red-600 dark:text-red-400">
			{error}
		</div>
	{/if}

	{#if success}
		<div class="rounded-lg bg-green-50 dark:bg-green-900/20 p-3 text-sm text-green-600 dark:text-green-400">
			{success}
		</div>
	{/if}

	<div class="space-y-6">
		<div>
			<label for="username" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
				用户名
			</label>
			<input
				id="username"
				type="text"
				value={data.user?.username || ""}
				disabled
				class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-700/50 px-4 py-2.5 text-gray-500 dark:text-gray-400 cursor-not-allowed"
			/>
			<p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
				用户名不可修改
			</p>
		</div>

		<div>
			<label for="email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
				邮箱
			</label>
			<input
				id="email"
				type="email"
				value={data.user?.email || ""}
				disabled
				class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-700/50 px-4 py-2.5 text-gray-500 dark:text-gray-400 cursor-not-allowed"
			/>
			<p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
				邮箱不可修改
			</p>
		</div>

		<div>
			<label for="nickname" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
				昵称
			</label>
			<input
				id="nickname"
				type="text"
				bind:value={nickname}
				placeholder="请输入昵称"
				class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
			/>
		</div>

		<div>
			<label for="avatarUrl" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
				头像URL
			</label>
			<input
				id="avatarUrl"
				type="url"
				bind:value={avatarUrl}
				placeholder="https://example.com/avatar.jpg"
				class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
			/>
			<p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
				可选,留空将不显示头像
			</p>
			{#if avatarUrl}
				<div class="mt-3">
					<p class="text-xs font-medium text-gray-700 dark:text-gray-300 mb-2">头像预览:</p>
					<img
						src={avatarUrl}
						alt="Avatar preview"
						class="size-16 rounded-full object-cover border-2 border-gray-200 dark:border-gray-600"
						onerror={(e) => {
							e.currentTarget.src = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='64' height='64'%3E%3Crect width='64' height='64' fill='%23ddd'/%3E%3Ctext x='50%25' y='50%25' dominant-baseline='middle' text-anchor='middle' font-family='monospace' font-size='16' fill='%23999'%3E加载失败%3C/text%3E%3C/svg%3E";
						}}
					/>
				</div>
			{/if}
		</div>

		<div class="flex justify-end">
			<button
				onclick={handleSubmit}
				disabled={loading}
				class="rounded-lg bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 px-6 py-2.5 font-medium text-white transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500/50"
			>
				{loading ? "保存中..." : "保存更改"}
			</button>
		</div>
	</div>
</div>
