import { useState, useEffect } from "react";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

export function useBackendUrl(username: string): {
  backendUrl: string;
  loading: boolean;
  error: string | null;
} {
  const [backendUrl, setBackendUrl] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!username) return;

    async function fetchTunnelUrl() {
      setLoading(true);
      setError(null);

      // If running locally, always use local backend
      if (
        window.location.hostname === "localhost" ||
        window.location.hostname === "127.0.0.1"
      ) {
        setBackendUrl("http://127.0.0.1:8000");
        setLoading(false);
        return;
      }

      // Look up tunnel URL from Supabase
      const { data, error } = await supabase
        .from("tunnel_registry")
        .select("tunnel_url, is_online")
        .eq("username", username)
        .single();

      if (error || !data) {
        setError("Could not find your backend. Is START.bat running?");
        setLoading(false);
        return;
      }

      if (!data.is_online) {
        setError("Your backend is offline. Please run START.bat.");
        setLoading(false);
        return;
      }

      setBackendUrl(data.tunnel_url);
      setLoading(false);
    }

    fetchTunnelUrl();

    // Refresh every 60 seconds in case tunnel URL changes
    const interval = setInterval(fetchTunnelUrl, 60000);
    return () => clearInterval(interval);
  }, [username]);

  return { backendUrl, loading, error };
}
