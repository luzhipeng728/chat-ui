<script lang="ts">
	import { base } from "$app/paths";
	import Modal from "$lib/components/Modal.svelte";

	interface Props {
		isOpen: boolean;
		onClose: () => void;
		onLoginSuccess?: () => void;
	}

	let { isOpen = $bindable(), onClose, onLoginSuccess }: Props = $props();

	let isLogin = $state(true); // true=登录, false=注册
	let username = $state("");
	let password = $state("");
	let email = $state("");
	let nickname = $state("");
	let error = $state("");
	let loading = $state(false);

	function resetForm() {
		username = "";
		password = "";
		email = "";
		nickname = "";
		error = "";
		loading = false;
	}

	function switchMode() {
		isLogin = !isLogin;
		resetForm();
	}

	async function handleSubmit() {
		if (!username || !password) {
			error = "请输入用户名和密码";
			return;
		}

		if (!isLogin && (!email || !nickname)) {
			error = "请填写所有字段";
			return;
		}

		loading = true;
		error = "";

		try {
			const endpoint = isLogin ? `${base}/login` : `${base}/register`;
			const body = isLogin
				? { username, password }
				: { username, password, email, nickname };

			const res = await fetch(endpoint, {
				method: "POST",
				headers: {
					"Content-Type": "application/json",
				},
				body: JSON.stringify(body),
			});

			const data = await res.json();

			if (!res.ok) {
				error = data.error || (isLogin ? "登录失败" : "注册失败");
				loading = false;
				return;
			}

			if (isLogin) {
				// 登录成功
				resetForm();
				isOpen = false;
				onLoginSuccess?.();
				// 刷新页面以更新用户状态
				window.location.reload();
			} else {
				// 注册成功,切换到登录模式
				isLogin = true;
				resetForm();
				error = "";
				// 显示成功提示
				setTimeout(() => {
					error = ""; // 清除之前的错误
				}, 100);
			}
		} catch (err) {
			error = "网络错误,请稍后再试";
			loading = false;
		}
	}

	function handleKeyPress(event: KeyboardEvent) {
		if (event.key === "Enter") {
			handleSubmit();
		}
	}
</script>

{#if isOpen}
<Modal onclose={onClose} width="!max-w-lg">
	<div class="flex flex-col gap-6 p-10 bg-white dark:bg-gray-900">
		<!-- 简洁标题 -->
		<div class="border-b border-gray-200 dark:border-gray-800 pb-4">
			<h2 class="text-xl font-semibold text-gray-900 dark:text-gray-100">
				{isLogin ? "登录" : "注册账号"}
			</h2>
			<p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
				{isLogin ? "使用您的账号登录" : "创建新账号以开始使用"}
			</p>
		</div>

		{#if error}
			<div class="rounded-lg bg-red-50 dark:bg-red-900/20 p-3 text-sm text-red-600 dark:text-red-400">
				{error}
			</div>
		{/if}

		<div class="space-y-4">
			<div>
				<label for="modal-username" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
					用户名
				</label>
				<input
					id="modal-username"
					type="text"
					bind:value={username}
					onkeypress={handleKeyPress}
					placeholder={isLogin ? "请输入用户名" : "3-20个字符"}
					class="w-full rounded-md border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 px-3 py-2 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 focus:border-gray-400 dark:focus:border-gray-600 focus:outline-none focus:ring-1 focus:ring-gray-400 dark:focus:ring-gray-600 transition-colors"
				/>
			</div>

			{#if !isLogin}
				<div>
					<label for="modal-nickname" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
						昵称
					</label>
					<input
						id="modal-nickname"
						type="text"
						bind:value={nickname}
						onkeypress={handleKeyPress}
						placeholder="显示昵称"
						class="w-full rounded-md border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 px-3 py-2 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 focus:border-gray-400 dark:focus:border-gray-600 focus:outline-none focus:ring-1 focus:ring-gray-400 dark:focus:ring-gray-600 transition-colors"
					/>
				</div>

				<div>
					<label for="modal-email" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
						邮箱
					</label>
					<input
						id="modal-email"
						type="email"
						bind:value={email}
						onkeypress={handleKeyPress}
						placeholder="your@email.com"
						class="w-full rounded-md border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 px-3 py-2 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 focus:border-gray-400 dark:focus:border-gray-600 focus:outline-none focus:ring-1 focus:ring-gray-400 dark:focus:ring-gray-600 transition-colors"
					/>
				</div>
			{/if}

			<div>
				<label for="modal-password" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5">
					密码
				</label>
				<input
					id="modal-password"
					type="password"
					bind:value={password}
					onkeypress={handleKeyPress}
					placeholder={isLogin ? "请输入密码" : "至少6个字符"}
					class="w-full rounded-md border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 px-3 py-2 text-gray-900 dark:text-gray-100 placeholder-gray-400 dark:placeholder-gray-500 focus:border-gray-400 dark:focus:border-gray-600 focus:outline-none focus:ring-1 focus:ring-gray-400 dark:focus:ring-gray-600 transition-colors"
				/>
			</div>

			<button
				onclick={handleSubmit}
				disabled={loading}
				class="w-full rounded-md bg-gray-900 hover:bg-gray-800 disabled:bg-gray-400 dark:bg-gray-100 dark:hover:bg-gray-200 dark:disabled:bg-gray-600 px-4 py-2.5 font-medium text-white dark:text-gray-900 disabled:text-gray-200 dark:disabled:text-gray-400 transition-colors focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2"
			>
				{loading ? (isLogin ? "登录中..." : "注册中...") : (isLogin ? "登录" : "注册")}
			</button>

			<!-- 底部链接 -->
			<div class="pt-2 text-center text-sm text-gray-600 dark:text-gray-400">
				{isLogin ? "还没有账号?" : "已有账号?"}
				<button
					onclick={switchMode}
					type="button"
					class="ml-1 font-medium text-gray-900 hover:text-gray-700 dark:text-gray-100 dark:hover:text-gray-300 underline decoration-gray-300 dark:decoration-gray-700 underline-offset-2 hover:decoration-gray-500 dark:hover:decoration-gray-500 transition-colors"
				>
					{isLogin ? "立即注册" : "返回登录"}
				</button>
			</div>
		</div>
	</div>
</Modal>
{/if}
