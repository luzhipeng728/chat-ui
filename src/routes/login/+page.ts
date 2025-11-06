import type { PageLoad } from "./$types";

export const load: PageLoad = async ({ url }) => {
	return {
		registered: url.searchParams.get("registered") === "true",
	};
};
