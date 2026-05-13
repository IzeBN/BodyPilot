// BOLD variant — novel paradigm: unified day plan, activity-bar calendar,
// chat morphs by mode, wide hero workout cards.

const BoldOnboarding = () => (
  <Phone noTab>
    <div className="appbar"><div className="appbar-back">←</div><div></div></div>
    <div className="ob-h1" style={{ fontSize: 28, paddingTop: 20 }}>Какой план тебе нужен?</div>
    <div className="ob-sub">Выбери одно — мы соберём приложение специально для тебя.</div>
    <div style={{ display: "flex", flexDirection: "column", gap: 12, padding: "0 20px" }}>
      <div className="goal-bold nutri">
        <div className="goal-bold-name">Только питание</div>
        <div className="goal-bold-desc">Дневник еды, БЖУ, AI-нутрициолог. Без тренировок.</div>
        <span className="goal-bold-arr">→</span>
      </div>
      <div className="goal-bold train">
        <div className="goal-bold-name">Только тренировки</div>
        <div className="goal-bold-desc">Программы, упражнения, AI-тренер. Без еды.</div>
        <span className="goal-bold-arr">→</span>
      </div>
      <div className="goal-bold both">
        <div className="goal-bold-name">Питание + Тренировки</div>
        <div className="goal-bold-desc">Полный стек. Рекомендуем — синергия даёт результат быстрее.</div>
        <span className="goal-bold-arr">→</span>
        <div style={{ position: "absolute", top: 10, right: 16, fontSize: 9, fontWeight: 800, color: "#fff", background: "rgba(255,255,255,0.2)", padding: "3px 8px", borderRadius: 999 }}>POPULAR</div>
      </div>
    </div>
  </Phone>
);

const BoldEquipment = () => (
  <Phone noTab>
    <div className="appbar"><div className="appbar-back">←</div><div style={{ fontSize: 11, color: "#9CA3AF", fontWeight: 600 }}>3 / 5</div></div>
    <div className="ob-h1" style={{ fontSize: 26 }}>Что в твоём арсенале?</div>
    <div className="ob-sub">Включай только то, чем реально пользуешься.</div>
    <div style={{ padding: "0 20px", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
      {[
        { ic: "🏋️", n: "Гантели", on: true },
        { ic: "⚡", n: "Штанга", on: true },
        { ic: "🔝", n: "Турник", on: false },
        { ic: "🪑", n: "Скамья", on: true },
        { ic: "🏭", n: "Тренажёры", on: false },
        { ic: "🟩", n: "Коврик", on: false },
      ].map((x, i) => (
        <div key={i} style={{
          padding: "16px 14px", borderRadius: 14,
          background: x.on ? "linear-gradient(135deg,#3B82F6,#2563EB)" : "#fff",
          color: x.on ? "#fff" : "#111827",
          border: x.on ? "none" : "1.5px solid #E5E7EB",
          display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 6,
          boxShadow: x.on ? "0 4px 14px rgba(37,99,235,0.25)" : "none",
          position: "relative"
        }}>
          <div style={{ fontSize: 22 }}>{x.ic}</div>
          <div style={{ fontSize: 13, fontWeight: 700 }}>{x.n}</div>
          {x.on && <div style={{ position: "absolute", top: 10, right: 10, width: 18, height: 18, borderRadius: 9, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <svg width="10" height="10" viewBox="0 0 24 24"><path d="M5 12l5 5 9-11" stroke="#2563EB" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
          </div>}
        </div>
      ))}
    </div>
    <div style={{ padding: "20px", marginTop: "auto" }}><div className="btn-blue">3 выбрано — продолжить</div></div>
  </Phone>
);

const BoldJournal = () => (
  <Phone tab="journal">
    <div className="appbar">
      <div><div className="appbar-title" style={{ fontSize: 26, fontWeight: 800 }}>Сегодня</div><div className="appbar-sub">Вс · 12 ноября</div></div>
      <div style={{ display: "flex", gap: 8 }}>
        <div className="appbar-action">🇷🇺</div>
      </div>
    </div>
    <div style={{ padding: "4px 18px 14px", background: "#fff" }}>
      <div style={{ display: "flex", justifyContent: "space-between", gap: 4 }}>
        {[
          { d: "Пн", n: 6, food: 0.9, train: 1 },
          { d: "Вт", n: 7, food: 0.8, train: 0 },
          { d: "Ср", n: 8, food: 1, train: 0.7 },
          { d: "Чт", n: 9, food: 0.3, train: 0 },
          { d: "Пт", n: 10, food: 0.9, train: 1 },
          { d: "Сб", n: 11, food: 0.85, train: 0 },
          { d: "Вс", n: 12, food: 0.68, train: 0.5, active: true },
        ].map((x, i) => (
          <div key={i} style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
            <div style={{ fontSize: 9, fontWeight: 600, color: x.active ? "#2563EB" : "#9CA3AF", textTransform: "uppercase" }}>{x.d}</div>
            <div style={{ fontSize: 13, fontWeight: 700, color: x.active ? "#2563EB" : "#111827" }}>{x.n}</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 2, width: 22 }}>
              <div style={{ height: 4, borderRadius: 999, background: "#F3F4F6", overflow: "hidden" }}>
                <div style={{ width: `${x.food * 100}%`, height: "100%", background: "#22C55E" }}></div>
              </div>
              <div style={{ height: 4, borderRadius: 999, background: "#F3F4F6", overflow: "hidden" }}>
                <div style={{ width: `${x.train * 100}%`, height: "100%", background: "#F97316" }}></div>
              </div>
            </div>
          </div>
        ))}
      </div>
      <div style={{ display: "flex", gap: 12, marginTop: 8, fontSize: 9, color: "#9CA3AF" }}>
        <span><span style={{ display: "inline-block", width: 8, height: 3, background: "#22C55E", borderRadius: 999, verticalAlign: "middle", marginRight: 4 }}></span>Еда</span>
        <span><span style={{ display: "inline-block", width: 8, height: 3, background: "#F97316", borderRadius: 999, verticalAlign: "middle", marginRight: 4 }}></span>Тренировки</span>
      </div>
    </div>
    <div className="scroll">
      <div style={{ padding: "0 18px 14px" }}>
        <div className="train-card-bold">
          <div className="train-bold-decor"></div>
          <div className="train-bold-row">
            <div>
              <div style={{ fontSize: 10, fontWeight: 800, opacity: 0.85, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 8 }}>↗ Следующее · 18:00</div>
              <div className="train-bold-title">Грудь и трицепс</div>
              <div className="train-bold-sub">45 мин · 8 упражнений · ~320 ккал</div>
            </div>
            <div className="train-bold-cta">Начать ▸</div>
          </div>
        </div>
      </div>

      <div style={{ padding: "0 18px 14px" }}>
        <div style={{ background: "#fff", borderRadius: 20, border: "0.5px solid #E5E7EB", padding: "16px", boxShadow: "0 2px 12px rgba(17,24,39,0.04)" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
            <div>
              <div style={{ fontSize: 11, color: "#9CA3AF", fontWeight: 700, textTransform: "uppercase", letterSpacing: 0.5 }}>Калории</div>
              <div style={{ display: "flex", alignItems: "baseline", gap: 4 }}>
                <div style={{ fontFamily: "JetBrains Mono", fontSize: 28, fontWeight: 800 }}>1420</div>
                <div style={{ fontSize: 12, color: "#9CA3AF" }}>/ 2100</div>
              </div>
            </div>
            <MacroRings size={70} />
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <div className="mp"><div className="mp-val" style={{ color: "#22C55E" }}>72g</div><div className="mp-lbl">Белок</div></div>
            <div className="mp"><div className="mp-val" style={{ color: "#06B6D4" }}>140g</div><div className="mp-lbl">Углев</div></div>
            <div className="mp"><div className="mp-val" style={{ color: "#CA8A04" }}>48g</div><div className="mp-lbl">Жир</div></div>
          </div>
        </div>
      </div>

      <div className="k-section-title">Еда</div>
      <div className="meal-row"><div><div className="meal-name">Куриная грудка + рис</div><div className="meal-meta">Обед · 13:15</div></div><div><span className="meal-kcal">580</span><span className="meal-kcal-u"> ккал</span></div></div>
      <div className="meal-row"><div><div className="meal-name">Овсянка с бананом</div><div className="meal-meta">Завтрак · 08:30</div></div><div><span className="meal-kcal">340</span><span className="meal-kcal-u"> ккал</span></div></div>
    </div>
  </Phone>
);

const BoldTrainings = () => (
  <Phone tab="training">
    <div className="appbar">
      <div><div className="appbar-title" style={{ fontSize: 26, fontWeight: 800 }}>Тренировки</div><div className="appbar-sub">Push · Pull · Legs</div></div>
      <div className="appbar-action">⚙️</div>
    </div>
    <div className="scroll">
      <div style={{ padding: "0 18px 16px" }}>
        <div className="train-card-bold" style={{ marginBottom: 14 }}>
          <div className="train-bold-decor"></div>
          <div className="train-bold-row">
            <div>
              <div style={{ fontSize: 10, fontWeight: 800, opacity: 0.85, letterSpacing: 0.5, textTransform: "uppercase", marginBottom: 8 }}>Сегодня</div>
              <div className="train-bold-title">Грудь и трицепс</div>
              <div className="train-bold-sub">45 мин · 8 упражнений</div>
            </div>
            <div className="train-bold-cta">Начать ▸</div>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
          {[
            { day: "Пт · 09:00", name: "Ноги", meta: "50 мин · 7 упр.", gr: "linear-gradient(135deg,#8B5CF6,#6366F1)" },
            { day: "Сб · 11:00", name: "Плечи и пресс", meta: "40 мин · 6 упр.", gr: "linear-gradient(135deg,#1F2937,#374151)" },
            { day: "Пн · 19:00", name: "Спина и бицепс", meta: "45 мин · 8 упр.", gr: "linear-gradient(135deg,#06B6D4,#0284C7)" },
          ].map((t, i) => (
            <div key={i} style={{ borderRadius: 18, background: t.gr, padding: 14, color: "#fff", display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{ width: 44, height: 44, borderRadius: 22, background: "rgba(255,255,255,0.18)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>›</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 9, opacity: 0.8, fontWeight: 700, letterSpacing: 0.6, textTransform: "uppercase" }}>{t.day}</div>
                <div style={{ fontSize: 16, fontWeight: 800, letterSpacing: "-0.2px", marginTop: 2 }}>{t.name}</div>
                <div style={{ fontSize: 11, opacity: 0.85, marginTop: 2 }}>{t.meta}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="k-section-title">Быстрый старт</div>
      <div style={{ padding: "0 18px 16px", display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10 }}>
        {[
          { ic: "🧘", n: "Растяжка", t: "15 мин" },
          { ic: "🏃", n: "HIIT", t: "20 мин" },
        ].map((x, i) => (
          <div key={i} style={{ background: "#fff", border: "0.5px solid #E5E7EB", borderRadius: 16, padding: 14 }}>
            <div style={{ fontSize: 24, marginBottom: 6 }}>{x.ic}</div>
            <div style={{ fontSize: 13, fontWeight: 700 }}>{x.n}</div>
            <div style={{ fontSize: 11, color: "#9CA3AF", marginTop: 2 }}>{x.t}</div>
          </div>
        ))}
      </div>
    </div>
  </Phone>
);

const BoldDetail = () => (
  <Phone tab="training">
    <div style={{ position: "relative", height: 280, marginBottom: 0 }}>
      <div style={{ position: "absolute", inset: 0, background: "linear-gradient(180deg,#F97316 0%,#F43F5E 60%,#fff 100%)" }}></div>
      <div style={{ position: "absolute", inset: 0, padding: "60px 20px 20px", display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", justifyContent: "space-between" }}>
          <div style={{ width: 36, height: 36, borderRadius: 18, background: "rgba(255,255,255,0.25)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontWeight: 600 }}>←</div>
          <div style={{ width: 36, height: 36, borderRadius: 18, background: "rgba(255,255,255,0.25)", backdropFilter: "blur(8px)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff" }}>♡</div>
        </div>
        <div style={{ marginTop: "auto" }}>
          <div style={{ fontSize: 10, color: "rgba(255,255,255,0.95)", fontWeight: 800, textTransform: "uppercase", letterSpacing: 0.8, marginBottom: 8 }}>День 3 · PUSH</div>
          <div style={{ fontSize: 30, fontWeight: 900, color: "#fff", letterSpacing: "-0.8px", lineHeight: 1 }}>Грудь и<br/>трицепс</div>
          <div style={{ display: "flex", gap: 14, marginTop: 14, color: "#fff", fontSize: 12, fontWeight: 600 }}>
            <span>⏱ 45 мин</span><span>🔥 320 ккал</span><span>💪 8 упр.</span>
          </div>
        </div>
      </div>
    </div>
    <div className="scroll" style={{ background: "#fff" }}>
      <div style={{ padding: "8px 18px 16px" }}>
        {[
          ["Жим штанги лёжа", "4 × 8–10"],
          ["Жим гантелей на наклонной", "3 × 10"],
          ["Разводка гантелей", "3 × 12"],
          ["Французский жим", "3 × 12"],
          ["Разгибания на блоке", "3 × 15"],
        ].map(([n, s], i) => (
          <div key={i} style={{ display: "flex", alignItems: "center", gap: 12, padding: "12px 0", borderBottom: i < 4 ? "0.5px solid #F9FAFB" : "none" }}>
            <div style={{ fontFamily: "JetBrains Mono", fontSize: 22, fontWeight: 800, color: "#F97316", minWidth: 28 }}>{String(i + 1).padStart(2, "0")}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 14, fontWeight: 700 }}>{n}</div>
              <div style={{ fontSize: 11, color: "#9CA3AF", marginTop: 1 }}>{s}</div>
            </div>
            <div style={{ color: "#9CA3AF" }}>›</div>
          </div>
        ))}
      </div>
      <div style={{ padding: "0 20px 20px" }}>
        <div className="btn-blue" style={{ background: "linear-gradient(135deg,#F97316,#F43F5E)", boxShadow: "0 6px 20px rgba(244,63,94,0.4)" }}>Начать тренировку</div>
      </div>
    </div>
  </Phone>
);

const BoldChat = () => (
  <Phone tab="chat">
    <div className="appbar">
      <div><div className="appbar-title" style={{ fontSize: 22 }}>AI</div><div className="appbar-sub">Тренировочный режим</div></div>
      <div className="appbar-action">📜</div>
    </div>
    <div className="chat-bold-hdr">
      <div className="chat-bold-mode nutri">🥗 Питание</div>
      <div className="chat-bold-mode train on">🏋️ Тренер</div>
    </div>
    <div className="scroll" style={{ padding: "0 18px", display: "flex", flexDirection: "column", gap: 10, background: "linear-gradient(180deg,#FFF7ED 0%,#fff 200px)" }}>
      <div className="bubble ai"><div className="src" style={{ color: "#F97316" }}>Тренер · AI</div>Что чувствуешь после жима? Спина прижата к скамье?</div>
      <div className="bubble user coral">Локти чуть болят</div>
      <div className="bubble ai">Возможно, разводишь их слишком широко. Попробуй угол 45° к корпусу, а не 90°. Снизит нагрузку на плечи и локти.</div>
      <div className="bubble user coral">Ок, попробую</div>
      <div className="bubble ai"><div className="src" style={{ color: "#F97316" }}>Тренер · AI</div>Если будет дискомфорт — сделай 2 подхода вместо 3, не геройствуй 💪</div>
    </div>
    <div className="chat-input">
      <span className="chat-input-txt">Спроси про технику…</span>
      <div className="chat-input-mic coral">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><rect x="9" y="3" width="6" height="12" rx="3" fill="#fff"/><path d="M5 11a7 7 0 0 0 14 0 M12 18v3" stroke="#fff" strokeWidth="2" strokeLinecap="round"/></svg>
      </div>
    </div>
  </Phone>
);

const BoldLive = () => (
  <Phone noTab>
    <div className="appbar">
      <div className="appbar-back">×</div>
      <div style={{ fontFamily: "JetBrains Mono", fontSize: 18, fontWeight: 800 }}>03:42</div>
      <div className="appbar-action" style={{ background: "transparent" }}>⏸</div>
    </div>
    <div style={{ padding: "0 20px 12px", display: "flex", gap: 4 }}>
      {[1,2,3,4,5,6,7,8].map(i => (
        <div key={i} style={{
          flex: 1, height: 4, borderRadius: 999,
          background: i < 3 ? "#F97316" : i === 3 ? "#FED7AA" : "#F3F4F6"
        }}></div>
      ))}
    </div>
    <div className="scroll">
      <div style={{ margin: "0 20px", height: 200, borderRadius: 24, background: "linear-gradient(135deg,#FED7AA,#FBA74F)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 56, position: "relative" }}>
        🏋️
        <div style={{ position: "absolute", top: 14, left: 14, padding: "5px 10px", background: "rgba(255,255,255,0.3)", backdropFilter: "blur(8px)", borderRadius: 999, fontSize: 10, fontWeight: 800, color: "#fff", letterSpacing: 0.5, textTransform: "uppercase" }}>3 / 8</div>
      </div>
      <div style={{ padding: "16px 20px 4px", textAlign: "center" }}>
        <div style={{ fontSize: 24, fontWeight: 800, letterSpacing: "-0.5px" }}>Жим гантелей</div>
        <div style={{ fontSize: 13, color: "#9CA3AF", marginTop: 4 }}>на наклонной скамье</div>
      </div>
      <div style={{ padding: "14px 20px", display: "flex", gap: 10 }}>
        {[1,2,3].map(i => (
          <div key={i} style={{
            flex: 1, padding: "10px 8px", borderRadius: 14, textAlign: "center",
            background: i === 1 ? "#22C55E" : i === 2 ? "#F97316" : "#F3F4F6",
            color: i <= 2 ? "#fff" : "#9CA3AF"
          }}>
            <div style={{ fontSize: 9, fontWeight: 800, opacity: 0.85, letterSpacing: 0.4 }}>ПОДХОД {i}</div>
            <div style={{ fontFamily: "JetBrains Mono", fontSize: 18, fontWeight: 800, marginTop: 2 }}>{i === 1 ? "10 × 22" : i === 2 ? "—" : "—"}</div>
          </div>
        ))}
      </div>
      <div style={{ margin: "0 20px", padding: 18, borderRadius: 20, background: "#111827", color: "#fff" }}>
        <div style={{ display: "flex", justifyContent: "space-around", textAlign: "center" }}>
          <div>
            <div style={{ fontSize: 10, opacity: 0.6, fontWeight: 700, letterSpacing: 0.5, marginBottom: 6 }}>ПОВТОРЫ</div>
            <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
              <div style={{ width: 32, height: 32, borderRadius: 16, background: "#374151", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>−</div>
              <div style={{ fontFamily: "JetBrains Mono", fontSize: 28, fontWeight: 800 }}>10</div>
              <div style={{ width: 32, height: 32, borderRadius: 16, background: "#F97316", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>+</div>
            </div>
          </div>
        </div>
        <div style={{ display: "flex", justifyContent: "space-around", textAlign: "center", marginTop: 14, paddingTop: 14, borderTop: "1px solid #374151" }}>
          <div>
            <div style={{ fontSize: 10, opacity: 0.6, fontWeight: 700, letterSpacing: 0.5, marginBottom: 6 }}>ВЕС, КГ</div>
            <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
              <div style={{ width: 32, height: 32, borderRadius: 16, background: "#374151", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>−</div>
              <div style={{ fontFamily: "JetBrains Mono", fontSize: 28, fontWeight: 800 }}>22</div>
              <div style={{ width: 32, height: 32, borderRadius: 16, background: "#F97316", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18 }}>+</div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div style={{ padding: "12px 20px 24px" }}>
      <div className="btn-blue" style={{ background: "linear-gradient(135deg,#F97316,#F43F5E)", boxShadow: "0 6px 22px rgba(244,63,94,0.45)" }}>
        Подход выполнен ▸
      </div>
    </div>
  </Phone>
);

Object.assign(window, { BoldOnboarding, BoldEquipment, BoldJournal, BoldTrainings, BoldDetail, BoldChat, BoldLive });
