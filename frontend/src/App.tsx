import { useState } from "react";
import { useBackendUrl } from "./hooks/useBackendUrl";
import Dashboard from "./components/Dashboard";
import Login from "./components/Login";
import "./App.css";

export default function App() {
  const [username, setUsername] = useState("");
  const { backendUrl, loading, error } = useBackendUrl(username);

  if (!username) {
    return <Login onLogin={(user) => setUsername(user)} />;
  }

  if (loading) {
    return (
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "center",
        height: "100vh", color: "var(--muted)", fontFamily: "var(--font-mono)",
        fontSize: "13px", letterSpacing: "0.1em"
      }}>
        Connecting to your backend...
      </div>
    );
  }

  if (error) {
    return (
      <div style={{
        display: "flex", alignItems: "center", justifyContent: "center",
        height: "100vh", color: "var(--down)", fontFamily: "var(--font-mono)",
        fontSize: "13px", letterSpacing: "0.1em"
      }}>
        {error}
      </div>
    );
  }

  return <Dashboard backendUrl={backendUrl} />;
}
