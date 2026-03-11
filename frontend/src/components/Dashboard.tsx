import { useState } from "react";
import { useHealth } from "../hooks/useHealth";
import StatusBar from "./StatusBar";
import TabBar from "./TabBar";
import PriceTile from "./PriceTile";
import "./Dashboard.css";

interface Props { backendUrl: string; }

const DEFAULT_TABS = ["Overview", "Rates", "FX", "Credit"];

const DEFAULT_TICKERS = [
  { ticker: "GT10 Govt",  field: "YLD_YTM_MID", label: "US 10Y" },
  { ticker: "GT2 Govt",   field: "YLD_YTM_MID", label: "US 2Y"  },
  { ticker: "GT30 Govt",  field: "YLD_YTM_MID", label: "US 30Y" },
  { ticker: "USGG10YR Index", field: "PX_LAST",  label: "UST 10Y" },
];

export default function Dashboard({ backendUrl }: Props) {
  const [activeTab, setActiveTab] = useState(0);
  const health = useHealth(backendUrl);

  return (
    <div className="dashboard">
      <StatusBar
        connected={health.data?.bloomberg_connected ?? false}
        loading={health.isLoading}
      />
      <TabBar
        tabs={DEFAULT_TABS}
        active={activeTab}
        onChange={setActiveTab}
      />
      <div className="dashboard-content">
        {activeTab === 0 && (
          <div className="tile-grid">
            {DEFAULT_TICKERS.map(t => (
              <PriceTile
                key={t.ticker}
                backendUrl={backendUrl}
                ticker={t.ticker}
                field={t.field}
                label={t.label}
              />
            ))}
          </div>
        )}
        {activeTab !== 0 && (
          <div className="coming-soon">
            <span>{DEFAULT_TABS[activeTab]} — coming soon</span>
          </div>
        )}
      </div>
    </div>
  );
}
