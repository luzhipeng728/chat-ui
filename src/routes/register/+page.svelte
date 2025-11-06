<script lang="ts">
	import { goto } from "$app/navigation";
	import { base } from "$app/paths";

	let username = $state("");
	let password = $state("");
	let email = $state("");
	let nickname = $state("");
	let error = $state("");
	let loading = $state(false);

	async function handleRegister() {
		if (!username || !password || !email || !nickname) {
			error = "请填写所有字段";
			return;
		}

		loading = true;
		error = "";

		try {
			const res = await fetch(`${base}/register`, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify({
					username,
					password,
					email,
					nickname,
				}),
			});

			const data = await res.json();

			if (!res.ok) {
				error = data.error || "注册失败";
				loading = false;
				return;
			}

			// 注册成功,跳转到登录页
			goto(`${base}/login?registered=true`);
		} catch (err) {
			error = "网络错误,请稍后再试";
			loading = false;
		}
	}

	function handleKeyPress(event: KeyboardEvent) {
		if (event.key === "Enter") {
			handleRegister();
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
					创建新账号
				</p>
			</div>

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
						placeholder="3-20个字符"
						class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
					/>
				</div>

				<div>
					<label for="nickname" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
						昵称
					</label>
					<input
						id="nickname"
						type="text"
						bind:value={nickname}
						onkeypress={handleKeyPress}
						placeholder="显示昵称"
						class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
					/>
				</div>

				<div>
					<label for="email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
						邮箱
					</label>
					<input
						id="email"
						type="email"
						bind:value={email}
						onkeypress={handleKeyPress}
						placeholder="your@email.com"
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
						placeholder="至少6个字符"
						class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-4 py-2.5 text-gray-900 dark:text-gray-100 placeholder-gray-500 dark:placeholder-gray-400 focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
					/>
				</div>

				<button
					onclick={handleRegister}
					disabled={loading}
					class="w-full rounded-lg bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 px-4 py-2.5 font-medium text-white transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500/50"
				>
					{loading ? "注册中..." : "注册"}
				</button>

				<div class="text-center text-sm text-gray-600 dark:text-gray-400">
					已有账号?
					<a href="{base}/login" class="text-blue-600 hover:text-blue-700 dark:text-blue-400 dark:hover:text-blue-300 font-medium">
						立即登录
					</a>
				</div>
			</div>
		</div>
	</div>
</div>
