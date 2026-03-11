import "./StatusBar.css";

interface Props {
  connected: boolean;
  loading: boolean;
}

export default function StatusBar({ backendUrl, connected, loading }: Props) {
  const now = new Date().toLocaleTimeString();

  return (
    <div className="statusbar">
      <div className="statusbar-left">
        <span className="statusbar-logo">MARKET MONITOR</span>
      </div>
      <div className="statusbar-right">
        <div className={`statusbar-dot ${loading ? "loading" : connected ? "ok" : "err"}`} />
        <span className="statusbar-label">
          {loading ? "Connecting..." : connected ? "Bloomberg connected" : "Bloomberg disconnected"}
        </span>
        <span className="statusbar-time">{now}</span>
      </div>
    </div>
  );
}
