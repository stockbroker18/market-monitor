import { useState, useEffect } from "react";
import { usePrice } from "../hooks/usePrice";
import "./PriceTile.css";

interface Props {
  backendUrl: string;
  ticker: string;
  field: string;
  label: string;
}

export default function PriceTile({ backendUrl, ticker, field, label }: Props) {
  const { data, isLoading, isError } = usePrice(backendUrl, ticker, field);
  const [lastValue, setLastValue] = useState<string>("—");

  useEffect(() => {
    if (data?.value != null) {
      const formatted = typeof data.value === "number"
        ? data.value.toFixed(3)
        : String(data.value);
      setLastValue(formatted);
    }
  }, [data]);

  return (
    <div className={`price-tile ${isError ? "error" : ""}`}>
      <div className="price-tile-label">{label}</div>
      <div className="price-tile-ticker">{ticker}</div>
      <div className={`price-tile-value ${isLoading && lastValue === "—" ? "loading" : ""}`}>
        {lastValue}
      </div>
      <div className="price-tile-field">{field}</div>
    </div>
  );
}
