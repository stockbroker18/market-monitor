import "./TabBar.css";

interface Props {
  tabs: string[];
  active: number;
  onChange: (i: number) => void;
}

export default function TabBar({ tabs, active, onChange }: Props) {
  return (
    <div className="tabbar">
      {tabs.map((tab, i) => (
        <button
          key={tab}
          className={`tabbar-tab ${i === active ? "active" : ""}`}
          onClick={() => onChange(i)}
        >
          {tab}
        </button>
      ))}
    </div>
  );
}
