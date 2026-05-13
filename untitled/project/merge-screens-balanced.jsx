// BALANCED variant — thoughtful integration: workout cards with hero gradients,
// dual-indicator calendar (food ring + workout dot), prominent chat mode pills.

const BalOnboarding = () => (
  <Phone noTab>
    <div className="appbar"><div className="appbar-back">←</div><div></div></div>
    <div className="ob-progress">
      <div className="ob-seg on"></div><div className="ob-seg on"></div>
      <div className="ob-seg"></div><div className="ob-seg"></div>
    </div>
    <div className="ob-h1">Расскажи о своих целях</div>
    <div className="ob-sub">Включи нужные модули — приложение перестроится под тебя.</div>
    <div style={{ display: "flex", flexDirection: "column", gap: 10, padding: "0 20px" }}>
      <div className="goal-card on" style={{ flexDirection: "column", alignItems: "stretch", gap: 12 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div className="goal-icon" style={{ background: "#DBEAFE" }}>🥗</div>
          <div style={{ flex: 1 }}>
            <div className="goal-name">Питание</div>
            <div className="goal-desc">Дневник, БЖУ, AI-нутрициолог</div>
          </div>
          <div style={{ width: 22, height: 22, borderRadius: 11, background: "#2563EB", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <svg width="11" height="11" viewBox="0 0 24 24"><path d="M5 12l5 5 9-11" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
          </div>
        </div>
      </div>
      <div className="goal-card on">
        <div className="goal-icon" style={{ background: "#FFEDD5" }}>🏋️</div>
        <div style={{ flex: 1 }}>
          <div className="goal-name">Тренировки</div>
          <div className="goal-desc">Программы, упражнения, AI-тренер</div>
        </div>
        <div style={{ width: 22, height: 22, borderRadius: 11, background: "#2563EB", display: "flex", alignItems: "center", justifyContent: "center" }}>
          <svg width="11" height="11" viewBox="0 0 24 24"><path d="M5 12l5 5 9-11" stroke="#fff" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
        </div>
      </div>
      <div style={{ padding: "8px 4px", fontSize: 11, color: "#9CA3AF", display: "flex", alignItems: "center", gap: 6 }}>
        <span>💡</span> Можешь поменять в Настройках в любой момент
      </div>
    </div>
    <div style={{ padding: "20px", marginTop: "auto" }}><div className="btn-blue">Продолжить</div></div>
  </Phone>
);

const BalEquipment = () => (
  <Phone noTab>
    <div className="appbar"><div className="appbar-back">←</div><div></div></div>
    <div className="ob-progress">
      <div className="ob-seg on"></div><div className="ob-seg on"></div>
      <div className="ob-seg on"></div><div className="ob-seg"></div>
    </div>
    <div className="ob-h1">Чем тренируешься?</div>
    <div className="ob-sub">Подберём план под доступное оборудование.</div>
    <div style={{ padding: "0 20px", display: "flex", flexWrap: "wrap", gap: 8 }}>
      <div className="eq-chip on"><span className="ico">🏋️</span> Гантели</div>
      <div className="eq-chip on"><span className="ico">⚡</span> Штанга</div>
      <div className="eq-chip"><span className="ico">🔝</span> Турник</div>
      <div className="eq-chip on"><span className="ico">🪑</span> Скамья</div>
      <div className="eq-chip"><span className="ico">🏭</span> Тренажёры</div>
      <div className="eq-chip on"><span className="ico">🟩</span> Коврик</div>
      <div className="eq-chip"><span className="ico">🟡</span> Резинки</div>
    </div>
    <div style={{ padding: "20px", marginTop: "auto", display: "flex", flexDirection: "column", gap: 10 }}>
      <div style={{ background: "#EFF6FF", border: "1px solid #DBEAFE", borderRadius: 12, padding: "12px 14px", fontSize: 12, color: "#1D4ED8", lineHeight: 1.5 }}>
        <strong>3 выбрано</strong> — доступно ~38 упражнений
      </div>
      <div className="btn-blue">Продолжить</div>
    </div>
  </Phone>
);

const BalJournal = () => (
  <Phone tab="journal">
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
          {x.train ? <div className={`cal-tag ${x.train}`} style={{ width: 16 }}></div> : <div className="cal-tag empty" style={{ width: 16 }}></div>}
        </div>
      ))}
    </div>
    <div className="scroll">
      <div style={{ display: "flex", alignItems: "center", gap: 18, padding: "10px 20px 16px" }}>
        <MacroRings size={88} />
        <div style={{ flex: 1, display: "flex", flexDirection: "column", gap: 8 }}>
          <div>
            <div style={{ fontSize: 10, fontWeight: 700, color: "#9CA3AF", textTransform: "uppercase", letterSpacing: 0.6 }}>Калории сегодня</div>
            <div style={{ display: "flex", alignItems: "baseline", gap: 5, marginTop: 2 }}>
              <span style={{ fontFamily: "JetBrains Mono", fontSize: 26, fontWeight: 800, letterSpacing: "-0.5px", color: "#111827" }}>1420</span>
              <span style={{ fontSize: 11, color: "#9CA3AF", fontWeight: 500 }}>/ 2100 ккал</span>
            </div>
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 10 }}><span style={{ width: 6, height: 6, borderRadius: 3, background: "#22C55E" }}></span><span style={{ fontFamily: "JetBrains Mono", fontWeight: 700, color: "#111827" }}>72g</span><span style={{ color: "#9CA3AF" }}>Б</span></div>
            <div style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 10 }}><span style={{ width: 6, height: 6, borderRadius: 3, background: "#06B6D4" }}></span><span style={{ fontFamily: "JetBrains Mono", fontWeight: 700, color: "#111827" }}>140g</span><span style={{ color: "#9CA3AF" }}>У</span></div>
            <div style={{ display: "flex", alignItems: "center", gap: 4, fontSize: 10 }}><span style={{ width: 6, height: 6, borderRadius: 3, background: "#EAB308" }}></span><span style={{ fontFamily: "JetBrains Mono", fontWeight: 700, color: "#111827" }}>48g</span><span style={{ color: "#9CA3AF" }}>Ж</span></div>
          </div>
        </div>
      </div>

      <div className="k-section-title">Еда</div>
      <div className="meal-row"><div><div className="meal-name">Овсянка с бананом</div><div className="meal-meta">Завтрак · 08:30</div></div><div><span className="meal-kcal">340</span><span className="meal-kcal-u"> ккал</span></div></div>
      <div className="meal-row"><div><div className="meal-name">Куриная грудка + рис</div><div className="meal-meta">Обед · 13:15</div></div><div><span className="meal-kcal">580</span><span className="meal-kcal-u"> ккал</span></div></div>
    </div>
  </Phone>
);

const BalTrainings = () => (
  <Phone tab="training">
    <div className="appbar">
      <div><div className="appbar-title">Тренировки</div><div className="appbar-sub">Программа · Неделя 3 из 8</div></div>
      <div className="appbar-action">⚙️</div>
    </div>
    <div style={{ padding: "0 20px 14px" }}>
      <div style={{ display: "flex", gap: 10, alignItems: "center", padding: "10px 14px", background: "#EFF6FF", borderRadius: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 11, color: "#1D4ED8", fontWeight: 700, textTransform: "uppercase", letterSpacing: 0.5 }}>Прогресс недели</div>
          <div style={{ fontSize: 15, fontWeight: 800, color: "#1D4ED8", marginTop: 2 }}>3 из 4 тренировок</div>
        </div>
        <div style={{ width: 44, height: 44, borderRadius: 22, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: "JetBrains Mono", fontWeight: 800, color: "#2563EB", fontSize: 13 }}>75%</div>
      </div>
    </div>
    <div className="scroll">
      <div style={{ padding: "0 18px 14px", display: "flex", flexDirection: "column", gap: 12 }}>
        <div className="train-card-bal">
          <div className="train-hero gr-coral">
            <span className="train-hero-tag">Сегодня · 18:00</span>
            <div className="train-hero-title">Грудь и трицепс</div>
          </div>
          <div className="train-body">
            <div className="train-body-item"><span className="num">45</span> мин</div>
            <div className="train-body-item"><span className="num">8</span> упр.</div>
            <div className="train-body-item"><span className="num">~320</span> ккал</div>
          </div>
        </div>
        <div className="train-card-bal">
          <div className="train-hero gr-violet">
            <span className="train-hero-tag">Пт · 09:00</span>
            <div className="train-hero-title">Ноги</div>
          </div>
          <div className="train-body">
            <div className="train-body-item"><span className="num">50</span> мин</div>
            <div className="train-body-item"><span className="num">7</span> упр.</div>
            <div className="train-body-item"><span className="num">~380</span> ккал</div>
          </div>
        </div>
        <div className="train-card-bal">
          <div className="train-hero gr-graph">
            <span className="train-hero-tag">Сб · 11:00</span>
            <div className="train-hero-title">Плечи и пресс</div>
          </div>
          <div className="train-body">
            <div className="train-body-item"><span className="num">40</span> мин</div>
            <div className="train-body-item"><span className="num">6</span> упр.</div>
            <div className="train-body-item"><span className="num">~260</span> ккал</div>
          </div>
        </div>
      </div>
    </div>
  </Phone>
);

const BalDetail = () => (
  <Phone tab="training">
    <div style={{ height: 220, position: "relative", margin: "0 0 16px" }}>
      <div style={{ position: "absolute", inset: 0, background: "linear-gradient(135deg,#F97316,#F43F5E)" }}></div>
      <div style={{ position: "absolute", inset: 0, padding: "60px 20px 20px", display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ width: 36, height: 36, borderRadius: 18, background: "rgba(255,255,255,0.2)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff" }}>←</div>
          <div style={{ width: 36, height: 36, borderRadius: 18, background: "rgba(255,255,255,0.2)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff" }}>⋯</div>
        </div>
        <div>
          <div style={{ fontSize: 10, fontWeight: 700, color: "rgba(255,255,255,0.85)", textTransform: "uppercase", letterSpacing: 0.6, marginBottom: 6 }}>День 3 · Грудь и трицепс</div>
          <div style={{ fontSize: 24, fontWeight: 800, color: "#fff", letterSpacing: "-0.4px", lineHeight: 1.1 }}>Push Day —<br/>Средний уровень</div>
        </div>
      </div>
    </div>
    <div className="scroll">
      <div style={{ margin: "0 20px 14px", padding: "14px 16px", background: "#F9FAFB", borderRadius: 14, display: "flex", justifyContent: "space-between" }}>
        <div style={{ textAlign: "center", flex: 1 }}><div style={{ fontFamily: "JetBrains Mono", fontSize: 18, fontWeight: 800 }}>45</div><div style={{ fontSize: 10, color: "#9CA3AF", fontWeight: 600 }}>МИН</div></div>
        <div style={{ width: 1, background: "#E5E7EB" }}></div>
        <div style={{ textAlign: "center", flex: 1 }}><div style={{ fontFamily: "JetBrains Mono", fontSize: 18, fontWeight: 800 }}>320</div><div style={{ fontSize: 10, color: "#9CA3AF", fontWeight: 600 }}>ККАЛ</div></div>
        <div style={{ width: 1, background: "#E5E7EB" }}></div>
        <div style={{ textAlign: "center", flex: 1 }}><div style={{ fontFamily: "JetBrains Mono", fontSize: 18, fontWeight: 800 }}>8</div><div style={{ fontSize: 10, color: "#9CA3AF", fontWeight: 600 }}>УПР.</div></div>
      </div>
      <div className="k-section-title">Упражнения <span className="more">8</span></div>
      <div style={{ padding: "0 18px 16px" }}>
        {[
          ["Жим штанги лёжа", "4 × 8–10"],
          ["Жим гантелей на наклонной", "3 × 10"],
          ["Разводка гантелей", "3 × 12"],
          ["Французский жим", "3 × 12"],
        ].map(([n, s], i) => (
          <div className="ex-row" key={i}>
            <div className="ex-num">{i + 1}</div>
            <div className="ex-info"><div className="ex-name">{n}</div><div className="ex-sets">{s}</div></div>
            <div className="ex-thumb" style={{ background: "linear-gradient(135deg,#FED7AA,#FBA74F)" }}>🏋️</div>
          </div>
        ))}
      </div>
      <div style={{ padding: "0 20px 20px" }}><div className="btn-blue">Начать тренировку</div></div>
    </div>
  </Phone>
);

const BalChat = () => (
  <Phone tab="chat">
    <div className="appbar">
      <div><div className="appbar-title">AI ассистент</div></div>
      <div className="appbar-action">📜</div>
    </div>
    <div className="chat-modes-bal">
      <div className="chat-mode-bal nutri on">
        <div className="ic">🥗</div>
        <div className="lb">Питание</div>
        <div className="desc">Калории, БЖУ, рецепты</div>
      </div>
      <div className="chat-mode-bal train">
        <div className="ic">🏋️</div>
        <div className="lb">Тренировки</div>
        <div className="desc">Программа, форма, советы</div>
      </div>
    </div>
    <div className="scroll" style={{ padding: "0 18px", display: "flex", flexDirection: "column", gap: 10 }}>
      <div className="bubble ai">Я записал твой обед — 580 ккал. Хочешь, посчитаю, сколько белка ещё нужно сегодня?</div>
      <div className="bubble user blue">Давай</div>
      <div className="bubble ai">До цели 145г белка осталось <strong>48г</strong>. Это ~200г куриной грудки или 2 порции творога.</div>
      <div className="bubble user blue">А чай с молоком сильно повлияет?</div>
      <div className="bubble ai">+30 ккал и 1.5г белка — не критично. Записал.</div>
    </div>
    <div className="chat-input">
      <span className="chat-input-txt">Что ты ел сегодня?</span>
      <div className="chat-input-mic">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><rect x="9" y="3" width="6" height="12" rx="3" fill="#fff"/><path d="M5 11a7 7 0 0 0 14 0 M12 18v3" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>
      </div>
    </div>
  </Phone>
);

const BalLive = () => (
  <Phone noTab>
    <div className="appbar">
      <div className="appbar-back">×</div>
      <div style={{ flex: 1, padding: "0 16px" }}>
        <div style={{ height: 5, background: "#F3F4F6", borderRadius: 999, overflow: "hidden" }}>
          <div style={{ width: "37%", height: "100%", background: "linear-gradient(90deg,#F97316,#F43F5E)" }}></div>
        </div>
        <div style={{ fontSize: 10, color: "#9CA3AF", fontWeight: 600, marginTop: 4, textAlign: "center" }}>Упражнение 3 из 8</div>
      </div>
      <div className="appbar-action" style={{ background: "transparent" }}>⏸</div>
    </div>
    <div className="scroll">
      <div className="live-img" style={{ background: "linear-gradient(135deg,#FED7AA,#FBA74F)" }}>🏋️</div>
      <div className="live-name">Жим гантелей на наклонной</div>
      <div className="live-meta">Подход 2 из 3</div>
      <div className="set-card">
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 14 }}>
          {[1,2,3].map(i => (
            <div key={i} style={{ flex: 1, textAlign: "center" }}>
              <div style={{ fontSize: 9, color: "#9CA3AF", fontWeight: 700, textTransform: "uppercase", marginBottom: 4 }}>Подход {i}</div>
              <div style={{
                margin: "0 auto", width: 40, height: 40, borderRadius: 20,
                background: i === 2 ? "#F97316" : i === 1 ? "#FED7AA" : "#F3F4F6",
                color: i <= 2 ? "#fff" : "#9CA3AF",
                display: "flex", alignItems: "center", justifyContent: "center",
                fontWeight: 800, fontSize: 13
              }}>{i === 1 ? "✓" : i === 2 ? "•" : "—"}</div>
            </div>
          ))}
        </div>
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
      <div className="btn-blue" style={{ flex: 2, background: "#F97316", boxShadow: "0 4px 18px rgba(249,115,22,0.4)" }}>Подход выполнен</div>
    </div>
  </Phone>
);

Object.assign(window, { BalOnboarding, BalEquipment, BalJournal, BalTrainings, BalDetail, BalChat, BalLive });
