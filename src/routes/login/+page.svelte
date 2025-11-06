<script lang="ts">
	import { goto } from "$app/navigation";
	import { base } from "$app/paths";

	let { data } = $props();

	let username = $state("");
	let password = $state("");
	let error = $state("");
	let loading = $state(false);

	// 检查是否刚完成注册
	const justRegistered = data.registered;

	async function handleLogin() {
		if (!username || !password) {
			error = "请输入用户名和密码";
			return;
		}

		loading = true;
		error = "";

		try {
			const res = await fetch(`${base}/login`, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					username,
					password,
				}),
			});

			const data = await res.json();

			if (!res.ok) {
				error = data.error || "登录失败";
				loading = false;
				return;
			}

			// 登录成功,跳转到首页
			goto(`${base}/`);
		} catch (err) {
			error = "网络错误,请稍后再试";
			loading = false;
		}
	}

	function handleKeyPress(event: KeyboardEvent) {
		if (event.key === "Enter") {
			handleLogin();
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800 px-4">
	<div class="w-full max-w-md">
		<div class="rounded-2xl bg-white dark:bg-gray-800 p-8 shadow-2xl">
			<div class="mb-8 text-center">
				<h1 class="text-3xl font-bold text-gray-900 dark:text-gray-100">
					易诚融智 AI
				</h1>
				<p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
					登录您的账号
				</p>
			</div>

			{#if justRegistered}
				<div class="mb-4 rounded-lg bg-green-50 dark:bg-green-900/20 p-3 text-sm text-green-600 dark:text-green-400">
					注册成功! 请使用您的账号登录
				</div>
			{/if}

			{#if error}
				<div class="mb-4 rounded-lg bg-red-50 dark:bg-red-900/20 p-3 text-sm text-red-600 dark:text-red-400">
					{error}
				</div>
			{/if}

			<div class="space-y-4">
				<div>
					<label for="username" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
						用户名
					</label>
					<input
						id="username"
						type="text"
						bind:value={username}
						onkeypress={handleKeyPress}
						placeholder="请输入用户名"
						class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
					/>
				</div>

				<div>
					<label for="password" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
						密码
					</label>
					<input
						id="password"
						type="password"
						bind:value={password}
						onkeypress={handleKeyPress}
						placeholder="请输入密码"
						class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
					/>
				</div>

				<button
					onclick={handleLogin}
					disabled={loading}
					class="w-full rounded-lg bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 px-4 py-2.5 font-medium text-white transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500/50"
				>
					{loading ? "登录中..." : "登录"}
				</button>

				<div class="text-center text-sm text-gray-600 dark:text-gray-400">
					还没有账号?
					<a href="{base}/register" class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 font-medium">
						立即注册
					</a>
				</div>
			</div>
		</div>
	</div>
</div>
