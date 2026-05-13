// Shared phone-frame + helper components for KayFit × FitKeep merge canvas

const StatusBar = ({ dark = false, time = "9:41" }) => (
  <div className={`sb${dark ? " dark" : ""}`}>
    <span className="sb-time">{time}</span>
    <div className="sb-right">
      <div className="sb-signal">
        <div className="sb-bar" style={{ height: 4 }}></div>
        <div className="sb-bar" style={{ height: 6 }}></div>
        <div className="sb-bar" style={{ height: 8 }}></div>
        <div className="sb-bar" style={{ height: 9 }}></div>
      </div>
      <span className="sb-lte">5G</span>
      <div className="sb-battery"><div className="fill"></div></div>
    </div>
  </div>
);

const DI = () => <div className="di"></div>;

// 3-tab bottom navigation with center "+"
const TabBar3 = ({ active = "journal" }) => (
  <div className="tabbar">
    <div className={`tab${active === "journal" ? " on" : ""}`}>
      <svg viewBox="0 0 24 24" fill="none">
        <path d="M5 4h14v16H5z M5 9h14 M9 4v16" stroke={active === "journal" ? "#2563EB" : "#9CA3AF"} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
      <span className="tab-lbl">Журнал</span>
    </div>
    <div className={`tab${active === "training" ? " on" : ""}`}>
      <svg viewBox="0 0 24 24" fill="none">
        <path d="M6 8v8 M3 10v4 M18 8v8 M21 10v4 M6 12h12" stroke={active === "training" ? "#2563EB" : "#9CA3AF"} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
      <span className="tab-lbl">Тренировки</span>
    </div>
    <div className="tab-add-btn"><span className="tab-plus">+</span></div>
    <div className={`tab${active === "chat" ? " on" : ""}`}>
      <svg viewBox="0 0 24 24" fill="none">
        <path d="M21 12a8 8 0 0 1-11.5 7.2L4 20l1-4.5A8 8 0 1 1 21 12z" stroke={active === "chat" ? "#2563EB" : "#9CA3AF"} strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>
      <span className="tab-lbl">Чат</span>
    </div>
    <div className="tab" style={{ visibility: "hidden" }}>
      <svg viewBox="0 0 24 24"></svg><span className="tab-lbl">_</span>
    </div>
  </div>
);

// Generic phone frame
const Phone = ({ children, dark = false, noTab = false, tab = "journal" }) => (
  <div className="phone" style={dark ? { background: "#1C1C1E" } : {}}>
    <DI />
    <StatusBar dark={dark} />
    {children}
    {!noTab && <TabBar3 active={tab} />}
  </div>
);

// Macro rings SVG (small)
const MacroRings = ({ size = 80 }) => {
  const c = size / 2;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <circle cx={c} cy={c} r={c - 4} fill="none" stroke="#FEE2E2" strokeWidth="4" />
      <circle cx={c} cy={c} r={c - 4} fill="none" stroke="#EF4444" strokeWidth="4"
              strokeDasharray={`${2 * Math.PI * (c - 4) * 0.72} ${2 * Math.PI * (c - 4)}`}
              strokeLinecap="round"
              transform={`rotate(-90 ${c} ${c})`} />
      <circle cx={c} cy={c} r={c - 12} fill="none" stroke="#DCFCE7" strokeWidth="4" />
      <circle cx={c} cy={c} r={c - 12} fill="none" stroke="#22C55E" strokeWidth="4"
              strokeDasharray={`${2 * Math.PI * (c - 12) * 0.6} ${2 * Math.PI * (c - 12)}`}
              strokeLinecap="round"
              transform={`rotate(-90 ${c} ${c})`} />
      <circle cx={c} cy={c} r={c - 20} fill="none" stroke="#CFFAFE" strokeWidth="4" />
      <circle cx={c} cy={c} r={c - 20} fill="none" stroke="#06B6D4" strokeWidth="4"
              strokeDasharray={`${2 * Math.PI * (c - 20) * 0.45} ${2 * Math.PI * (c - 20)}`}
              strokeLinecap="round"
              transform={`rotate(-90 ${c} ${c})`} />
    </svg>
  );
};

Object.assign(window, { StatusBar, DI, TabBar3, Phone, MacroRings });
