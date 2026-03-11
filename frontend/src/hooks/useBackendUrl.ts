/**
 * Returns the backend URL.
 * - On localhost: always use local backend
 * - On Vercel: use tunnel URL from Supabase (future) or env var
 */
export function useBackendUrl(): string {
  if (window.location.hostname === "localhost" ||
      window.location.hostname === "127.0.0.1") {
    return "http://127.0.0.1:8000";
  }
  // TODO: fetch tunnel URL from Supabase registry
  return import.meta.env.VITE_BACKEND_URL || "http://127.0.0.1:8000";
}
