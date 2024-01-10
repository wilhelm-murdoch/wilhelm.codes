export const load = async ({ params, fetch }) => {
    const response = await fetch("/api/australia.json");
    return {
        "quiz": await response.json()
    }
};