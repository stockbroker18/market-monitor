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

  const value = data?.value;
  const display = value != null
    ? typeof value === "number" ? value.toFixed(3) : String(value)
    : "—";

  return (
    <div className={`price-tile ${isError ? "error" : ""}`}>
      <div className="price-tile-label">{label}</div>
      <div className="price-tile-ticker">{ticker}</div>
      <div className={`price-tile-value ${isLoading ? "loading" : ""}`}>
        {display}
      </div>
      <div className="price-tile-field">{field}</div>
    </div>
  );
}
