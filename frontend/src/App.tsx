import { useState } from "react";
import { useBackendUrl } from "./hooks/useBackendUrl";
import Dashboard from "./components/Dashboard";
import Login from "./components/Login";
import "./App.css";

export default function App() {
  const [authed, setAuthed] = useState(false);
  const backendUrl = useBackendUrl();

  if (!authed) return <Login onLogin={() => setAuthed(true)} />;
  return <Dashboard backendUrl={backendUrl} />;
}
