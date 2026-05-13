// Clickable Variant B prototype — full navigation flow.
const { useState } = React;

const SCREENS = {
  OB_MODULES: "ob-modules",
  OB_EQUIP: "ob-equip",
  JOURNAL: "journal",
  ACCOUNT: "account",
  // legacy aliases kept for compat
  PITANIE: "journal",
  TRAININGS: "journal",
  CHAT: "chat",
  DETAIL: "detail",
  LIVE: "live",
};

const Check = ({ size = 11, color = "#fff" }) => (
  <svg width={size} height={size} viewBox="0 0 24 24"><path d="M5 12l5 5 9-11" stroke={color} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
);

const MacroRings = ({ size = 88 }) => {
  const cx = size / 2, cy = size / 2;
  const ring = (r, color, frac) => {
    const C = 2 * Math.PI * r;
    return (
      <g key={r}>
        <circle cx={cx} cy={cy} r={r} fill="none" stroke="#F3F4F6" strokeWidth="5"/>
        <circle cx={cx} cy={cy} r={r} fill="none" stroke={color} strokeWidth="5"
                strokeDasharray={`${C * frac} ${C}`}
                transform={`rotate(-90 ${cx} ${cy})`} strokeLinecap="round"/>
      </g>
    );
  };
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ flexShrink: 0 }}>
      {ring(size/2 - 4,  "#EF4444", 0.68)}
      {ring(size/2 - 13, "#22C55E", 0.50)}
      {ring(size/2 - 22, "#06B6D4", 0.72)}
    </svg>
  );
};

const TabIcon = ({ kind, active }) => {
  const c = active ? "#2563EB" : "#9CA3AF";
  if (kind === "journal" || kind === "pitanie") return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="18" height="18" rx="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/>
    </svg>
  );
  if (kind === "training") return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 8v8 M3 10v4 M18 8v8 M21 10v4 M6 12h12"/>
    </svg>
  );
  if (kind === "chat") return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/>
    </svg>
  );
  if (kind === "more") return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2" strokeLinecap="round">
      <circle cx="5" cy="12" r="1.4"/><circle cx="12" cy="12" r="1.4"/><circle cx="19" cy="12" r="1.4"/>
    </svg>
  );
  return null;
};

const TabBar = ({ active, onNav, onAdd }) => (
  <div className="tabbar">
    <div className={`tab ${active === SCREENS.JOURNAL ? "on" : ""}`} onClick={() => onNav(SCREENS.JOURNAL)}>
      <TabIcon kind="journal" active={active === SCREENS.JOURNAL}/><div className="tab-lbl">Журнал</div>
    </div>
    <div className="tab-add-btn" onClick={onAdd}>+</div>
    <div className={`tab ${active === SCREENS.CHAT ? "on" : ""}`} onClick={() => onNav(SCREENS.CHAT)}>
      <TabIcon kind="chat" active={active === SCREENS.CHAT}/><div className="tab-lbl">Чат</div>
    </div>
  </div>
);

const ObModules = ({ onNext }) => {
  const [nutri, setNutri] = useState(true);
  const [train, setTrain] = useState(true);
  const ok = nutri || train;
  return (
    <div className="phone">
      <div className="appbar"><div></div><div></div></div>
      <div className="ob-progress"><div className="ob-seg on"></div><div className="ob-seg on"></div><div className="ob-seg"></div><div className="ob-seg"></div></div>
      <div className="ob-h1">Расскажи о своих целях</div>
      <div className="ob-sub">Включи нужные модули — приложение перестроится под тебя.</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 12, padding: "0 22px" }}>
        <div className={`goal-card ${nutri ? "on" : ""}`} onClick={() => setNutri(!nutri)}>
          <div className="goal-icon" style={{ background: nutri ? "#DBEAFE" : "#F3F4F6" }}>🥗</div>
          <div style={{ flex: 1 }}>
            <div className="goal-name">Питание</div>
            <div className="goal-desc">Дневник, БЖУ, AI-нутрициолог</div>
          </div>
          {nutri && <div className="check-circle"><Check/></div>}
        </div>
        <div className={`goal-card ${train ? "on" : ""}`} onClick={() => setTrain(!train)}>
          <div className="goal-icon" style={{ background: train ? "#DBEAFE" : "#F3F4F6" }}>🏋️</div>
          <div style={{ flex: 1 }}>
            <div className="goal-name">Тренировки</div>
            <div className="goal-desc">Программы, упражнения, AI-тренер</div>
          </div>
          {train && <div className="check-circle"><Check/></div>}
        </div>
        <div style={{ padding: "8px 4px", fontSize: 12, color: "#9CA3AF", display: "flex", alignItems: "center", gap: 6 }}>
          <span>💡</span> Можешь поменять в Настройках в любой момент
        </div>
      </div>
      <div style={{ padding: 22, marginTop: "auto" }}>
        <div className="btn-blue" style={{ opacity: ok ? 1 : 0.4, pointerEvents: ok ? "auto" : "none" }} onClick={onNext}>Продолжить</div>
      </div>
    </div>
  );
};

const ObEquipment = ({ onBack, onDone }) => {
  const [picked, setPicked] = useState({ gan: true, sht: true, sk: true });
  const toggle = (k) => setPicked(p => ({ ...p, [k]: !p[k] }));
  const items = [
    ["gan", "🏋️", "Гантели"], ["sht", "⚡", "Штанга"],
    ["tur", "🔝", "Турник"],   ["sk",  "🪑", "Скамья"],
    ["tr",  "🏭", "Тренажёры"], ["mat", "🟩", "Коврик"],
    ["rez", "🟡", "Резинки"],
  ];
  const count = Object.values(picked).filter(Boolean).length;
  return (
    <div className="phone">
      <div className="appbar"><div className="appbar-back" onClick={onBack}>←</div><div></div></div>
      <div className="ob-progress"><div className="ob-seg on"></div><div className="ob-seg on"></div><div className="ob-seg on"></div><div className="ob-seg"></div></div>
      <div className="ob-h1">Чем тренируешься?</div>
      <div className="ob-sub">Подберём план под доступное оборудование.</div>
      <div style={{ padding: "0 22px", display: "flex", flexWrap: "wrap", gap: 8 }}>
        {items.map(([k, ic, n]) => (
          <div key={k} className={`eq-chip ${picked[k] ? "on" : ""}`} onClick={() => toggle(k)}>
            <span>{ic}</span> {n}
          </div>
        ))}
      </div>
      <div style={{ padding: 22, marginTop: "auto", display: "flex", flexDirection: "column", gap: 12 }}>
        <div style={{ background: "#EFF6FF", border: "1px solid #DBEAFE", borderRadius: 14, padding: "12px 16px", fontSize: 13, color: "#1D4ED8", lineHeight: 1.5 }}>
          <strong>{count} выбрано</strong> — доступно ~{count * 12} упражнений
        </div>
        <div className="btn-blue" onClick={onDone}>Продолжить</div>
      </div>
    </div>
  );
};

const Account = ({ onNav, onAdd }) => {
  const [equip, setEquip] = useState({ gan: true, sht: true, sk: true, tur: false, tr: false, mat: true, rez: false });
  const toggle = (k) => setEquip(p => ({ ...p, [k]: !p[k] }));
  const items = [
    ["gan", "🏋️", "Гантели"], ["sht", "⚡", "Штанга"],
    ["tur", "🔝", "Турник"],   ["sk",  "🪑", "Скамья"],
    ["tr",  "🏭", "Тренажёры"], ["mat", "🟩", "Коврик"],
    ["rez", "🟡", "Резинки"],
  ];
  const count = Object.values(equip).filter(Boolean).length;
  const Row = ({ ic, name, sub, action, onClick }) => (
    <div onClick={onClick} style={{ display: "flex", alignItems: "center", gap: 14, padding: "14px 22px", cursor: onClick ? "pointer" : "default", borderBottom: "0.5px solid #F3F4F6" }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: "#F3F4F6", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 16, flexShrink: 0 }}>{ic}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: "#111827" }}>{name}</div>
        {sub && <div style={{ fontSize: 12, color: "#9CA3AF", marginTop: 2 }}>{sub}</div>}
      </div>
      {action && <div style={{ fontSize: 13, color: "#9CA3AF", flexShrink: 0 }}>{action}</div>}
    </div>
  );
  return (
    <div className="phone">
      <div className="appbar">
        <div><div className="appbar-title">Аккаунт</div><div className="appbar-sub">Профиль · настройки</div></div>
        <div className="appbar-action">⚙</div>
      </div>
      <div className="scroll">
        {/* Profile header */}
        <div style={{ padding: "0 22px 18px", display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{ width: 64, height: 64, borderRadius: 32, background: "linear-gradient(135deg,#2563EB,#7C3AED)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 22, fontWeight: 800, letterSpacing: -0.5, flexShrink: 0 }}>АК</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 18, fontWeight: 800, color: "#111827", letterSpacing: -0.3 }}>Алексей К.</div>
            <div style={{ fontSize: 13, color: "#6B7280", marginTop: 2 }}>alex.k@mail.ru</div>
            <div style={{ display: "inline-flex", alignItems: "center", gap: 4, marginTop: 6, padding: "3px 8px", background: "linear-gradient(135deg,#FEF3C7,#FDE68A)", borderRadius: 999, fontSize: 10, fontWeight: 800, color: "#92400E", letterSpacing: 0.4, textTransform: "uppercase" }}>★ Pro · до 12.06</div>
          </div>
        </div>

        {/* Stats strip */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 1, background: "#F3F4F6", margin: "0 22px 24px", borderRadius: 14, overflow: "hidden", border: "1px solid #F3F4F6" }}>
          {[["28", "тренировок"], ["12", "недель"], ["−4.2", "кг"]].map(([n, l]) => (
            <div key={l} style={{ background: "#fff", padding: "12px 6px", textAlign: "center" }}>
              <div style={{ fontFamily: "JetBrains Mono", fontSize: 20, fontWeight: 800, color: "#111827", letterSpacing: -0.5 }}>{n}</div>
              <div style={{ fontSize: 10, color: "#9CA3AF", fontWeight: 500, marginTop: 2 }}>{l}</div>
            </div>
          ))}
        </div>

        {/* Section: Программа */}
        <div style={{ fontSize: 11, fontWeight: 700, color: "#9CA3AF", letterSpacing: 0.6, textTransform: "uppercase", padding: "0 22px 8px" }}>Программа</div>
        <div style={{ background: "#fff", borderTop: "0.5px solid #F3F4F6" }}>
          <Row ic="🎯" name="Цель" sub="Снижение веса · −0.5 кг/нед" action="›" onClick={() => {}}/>
          <Row ic="🍽" name="Питание" sub="2100 ккал · 130/210/70 БЖУ" action="›" onClick={() => {}}/>
          <Row ic="🏋" name="Тренировки" sub="3×/нед · 45 мин · Дом" action="›" onClick={() => {}}/>
        </div>

        {/* Section: Оборудование */}
        <div style={{ fontSize: 11, fontWeight: 700, color: "#9CA3AF", letterSpacing: 0.6, textTransform: "uppercase", padding: "20px 22px 8px", display: "flex", justifyContent: "space-between" }}>
          <span>Оборудование</span>
          <span style={{ color: "#2563EB", fontWeight: 700 }}>{count} выбрано</span>
        </div>
        <div style={{ padding: "0 22px 6px", fontSize: 12, color: "#6B7280", lineHeight: 1.5 }}>Тренировки подбираются под доступный инвентарь. Тапни, чтобы включить или выключить.</div>
        <div style={{ padding: "12px 22px 0", display: "flex", flexWrap: "wrap", gap: 8 }}>
          {items.map(([k, ic, n]) => (
            <div key={k} className={`eq-chip ${equip[k] ? "on" : ""}`} onClick={() => toggle(k)}>
              <span>{ic}</span> {n}
            </div>
          ))}
        </div>
        <div style={{ margin: "14px 22px 0", background: "#EFF6FF", border: "1px solid #DBEAFE", borderRadius: 12, padding: "10px 14px", fontSize: 12, color: "#1D4ED8", lineHeight: 1.5 }}>
          Доступно ~{count * 12} упражнений в библиотеке
        </div>
        <div onClick={() => {}} style={{ margin: "10px 22px 0", padding: "12px 14px", border: "1px solid #E5E7EB", borderRadius: 12, fontSize: 13, fontWeight: 600, color: "#111827", display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }}>
          <span style={{ fontSize: 16 }}>⚙</span>
          <span style={{ flex: 1 }}>Расширенный выбор оборудования</span>
          <span style={{ fontSize: 11, color: "#9CA3AF" }}>вес / типы ›</span>
        </div>

        {/* Section: Правовые и AI */}
        <div style={{ fontSize: 11, fontWeight: 700, color: "#9CA3AF", letterSpacing: 0.6, textTransform: "uppercase", padding: "24px 22px 8px" }}>Правовые и данные</div>
        <div style={{ background: "#fff", borderTop: "0.5px solid #F3F4F6" }}>
          <Row ic="🤖" name="AI сервисы" sub="OpenAI · USDA database" action="›" onClick={() => {}}/>
          <Row ic="🔒" name="Конфиденциальность" sub="Настройки данных" action="›" onClick={() => {}}/>
          <Row ic="📄" name="Privacy Policy" action="›" onClick={() => {}}/>
          <Row ic="📜" name="Terms of Use" action="›" onClick={() => {}}/>
          <Row ic="✨" name="AI-модели" sub="Согласие на обработку" action="Вкл ›" onClick={() => {}}/>
          <Row ic="📤" name="Экспорт данных" action="›" onClick={() => {}}/>
        </div>

        {/* Section: Параметры */}
        <div style={{ fontSize: 11, fontWeight: 700, color: "#9CA3AF", letterSpacing: 0.6, textTransform: "uppercase", padding: "24px 22px 8px" }}>Параметры тела</div>
        <div style={{ background: "#fff", borderTop: "0.5px solid #F3F4F6" }}>
          <Row ic="⚖" name="Вес" sub="Последнее: 78.3 кг · 3 дня назад" action="78.3 кг ›" onClick={() => {}}/>
          <Row ic="📏" name="Рост" action="182 см ›" onClick={() => {}}/>
          <Row ic="🎂" name="Возраст" action="28 ›" onClick={() => {}}/>
        </div>

        {/* Section: Приложение */}
        <div style={{ fontSize: 11, fontWeight: 700, color: "#9CA3AF", letterSpacing: 0.6, textTransform: "uppercase", padding: "24px 22px 8px" }}>Приложение</div>
        <div style={{ background: "#fff", borderTop: "0.5px solid #F3F4F6" }}>
          <Row ic="🔔" name="Уведомления" action="Вкл ›" onClick={() => {}}/>
          <Row ic="🌐" name="Язык" action="Русский ›" onClick={() => {}}/>
          <Row ic="💳" name="Подписка" sub="Pro · продлевается 12.06.2026" action="›" onClick={() => {}}/>
          <Row ic="❌" name="Удалить аккаунт" action="›" onClick={() => {}}/>
          <Row ic="❓" name="Помощь и поддержка" action="›" onClick={() => {}}/>
        </div>

        <div style={{ padding: "24px 22px 16px", textAlign: "center" }}>
          <div style={{ fontSize: 13, color: "#EF4444", fontWeight: 600, cursor: "pointer" }}>Выйти из аккаунта</div>
          <div style={{ fontSize: 11, color: "#D1D5DB", marginTop: 14 }}>Кайфит · v2.4.1</div>
        </div>
      </div>
      <TabBar active={null} onNav={onNav} onAdd={onAdd}/>
    </div>
  );
};

const Journal = ({ onNav, onAdd, onOpenDetail }) => {
  const [openFood, setOpenFood] = useState(true);
  const [openTrain, setOpenTrain] = useState(true);
  const meals = [
    { name: "Овсянка с бананом", meta: "завтрак · 08:30", kcal: 340 },
    { name: "Куриная грудка + рис", meta: "обед · 13:15", kcal: 580 },
    { name: "Йогурт + ягоды", meta: "перекус · 16:00", kcal: 180 },
  ];
  const totalMeals = meals.length;
  const todayTraining = { tag: "Сегодня · 18:00", name: "Грудь и трицепс", t: "45", e: "8", k: "320", gr: "gr-coral" };
  const SectionHead = ({ title, count, sub, open, onToggle }) => (
    <div onClick={onToggle} style={{ display: "flex", alignItems: "center", gap: 10, padding: "14px 22px 10px", cursor: "pointer", userSelect: "none" }}>
      <div style={{ fontSize: 17, fontWeight: 800, color: "#111827", letterSpacing: -0.3 }}>{title}</div>
      <div style={{ fontSize: 12, fontWeight: 700, color: "#9CA3AF", fontFamily: "JetBrains Mono" }}>{count}</div>
      <div style={{ flex: 1, minWidth: 0, fontSize: 11, color: "#9CA3AF", fontWeight: 500, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{sub}</div>
      <div style={{ width: 24, height: 24, borderRadius: 12, background: "#F3F4F6", display: "flex", alignItems: "center", justifyContent: "center", color: "#6B7280", fontSize: 11, transition: "transform 0.2s", transform: open ? "rotate(0deg)" : "rotate(-90deg)" }}>⌄</div>
    </div>
  );
  return (
    <div className="phone">
      <div className="appbar">
        <div><div className="appbar-title">Журнал</div><div className="appbar-sub">Вс, 12 ноября · Неделя 3 из 8</div></div>
        <div className="appbar-action" onClick={() => onNav(SCREENS.ACCOUNT)} title="Аккаунт" style={{ background: "linear-gradient(135deg,#2563EB,#7C3AED)", color: "#fff", fontSize: 12, fontWeight: 800, letterSpacing: -0.3 }}>АК</div>
      </div>
      <div className="cal-strip">
        {[
          { d: "Пн", n: 6, st: "logged", train: "violet" },
          { d: "Вт", n: 7, st: "logged" },
          { d: "Ср", n: 8, st: "logged", train: "coral" },
          { d: "Чт", n: 9, st: "missed" },
          { d: "Пт", n: 10, st: "logged", train: "violet" },
          { d: "Сб", n: 11, st: "logged" },
          { d: "Вс", n: 12, st: "active", train: "coral" },
        ].map((x, i) => (
          <div className="cal-day" key={i}>
            <div className="cal-dn">{x.d}</div>
            <div className={`cal-num ${x.st}`}>{x.n}</div>
            <div className={`cal-tag ${x.train || "empty"}`}></div>
          </div>
        ))}
      </div>
      <div className="scroll">
        {/* Summary strip: calories + macros */}
        <div style={{ display: "flex", alignItems: "center", gap: 16, padding: "10px 22px 18px" }}>
          <MacroRings size={80}/>
          <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 8 }}>
            <div>
              <div style={{ fontSize: 10, fontWeight: 700, color: "#9CA3AF", textTransform: "uppercase", letterSpacing: 0.6 }}>Калории сегодня</div>
              <div style={{ display: "flex", alignItems: "baseline", gap: 6, marginTop: 2, whiteSpace: "nowrap" }}>
                <span style={{ fontFamily: "JetBrains Mono", fontSize: 26, fontWeight: 800, letterSpacing: "-0.5px" }}>1420</span>
                <span style={{ fontSize: 12, color: "#9CA3AF", fontWeight: 500 }}>/ 2100 ккал</span>
              </div>
            </div>
            <div style={{ display: "flex", gap: 12 }}>
              {[["#22C55E", "72g", "Б"], ["#06B6D4", "140g", "У"], ["#EAB308", "48g", "Ж"]].map(([c, g, l]) => (
                <div key={l} style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 11 }}>
                  <span style={{ width: 7, height: 7, borderRadius: 4, background: c }}></span>
                  <span style={{ fontFamily: "JetBrains Mono", fontWeight: 700 }}>{g}</span>
                  <span style={{ color: "#9CA3AF" }}>{l}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Еда — collapsible */}
        <SectionHead title="Еда" count={totalMeals} sub="1100 ккал · БЖУ 72/140/48" open={openFood} onToggle={() => setOpenFood(o => !o)}/>
        {openFood && (
          <div style={{ background: "#fff", borderTop: "0.5px solid #F3F4F6" }}>
            {meals.map((m, i) => (
              <div className="meal-row" key={i}>
                <div style={{ minWidth: 0 }}>
                  <div className="meal-name">{m.name}</div>
                  <div className="meal-meta">{m.meta}</div>
                </div>
                <div style={{ flexShrink: 0 }}><span className="meal-kcal">{m.kcal}</span></div>
              </div>
            ))}
            <div onClick={onAdd} style={{ padding: "12px 22px 16px", fontSize: 13, color: "#2563EB", fontWeight: 700, cursor: "pointer" }}>+ Добавить приём пищи</div>
          </div>
        )}

        {/* Тренировки — collapsible */}
        <SectionHead title="Тренировки" count={1} sub="На сегодня · Неделя 3/8" open={openTrain} onToggle={() => setOpenTrain(o => !o)}/>
        {openTrain && (
          <div style={{ padding: "0 20px 16px", display: "flex", flexDirection: "column", gap: 12 }}>
            <div className="train-card-bal" onClick={() => onOpenDetail(todayTraining)}>
              <div className={`train-hero ${todayTraining.gr}`}>
                <span className="train-hero-tag">{todayTraining.tag}</span>
                <div className="train-hero-title">{todayTraining.name}</div>
              </div>
              <div className="train-body">
                <div className="train-body-item"><span className="num">{todayTraining.t}</span> мин</div>
                <div className="train-body-item"><span className="num">{todayTraining.e}</span> упр.</div>
                <div className="train-body-item"><span className="num">~{todayTraining.k}</span> ккал</div>
              </div>
            </div>
            <div onClick={() => onNav(SCREENS.ACCOUNT)} style={{ textAlign: "center", padding: "6px 0", fontSize: 12, color: "#9CA3AF" }}>Следующая: Пт, 09:00 · Ноги ›</div>
          </div>
        )}
      </div>
      <TabBar active={SCREENS.JOURNAL} onNav={onNav} onAdd={onAdd}/>
    </div>
  );
};

const Pitanie = ({ onNav, onAdd }) => (
  <div className="phone">
    <div className="appbar">
      <div><div className="appbar-title">Питание</div><div className="appbar-sub">Вс, 12 ноября</div></div>
      <div className="appbar-action">🇷🇺</div>
    </div>
    <div className="cal-strip">
      {[
        { d: "Пн", n: 6, st: "logged", train: "violet" },
        { d: "Вт", n: 7, st: "logged" },
        { d: "Ср", n: 8, st: "logged", train: "coral" },
        { d: "Чт", n: 9, st: "missed" },
        { d: "Пт", n: 10, st: "logged", train: "violet" },
        { d: "Сб", n: 11, st: "logged" },
        { d: "Вс", n: 12, st: "active", train: "coral" },
      ].map((x, i) => (
        <div className="cal-day" key={i}>
          <div className="cal-dn">{x.d}</div>
          <div className={`cal-num ${x.st}`}>{x.n}</div>
          <div className={`cal-tag ${x.train || "empty"}`}></div>
        </div>
      ))}
    </div>
    <div className="scroll">
      <div style={{ display: "flex", alignItems: "center", gap: 16, padding: "10px 22px 16px" }}>
        <MacroRings size={80}/>
        <div style={{ flex: 1, minWidth: 0, display: "flex", flexDirection: "column", gap: 8 }}>
          <div>
            <div style={{ fontSize: 10, fontWeight: 700, color: "#9CA3AF", textTransform: "uppercase", letterSpacing: 0.6 }}>Калории сегодня</div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 6, marginTop: 2, whiteSpace: "nowrap" }}>
              <span style={{ fontFamily: "JetBrains Mono", fontSize: 26, fontWeight: 800, letterSpacing: "-0.5px" }}>1420</span>
              <span style={{ fontSize: 12, color: "#9CA3AF", fontWeight: 500 }}>/ 2100 ккал</span>
            </div>
          </div>
          <div style={{ display: "flex", gap: 12 }}>
            {[["#22C55E", "72g", "Б"], ["#06B6D4", "140g", "У"], ["#EAB308", "48g", "Ж"]].map(([c, g, l]) => (
              <div key={l} style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 11 }}>
                <span style={{ width: 7, height: 7, borderRadius: 4, background: c }}></span>
                <span style={{ fontFamily: "JetBrains Mono", fontWeight: 700 }}>{g}</span>
                <span style={{ color: "#9CA3AF" }}>{l}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="k-section-title">Еда <span className="more">3</span></div>
      <div className="meal-row"><div><div className="meal-name">Овсянка с бананом</div><div className="meal-meta">Завтрак · 08:30</div></div><div><span className="meal-kcal">340</span><span className="meal-kcal-u"> ккал</span></div></div>
      <div className="meal-row"><div><div className="meal-name">Куриная грудка + рис</div><div className="meal-meta">Обед · 13:15</div></div><div><span className="meal-kcal">580</span><span className="meal-kcal-u"> ккал</span></div></div>
      <div className="meal-row"><div><div className="meal-name">Йогурт + ягоды</div><div className="meal-meta">Перекус · 16:00</div></div><div><span className="meal-kcal">180</span><span className="meal-kcal-u"> ккал</span></div></div>
    </div>
    <TabBar active={SCREENS.PITANIE} onNav={onNav} onAdd={onAdd}/>
  </div>
);

const Trainings = ({ onNav, onAdd, onOpenDetail }) => (
  <div className="phone">
    <div className="appbar">
      <div><div className="appbar-title">Тренировки</div><div className="appbar-sub">Программа · Неделя 3 из 8</div></div>
      <div className="appbar-action">⚙️</div>
    </div>
    <div style={{ padding: "0 22px 16px" }}>
      <div style={{ display: "flex", gap: 10, alignItems: "center", padding: "12px 16px", background: "#EFF6FF", borderRadius: 14 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, color: "#1D4ED8", fontWeight: 700, textTransform: "uppercase", letterSpacing: 0.5 }}>Прогресс недели</div>
          <div style={{ fontSize: 16, fontWeight: 800, color: "#1D4ED8", marginTop: 2 }}>3 из 4 тренировок</div>
        </div>
        <div style={{ width: 48, height: 48, borderRadius: 24, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "JetBrains Mono", fontWeight: 800, color: "#2563EB", fontSize: 14 }}>75%</div>
      </div>
    </div>
    <div className="scroll">
      <div style={{ padding: "0 20px 16px", display: "flex", flexDirection: "column", gap: 12 }}>
        {[
          { tag: "Сегодня · 18:00", name: "Грудь и трицепс", t: "45", e: "8", k: "320", gr: "gr-coral" },
          { tag: "Пт · 09:00", name: "Ноги", t: "50", e: "7", k: "380", gr: "gr-violet" },
          { tag: "Сб · 11:00", name: "Плечи и пресс", t: "40", e: "6", k: "260", gr: "gr-graph" },
          { tag: "Пн · 19:00", name: "Спина и бицепс", t: "45", e: "8", k: "340", gr: "gr-cyan" },
        ].map((x, i) => (
          <div key={i} className="train-card-bal" onClick={() => onOpenDetail(x)}>
            <div className={`train-hero ${x.gr}`}>
              <span className="train-hero-tag">{x.tag}</span>
              <div className="train-hero-title">{x.name}</div>
            </div>
            <div className="train-body">
              <div className="train-body-item"><span className="num">{x.t}</span> мин</div>
              <div className="train-body-item"><span className="num">{x.e}</span> упр.</div>
              <div className="train-body-item"><span className="num">~{x.k}</span> ккал</div>
            </div>
          </div>
        ))}
      </div>
    </div>
    <TabBar active={SCREENS.TRAININGS} onNav={onNav} onAdd={onAdd}/>
  </div>
);

const Detail = ({ workout, onBack, onStart }) => {
  const w = workout || { name: "Грудь и трицепс", gr: "gr-coral", t: "45", e: "8", k: "320", tag: "Сегодня · 18:00" };
  const gradMap = {
    "gr-coral":  "linear-gradient(135deg,#F97316,#F43F5E)",
    "gr-violet": "linear-gradient(135deg,#8B5CF6,#6366F1)",
    "gr-graph":  "linear-gradient(135deg,#1F2937,#374151)",
    "gr-cyan":   "linear-gradient(135deg,#06B6D4,#0284C7)",
  };
  return (
    <div className="phone">
      <div style={{ height: 240, position: "relative" }}>
        <div style={{ position: "absolute", inset: 0, background: gradMap[w.gr] }}></div>
        <div style={{ position: "absolute", inset: 0, padding: "68px 22px 24px", display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
          <div style={{ display: "flex", justifyContent: "space-between" }}>
            <div className="appbar-back" style={{ background: "rgba(255,255,255,0.22)", color: "#fff", backdropFilter: "blur(8px)" }} onClick={onBack}>←</div>
            <div className="appbar-action" style={{ background: "rgba(255,255,255,0.22)", color: "#fff", backdropFilter: "blur(8px)" }}>⋯</div>
          </div>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, color: "rgba(255,255,255,0.9)", textTransform: "uppercase", letterSpacing: 0.6, marginBottom: 8 }}>{w.tag}</div>
            <div style={{ fontSize: 28, fontWeight: 800, color: "#fff", letterSpacing: "-0.5px", lineHeight: 1.05 }}>{w.name}</div>
          </div>
        </div>
      </div>
      <div className="scroll">
        <div style={{ margin: "16px 22px", padding: "14px 16px", background: "#F9FAFB", borderRadius: 16, display: "flex", justifyContent: "space-between" }}>
          {[[w.t, "МИН"], [w.k, "ККАЛ"], [w.e, "УПР."]].map(([v, l], i, a) => (
            <React.Fragment key={l}>
              <div style={{ textAlign: "center", flex: 1 }}><div style={{ fontFamily: "JetBrains Mono", fontSize: 20, fontWeight: 800 }}>{v}</div><div style={{ fontSize: 10, color: "#9CA3AF", fontWeight: 600, marginTop: 2 }}>{l}</div></div>
              {i < a.length - 1 && <div style={{ width: 1, background: "#E5E7EB" }}></div>}
            </React.Fragment>
          ))}
        </div>
        <div className="k-section-title">Упражнения <span className="more">{w.e}</span></div>
        <div style={{ padding: "0 22px 16px" }}>
          {[
            ["Жим штанги лёжа", "4 × 8–10"],
            ["Жим гантелей на наклонной", "3 × 10"],
            ["Разводка гантелей", "3 × 12"],
            ["Французский жим", "3 × 12"],
            ["Разгибания на блоке", "3 × 15"],
          ].map(([n, s], i) => (
            <div className="ex-row" key={i}>
              <div className="ex-num">{i + 1}</div>
              <div className="ex-info"><div className="ex-name">{n}</div><div className="ex-sets">{s}</div></div>
              <div className="ex-thumb" style={{ background: "linear-gradient(135deg,#FED7AA,#FBA74F)" }}>🏋️</div>
            </div>
          ))}
        </div>
      </div>
      <div style={{ padding: "12px 22px 24px" }}><div className="btn-blue" onClick={onStart}>Начать тренировку</div></div>
    </div>
  );
};

const Live = ({ onExit, onFinish }) => {
  const exercises = [
    { name: "Жим штанги лёжа",            sets: 4, reps: 10, w: 60, ic: "🏋️" },
    { name: "Жим гантелей на наклонной",  sets: 3, reps: 10, w: 22, ic: "🏋️" },
    { name: "Разводка гантелей",          sets: 3, reps: 12, w: 12, ic: "💪" },
    { name: "Французский жим",            sets: 3, reps: 12, w: 18, ic: "💪" },
    { name: "Разгибания на блоке",        sets: 3, reps: 15, w: 25, ic: "🔥" },
  ];
  const [exIdx, setExIdx] = useState(0);
  const [setIdx, setSetIdx] = useState(0);
  const [reps, setReps] = useState(exercises[0].reps);
  const [w, setW] = useState(exercises[0].w);

  const ex = exercises[exIdx];
  const totalSets = ex.sets;
  const totalExercises = exercises.length;

  const next = () => {
    if (setIdx + 1 < totalSets) {
      setSetIdx(setIdx + 1);
    } else if (exIdx + 1 < totalExercises) {
      const ni = exIdx + 1;
      setExIdx(ni); setSetIdx(0);
      setReps(exercises[ni].reps); setW(exercises[ni].w);
    } else {
      onFinish();
    }
  };
  const progressPct = ((exIdx * 100) / totalExercises) + (((setIdx + 1) / totalSets) * (100 / totalExercises));

  return (
    <div className="phone">
      <div className="appbar">
        <div className="appbar-back" onClick={onExit}>×</div>
        <div style={{ flex: 1, padding: "0 16px" }}>
          <div style={{ height: 6, background: "#F3F4F6", borderRadius: 999, overflow: "hidden" }}>
            <div style={{ width: `${progressPct}%`, height: "100%", background: "linear-gradient(90deg,#F97316,#F43F5E)", transition: "width 0.3s" }}></div>
          </div>
          <div style={{ fontSize: 11, color: "#9CA3AF", fontWeight: 600, marginTop: 5, textAlign: "center" }}>Упражнение {exIdx + 1} из {totalExercises}</div>
        </div>
        <div className="appbar-action" style={{ background: "transparent" }}>⏸</div>
      </div>
      <div className="scroll">
        <div className="live-img" style={{ background: "linear-gradient(135deg,#FED7AA,#FBA74F)" }}>{ex.ic}</div>
        <div className="live-name">{ex.name}</div>
        <div className="live-meta">Подход {setIdx + 1} из {totalSets}</div>
        <div className="set-card">
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 16 }}>
            {Array.from({ length: totalSets }).map((_, i) => (
              <div key={i} style={{ flex: 1, textAlign: "center" }}>
                <div style={{ fontSize: 10, color: "#9CA3AF", fontWeight: 700, textTransform: "uppercase", marginBottom: 5 }}>Подход {i + 1}</div>
                <div style={{
                  margin: "0 auto", width: 44, height: 44, borderRadius: 22,
                  background: i < setIdx ? "#22C55E" : i === setIdx ? "#F97316" : "#F3F4F6",
                  color: i <= setIdx ? "#fff" : "#9CA3AF",
                  display: "flex", alignItems: "center", justifyContent: "center",
                  fontWeight: 800, fontSize: 14
                }}>{i < setIdx ? "✓" : i === setIdx ? "•" : "—"}</div>
              </div>
            ))}
          </div>
          <div className="counter-row">
            <span className="counter-label">Повторения</span>
            <div className="counter-controls">
              <div className="counter-btn" onClick={() => setReps(Math.max(1, reps - 1))}>−</div>
              <div className="counter-val">{reps}</div>
              <div className="counter-btn" onClick={() => setReps(reps + 1)}>+</div>
            </div>
          </div>
          <div className="counter-row">
            <span className="counter-label">Вес, кг</span>
            <div className="counter-controls">
              <div className="counter-btn" onClick={() => setW(Math.max(0, w - 1))}>−</div>
              <div className="counter-val">{w}</div>
              <div className="counter-btn" onClick={() => setW(w + 1)}>+</div>
            </div>
          </div>
        </div>
      </div>
      <div style={{ padding: "14px 22px 24px", display: "flex", gap: 10 }}>
        <div className="btn-outline" style={{ flex: 1 }} onClick={next}>Пропустить</div>
        <div className="btn-coral" style={{ flex: 2 }} onClick={next}>Подход выполнен</div>
      </div>
    </div>
  );
};

const Chat = ({ onNav, onAdd }) => {
  const [mode, setMode] = useState("nutri");
  const nutriMsgs = [
    { role: "ai", text: "Я записал твой обед — 580 ккал. Хочешь, посчитаю, сколько белка ещё нужно сегодня?" },
    { role: "user", text: "Давай" },
    { role: "ai", text: "До цели 145г белка осталось 48г. Это ~200г куриной грудки или 2 порции творога." },
    { role: "user", text: "А чай с молоком сильно повлияет?" },
    { role: "ai", text: "+30 ккал и 1.5г белка — не критично. Записал." },
  ];
  const trainMsgs = [
    { role: "ai", text: "Что чувствуешь после жима? Спина прижата к скамье?" },
    { role: "user", text: "Локти чуть болят" },
    { role: "ai", text: "Возможно, разводишь их слишком широко. Попробуй угол 45° к корпусу. Снизит нагрузку на плечи и локти." },
    { role: "user", text: "Ок, попробую" },
  ];
  const msgs = mode === "nutri" ? nutriMsgs : trainMsgs;
  return (
    <div className="phone">
      <div className="appbar">
        <div><div className="appbar-title">AI ассистент</div></div>
        <div className="appbar-action">📜</div>
      </div>
      <div className="chat-modes-bal">
        <div className={`chat-mode-bal nutri ${mode === "nutri" ? "on" : ""}`} onClick={() => setMode("nutri")}>
          <div className="ic">🥗</div><div className="lb">Питание</div><div className="desc">Калории, БЖУ, рецепты</div>
        </div>
        <div className={`chat-mode-bal train ${mode === "train" ? "on" : ""}`} onClick={() => setMode("train")}>
          <div className="ic">🏋️</div><div className="lb">Тренировки</div><div className="desc">Программа, форма, советы</div>
        </div>
      </div>
      <div className="scroll" style={{ padding: "8px 20px 12px", display: "flex", flexDirection: "column", gap: 10 }}>
        {msgs.map((m, i) => (
          <div key={i} className={`bubble ${m.role === "ai" ? "ai" : "user blue"}`}>{m.text}</div>
        ))}
      </div>
      <div className="chat-input">
        <span className="chat-input-txt">{mode === "nutri" ? "Что ты ел сегодня?" : "Спроси про технику…"}</span>
        <div className="chat-input-mic">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><rect x="9" y="3" width="6" height="12" rx="3" fill="#fff"/><path d="M5 11a7 7 0 0 0 14 0 M12 18v3" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>
        </div>
      </div>
      <TabBar active={SCREENS.CHAT} onNav={onNav} onAdd={onAdd}/>
    </div>
  );
};

// ─── Add sheet ─────────────────────────────
const AddSheet = ({ onClose, onTrain }) => (
  <div className="sheet-back" onClick={onClose}>
    <div className="sheet" onClick={(e) => e.stopPropagation()}>
      <div className="sheet-grab"></div>
      <div className="sheet-title">Что добавить?</div>
      <div className="sheet-opt">
        <div className="sheet-opt-ic" style={{ background: "linear-gradient(135deg,#22C55E,#16A34A)" }}>🥗</div>
        <div className="sheet-opt-info"><div className="sheet-opt-name">Запись еды</div><div className="sheet-opt-desc">Сфоткать, описать или из списка</div></div>
        <div style={{ color: "#9CA3AF" }}>›</div>
      </div>
      <div className="sheet-opt" onClick={onTrain}>
        <div className="sheet-opt-ic" style={{ background: "linear-gradient(135deg,#F97316,#F43F5E)" }}>🏋️</div>
        <div className="sheet-opt-info"><div className="sheet-opt-name">Тренировка</div><div className="sheet-opt-desc">Начать или запланировать</div></div>
        <div style={{ color: "#9CA3AF" }}>›</div>
      </div>
      <div className="sheet-opt">
        <div className="sheet-opt-ic" style={{ background: "linear-gradient(135deg,#06B6D4,#0284C7)" }}>💧</div>
        <div className="sheet-opt-info"><div className="sheet-opt-name">Вода</div><div className="sheet-opt-desc">Быстрая запись стакана</div></div>
        <div style={{ color: "#9CA3AF" }}>›</div>
      </div>
      <div className="sheet-opt">
        <div className="sheet-opt-ic" style={{ background: "linear-gradient(135deg,#8B5CF6,#6366F1)" }}>⚖️</div>
        <div className="sheet-opt-info"><div className="sheet-opt-name">Вес и замеры</div><div className="sheet-opt-desc">Утреннее взвешивание</div></div>
        <div style={{ color: "#9CA3AF" }}>›</div>
      </div>
    </div>
  </div>
);

// ─── App root ─────────────────────────────
const App = () => {
  const [screen, setScreen] = useState(SCREENS.OB_MODULES);
  const [workout, setWorkout] = useState(null);
  const [sheet, setSheet] = useState(false);

  React.useEffect(() => {
    window.__resetApp = () => { setScreen(SCREENS.OB_MODULES); setWorkout(null); setSheet(false); };
  }, []);

  const onAdd = () => setScreen(SCREENS.CHAT);

  return (
    <div style={{ position: "relative" }}>
      {screen === SCREENS.OB_MODULES && <ObModules onNext={() => setScreen(SCREENS.OB_EQUIP)}/>}
      {screen === SCREENS.OB_EQUIP   && <ObEquipment onBack={() => setScreen(SCREENS.OB_MODULES)} onDone={() => setScreen(SCREENS.JOURNAL)}/>}
      {screen === SCREENS.JOURNAL    && <Journal onNav={setScreen} onAdd={onAdd} onOpenDetail={(w) => { setWorkout(w); setScreen(SCREENS.DETAIL); }}/>}
      {screen === SCREENS.CHAT       && <Chat onNav={setScreen} onAdd={onAdd}/>}
      {screen === SCREENS.ACCOUNT    && <Account onNav={setScreen} onAdd={onAdd}/>}
      {screen === SCREENS.DETAIL     && <Detail workout={workout} onBack={() => setScreen(SCREENS.TRAININGS)} onStart={() => setScreen(SCREENS.LIVE)}/>}
      {screen === SCREENS.LIVE       && <Live onExit={() => setScreen(SCREENS.DETAIL)} onFinish={() => setScreen(SCREENS.TRAININGS)}/>}
      {sheet && <AddSheet onClose={() => setSheet(false)} onTrain={() => { setSheet(false); setScreen(SCREENS.TRAININGS); }}/>}
    </div>
  );
};

ReactDOM.createRoot(document.getElementById("root")).render(<App/>);
