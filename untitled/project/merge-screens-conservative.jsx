// CONSERVATIVE variant — minimal change to KayFit; one Тренировки tab + simple reuse of patterns.

// Screen 1: Onboarding "что нужно?"
const ConsOnboarding = () => (
  <Phone noTab>
    <div className="appbar">
      <div className="appbar-back">←</div>
      <div></div>
    </div>
    <div className="ob-progress">
      <div className="ob-seg on"></div><div className="ob-seg on"></div>
      <div className="ob-seg"></div><div className="ob-seg"></div>
    </div>
    <div className="ob-h1">С чем тебе помочь?</div>
    <div className="ob-sub">Можешь выбрать что-то одно — потом всегда добавишь второе.</div>
    <div style={{ display: "flex", flexDirection: "column", gap: 10, padding: "0 20px" }}>
      <div className="goal-card on">
        <div className="goal-icon">🥗</div>
        <div><div className="goal-name">Питание</div><div className="goal-desc">Считать калории, БЖУ, вести дневник</div></div>
      </div>
      <div className="goal-card">
        <div className="goal-icon">🏋️</div>
        <div><div className="goal-name">Тренировки</div><div className="goal-desc">План занятий и AI-тренер</div></div>
      </div>
      <div className="goal-card">
        <div className="goal-icon">⚡</div>
        <div><div className="goal-name">И то, и другое</div><div className="goal-desc">Полный набор инструментов</div></div>
      </div>
    </div>
    <div style={{ padding: "20px", marginTop: "auto" }}><div className="btn-blue">Продолжить</div></div>
  </Phone>
);

// Screen 2: Equipment
const ConsEquipment = () => (
  <Phone noTab>
    <div className="appbar">
      <div className="appbar-back">←</div>
      <div></div>
    </div>
    <div className="ob-progress">
      <div className="ob-seg on"></div><div className="ob-seg on"></div>
      <div className="ob-seg on"></div><div className="ob-seg"></div>
    </div>
    <div className="ob-h1">Что у тебя есть?</div>
    <div className="ob-sub">Выбери оборудование — план подстроится.</div>
    <div style={{ padding: "0 20px", display: "flex", flexWrap: "wrap", gap: 8 }}>
      <div className="eq-chip on"><span className="ico">🏋️</span> Гантели</div>
      <div className="eq-chip on"><span className="ico">⚡</span> Штанга</div>
      <div className="eq-chip"><span className="ico">🔝</span> Турник</div>
      <div className="eq-chip on"><span className="ico">🪑</span> Скамья</div>
      <div className="eq-chip"><span className="ico">🏭</span> Тренажёры</div>
      <div className="eq-chip"><span className="ico">🟩</span> Коврик</div>
      <div className="eq-chip"><span className="ico">🟡</span> Резинки</div>
      <div className="eq-chip"><span className="ico">⛔</span> Ничего</div>
    </div>
    <div style={{ padding: "20px", marginTop: "auto" }}><div className="btn-blue">Продолжить</div></div>
  </Phone>
);

// Screen 3: Journal with workout dots
const ConsJournal = () => (
  <Phone tab="journal">
    <div className="appbar">
      <div><div className="appbar-title">Журнал</div><div className="appbar-sub">Сегодня, 12 ноября</div></div>
      <div className="appbar-action">🇷🇺</div>
    </div>
    <div className="cal-strip">
      {[
        { d: "Пн", n: 6, st: "logged" }, { d: "Вт", n: 7, st: "logged", train: true },
        { d: "Ср", n: 8, st: "logged" }, { d: "Чт", n: 9, st: "missed" },
        { d: "Пт", n: 10, st: "logged", train: true }, { d: "Сб", n: 11, st: "logged" },
        { d: "Вс", n: 12, st: "active", train: true },
      ].map((x, i) => (
        <div className="cal-day" key={i}>
          <div className="cal-dn">{x.d}</div>
          <div className={`cal-num ${x.st}`}>{x.n}</div>
          {x.train ? <div className="cal-tag"></div> : <div style={{ height: 5 }}></div>}
        </div>
      ))}
    </div>
    <div className="scroll">
      <div style={{ display: "flex", flexDirection: "column", alignItems: "center", padding: "8px 0 4px" }}>
        <MacroRings size={120} />
        <div style={{ marginTop: -78, textAlign: "center", pointerEvents: "none" }}>
          <div style={{ fontFamily: "JetBrains Mono", fontSize: 22, fontWeight: 800, color: "#111827" }}>1420</div>
          <div style={{ fontSize: 9, color: "#9CA3AF", fontWeight: 600 }}>из 2100 ккал</div>
        </div>
      </div>
      <div style={{ padding: "0 18px 8px", display: "flex", gap: 8 }}>
        <div className="mp"><div className="mp-val" style={{ color: "#22C55E" }}>72g</div><div className="mp-lbl">Белок</div></div>
        <div className="mp"><div className="mp-val" style={{ color: "#06B6D4" }}>140g</div><div className="mp-lbl">Углев</div></div>
        <div className="mp"><div className="mp-val" style={{ color: "#CA8A04" }}>48g</div><div className="mp-lbl">Жир</div></div>
      </div>
      <div className="k-section-title">Еда сегодня <span className="more">3</span></div>
      <div className="meal-row"><div><div className="meal-name">Овсянка с бананом</div><div className="meal-meta">Завтрак · 08:30</div></div><div><span className="meal-kcal">340</span><span className="meal-kcal-u"> ккал</span></div></div>
      <div className="meal-row"><div><div className="meal-name">Куриная грудка + рис</div><div className="meal-meta">Обед · 13:15</div></div><div><span className="meal-kcal">580</span><span className="meal-kcal-u"> ккал</span></div></div>
      <div className="meal-row"><div><div className="meal-name">Творог + ягоды</div><div className="meal-meta">Перекус · 16:40</div></div><div><span className="meal-kcal">220</span><span className="meal-kcal-u"> ккал</span></div></div>

      <div className="k-section-title">Тренировка <span className="more">1</span></div>
      <div style={{ padding: "0 18px 16px" }}>
        <div className="train-card-cons">
          <div className="train-thumb-cons">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M6 8v8 M3 10v4 M18 8v8 M21 10v4 M6 12h12" stroke="#2563EB" strokeWidth="2" strokeLinecap="round"/></svg>
          </div>
          <div style={{ flex: 1 }}>
            <div className="train-name">Грудь и трицепс</div>
            <div className="train-meta">8 упражнений · 45 мин · Сегодня 18:00</div>
          </div>
          <div style={{ color: "#9CA3AF" }}>›</div>
        </div>
      </div>
    </div>
  </Phone>
);

// Screen 4: Тренировки list
const ConsTrainings = () => (
  <Phone tab="training">
    <div className="appbar">
      <div><div className="appbar-title">Тренировки</div><div className="appbar-sub">Программа · Неделя 3</div></div>
      <div className="appbar-action">⚙️</div>
    </div>
    <div className="cal-strip">
      {["Пн","Вт","Ср","Чт","Пт","Сб","Вс"].map((d,i)=>{
        const trains = [true,false,true,false,true,false,false];
        const today = i===6;
        return <div className="cal-day" key={i}>
          <div className="cal-dn">{d}</div>
          <div className={`cal-num ${today?"active":""}`}>{6+i}</div>
          {trains[i]?<div className="cal-tag"></div>:<div style={{height:5}}></div>}
        </div>;
      })}
    </div>
    <div className="scroll">
      <div className="k-section-title">На этой неделе <span className="more">3 из 4</span></div>
      <div style={{ padding: "0 18px 8px", display: "flex", flexDirection: "column", gap: 10 }}>
        <div className="train-card-cons" style={{ borderColor: "#22C55E", background: "#F0FDF4" }}>
          <div className="train-thumb-cons" style={{ background: "#DCFCE7" }}>
            <svg width="20" height="20" viewBox="0 0 24 24"><path d="M5 12l5 5 9-11" stroke="#22C55E" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
          </div>
          <div style={{ flex: 1 }}>
            <div className="train-name">Спина и бицепс</div>
            <div className="train-meta">Пн · 42 мин · Завершено</div>
          </div>
        </div>
        <div className="train-card-cons">
          <div className="train-thumb-cons"><span style={{ fontSize: 18 }}>💪</span></div>
          <div style={{ flex: 1 }}>
            <div className="train-name">Грудь и трицепс</div>
            <div className="train-meta">Сегодня · 45 мин · 8 упражнений</div>
          </div>
          <div style={{ color: "#9CA3AF" }}>›</div>
        </div>
        <div className="train-card-cons">
          <div className="train-thumb-cons"><span style={{ fontSize: 18 }}>🦵</span></div>
          <div style={{ flex: 1 }}>
            <div className="train-name">Ноги</div>
            <div className="train-meta">Пт · 50 мин · 7 упражнений</div>
          </div>
          <div style={{ color: "#9CA3AF" }}>›</div>
        </div>
      </div>
      <div className="k-section-title">Библиотека</div>
      <div style={{ padding: "0 18px 16px", display: "flex", flexDirection: "column", gap: 10 }}>
        <div className="train-card-cons">
          <div className="train-thumb-cons"><span style={{ fontSize: 18 }}>🧘</span></div>
          <div style={{ flex: 1 }}><div className="train-name">Растяжка</div><div className="train-meta">15 мин · Без оборудования</div></div>
          <div style={{ color: "#9CA3AF" }}>›</div>
        </div>
        <div className="train-card-cons">
          <div className="train-thumb-cons"><span style={{ fontSize: 18 }}>🏃</span></div>
          <div style={{ flex: 1 }}><div className="train-name">Кардио — HIIT</div><div className="train-meta">25 мин · Высокая</div></div>
          <div style={{ color: "#9CA3AF" }}>›</div>
        </div>
      </div>
    </div>
  </Phone>
);

// Screen 5: Workout detail
const ConsDetail = () => (
  <Phone tab="training">
    <div className="appbar">
      <div className="appbar-back">←</div>
      <div className="appbar-action">⋯</div>
    </div>
    <div className="scroll">
      <div style={{ padding: "0 20px 16px" }}>
        <div style={{ height: 130, borderRadius: 16, background: "linear-gradient(135deg,#DBEAFE,#BFDBFE)", display: "flex", alignItems: "flex-end", padding: 14 }}>
          <div style={{ fontSize: 38 }}>💪</div>
        </div>
        <div style={{ fontSize: 22, fontWeight: 800, color: "#111827", marginTop: 14, letterSpacing: "-0.3px" }}>Грудь и трицепс</div>
        <div style={{ fontSize: 12, color: "#9CA3AF", marginTop: 4, fontWeight: 500 }}>Средний уровень · 8 упражнений · ~45 мин</div>
      </div>
      <div style={{ margin: "0 20px 14px", padding: "12px 16px", background: "#F9FAFB", borderRadius: 14, display: "flex", justifyContent: "space-between" }}>
        <div style={{ textAlign: "center" }}><div style={{ fontFamily: "JetBrains Mono", fontSize: 16, fontWeight: 800 }}>45</div><div style={{ fontSize: 10, color: "#9CA3AF" }}>МИН</div></div>
        <div style={{ width: 1, background: "#E5E7EB" }}></div>
        <div style={{ textAlign: "center" }}><div style={{ fontFamily: "JetBrains Mono", fontSize: 16, fontWeight: 800 }}>320</div><div style={{ fontSize: 10, color: "#9CA3AF" }}>ККАЛ</div></div>
        <div style={{ width: 1, background: "#E5E7EB" }}></div>
        <div style={{ textAlign: "center" }}><div style={{ fontFamily: "JetBrains Mono", fontSize: 16, fontWeight: 800 }}>8</div><div style={{ fontSize: 10, color: "#9CA3AF" }}>УПР.</div></div>
      </div>
      <div className="k-section-title">Упражнения</div>
      <div style={{ padding: "0 18px 16px" }}>
        {[
          ["Жим штанги лёжа", "4 × 8–10"],
          ["Жим гантелей на наклонной", "3 × 10"],
          ["Разводка гантелей", "3 × 12"],
          ["Отжимания на брусьях", "3 × макс"],
          ["Французский жим", "3 × 12"],
          ["Разгибания на блоке", "3 × 15"],
        ].map(([n, s], i) => (
          <div className="ex-row" key={i}>
            <div className="ex-num">{i + 1}</div>
            <div className="ex-info"><div className="ex-name">{n}</div><div className="ex-sets">{s}</div></div>
            <div className="ex-thumb">🏋️</div>
          </div>
        ))}
      </div>
      <div style={{ padding: "0 20px 20px" }}><div className="btn-blue">Начать тренировку</div></div>
    </div>
  </Phone>
);

// Screen 6: Chat with mode switcher
const ConsChat = () => (
  <Phone tab="chat">
    <div className="appbar">
      <div><div className="appbar-title">AI ассистент</div><div className="appbar-sub">Онлайн</div></div>
      <div className="appbar-action">📜</div>
    </div>
    <div className="chat-modes">
      <div className="chat-mode nutri on"><span className="dot"></span> Питание</div>
      <div className="chat-mode train"><span className="dot"></span> Тренировки</div>
    </div>
    <div className="scroll" style={{ padding: "0 18px", display: "flex", flexDirection: "column", gap: 10 }}>
      <div className="bubble ai"><div className="src">Питание · AI</div>Привет! Я твой нутрициолог. Что съел сегодня?</div>
      <div className="bubble user blue">Овсянка с бананом и кофе</div>
      <div className="bubble ai">Записал: 340 ккал, 9г белка. Не хочешь добавить ложку протеина в овсянку? Догонишь норму белка к обеду.</div>
      <div className="bubble user blue">Хорошая идея</div>
      <div className="bubble ai"><div className="src">Питание · AI</div>Готово 👍 Цель белка на день: 145г. Сейчас ~25г.</div>
    </div>
    <div className="chat-input">
      <span className="chat-input-txt">Спроси что-нибудь…</span>
      <div className="chat-input-mic">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><rect x="9" y="3" width="6" height="12" rx="3" fill="#fff"/><path d="M5 11a7 7 0 0 0 14 0 M12 18v3" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>
      </div>
    </div>
  </Phone>
);

// Screen 7: Live workout (light)
const ConsLive = () => (
  <Phone noTab>
    <div className="appbar">
      <div className="appbar-back">×</div>
      <div style={{ fontSize: 13, fontWeight: 600, color: "#9CA3AF" }}>3 / 8</div>
      <div className="appbar-action" style={{ background: "transparent" }}>⏸</div>
    </div>
    <div className="scroll">
      <div className="live-img">🏋️</div>
      <div className="live-name">Жим гантелей на наклонной</div>
      <div className="live-meta">Подход 2 из 3 · 90 сек отдых</div>
      <div className="set-card">
        <div className="set-card-title">Текущий подход</div>
        <div className="counter-row">
          <span className="counter-label">Повторения</span>
          <div className="counter-controls">
            <div className="counter-btn">−</div>
            <div className="counter-val">10</div>
            <div className="counter-btn">+</div>
          </div>
        </div>
        <div className="counter-row">
          <span className="counter-label">Вес, кг</span>
          <div className="counter-controls">
            <div className="counter-btn">−</div>
            <div className="counter-val">22</div>
            <div className="counter-btn">+</div>
          </div>
        </div>
      </div>
    </div>
    <div style={{ padding: "12px 20px 24px", display: "flex", gap: 10 }}>
      <div className="btn-outline" style={{ flex: 1 }}>Пропустить</div>
      <div className="btn-blue" style={{ flex: 2 }}>Подход выполнен</div>
    </div>
  </Phone>
);

Object.assign(window, { ConsOnboarding, ConsEquipment, ConsJournal, ConsTrainings, ConsDetail, ConsChat, ConsLive });
