import { useState } from "react";
import "./Login.css";

interface Props { onLogin: (username: string) => void; }

export default function Login({ onLogin }: Props) {
  const [user, setUser] = useState("");
  const [pass, setPass] = useState("");
  const [error, setError] = useState("");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user || !pass) { setError("Please enter username and password."); return; }
    // TODO: validate against Supabase
    // For now accept any credentials to test the UI
    onLogin();
  }

  return (
    <div className="login-bg">
      <div className="login-card">
        <div className="login-logo">
          <span className="login-logo-mark">M</span>
          <span className="login-logo-text">MARKET<br/>MONITOR</span>
        </div>
        <form onSubmit={handleSubmit} className="login-form">
          {error && <div className="login-error">{error}</div>}
          <div className="login-field">
            <label>Username</label>
            <input
              type="text"
              value={user}
              onChange={e => setUser(e.target.value)}
              autoFocus
              spellCheck={false}
            />
          </div>
          <div className="login-field">
            <label>Password</label>
            <input
              type="password"
              value={pass}
              onChange={e => setPass(e.target.value)}
            />
          </div>
          <button type="submit" className="login-btn">Sign In</button>
        </form>
        <p className="login-footer">
          No account? <a href="#">Request access</a>
        </p>
      </div>
    </div>
  );
}
