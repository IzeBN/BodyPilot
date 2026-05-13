// Main app — composes DesignCanvas with all 3 variants

const W = 320, H = 690;

const App = () => (
  <DesignCanvas>
    <DCSection id="icons" title="Иконки приложения" subtitle="6 направлений: wordmark, кольца БЖУ, K + ring, AI-sparkle, бары активности, дуо-split питание/тренировки. iOS-squircle 22.5% радиус.">
      <DCArtboard id="icons-row" label="01 · 6 вариантов" width={1620} height={300}><AppIconsRow/></DCArtboard>
    </DCSection>

    <DCSection id="conservative" title="Вариант A · Консервативный" subtitle="Минимальные правки KayFit — просто добавлена вкладка Тренировки. Карточки-строки как у еды, простой переключатель в чате, лёгкая точка под датой для дней с тренировкой.">
      <DCArtboard id="c1" label="01 · Онбординг — выбор" width={W} height={H}><ConsOnboarding/></DCArtboard>
      <DCArtboard id="c2" label="02 · Оборудование" width={W} height={H}><ConsEquipment/></DCArtboard>
      <DCArtboard id="c3" label="03 · Журнал + точка" width={W} height={H}><ConsJournal/></DCArtboard>
      <DCArtboard id="c4" label="04 · Тренировки (список)" width={W} height={H}><ConsTrainings/></DCArtboard>
      <DCArtboard id="c5" label="05 · Карточка тренировки" width={W} height={H}><ConsDetail/></DCArtboard>
      <DCArtboard id="c6" label="06 · Чат (segmented)" width={W} height={H}><ConsChat/></DCArtboard>
      <DCArtboard id="c7" label="07 · Live workout" width={W} height={H}><ConsLive/></DCArtboard>
    </DCSection>

    <DCSection id="balanced" title="Вариант B · Сбалансированный" subtitle="Тренировки получают собственный визуальный язык — карточки с цветным hero, двойной индикатор на календаре (рамка-еда + цветная полоса-тренировка), prominent pills для смены режима AI.">
      <DCArtboard id="b1" label="01 · Онбординг — чек-боксы" width={W} height={H}><BalOnboarding/></DCArtboard>
      <DCArtboard id="b2" label="02 · Оборудование + count" width={W} height={H}><BalEquipment/></DCArtboard>
      <DCArtboard id="b3" label="03 · Журнал + hero-карточка" width={W} height={H}><BalJournal/></DCArtboard>
      <DCArtboard id="b4" label="04 · Тренировки + прогресс" width={W} height={H}><BalTrainings/></DCArtboard>
      <DCArtboard id="b5" label="05 · Детали (full-bleed)" width={W} height={H}><BalDetail/></DCArtboard>
      <DCArtboard id="b6" label="06 · Чат (контентные pills)" width={W} height={H}><BalChat/></DCArtboard>
      <DCArtboard id="b7" label="07 · Live + sets-row" width={W} height={H}><BalLive/></DCArtboard>
    </DCSection>

    <DCSection id="bold" title="Вариант C · Смелый" subtitle="Календарь превращается в activity strip с двумя барами на день (еда / тренировка). Полноэкранный hero-карточка. Чат меняет цвет фона под режим. Wide gradient cards вместо одинаковых строк.">
      <DCArtboard id="d1" label="01 · Онбординг — крупные cards" width={W} height={H}><BoldOnboarding/></DCArtboard>
      <DCArtboard id="d2" label="02 · Оборудование (grid)" width={W} height={H}><BoldEquipment/></DCArtboard>
      <DCArtboard id="d3" label="03 · Журнал + activity bars" width={W} height={H}><BoldJournal/></DCArtboard>
      <DCArtboard id="d4" label="04 · Тренировки (color-coded)" width={W} height={H}><BoldTrainings/></DCArtboard>
      <DCArtboard id="d5" label="05 · Детали (full hero)" width={W} height={H}><BoldDetail/></DCArtboard>
      <DCArtboard id="d6" label="06 · Чат (тёмный switcher)" width={W} height={H}><BoldChat/></DCArtboard>
      <DCArtboard id="d7" label="07 · Live (тёмный pad)" width={W} height={H}><BoldLive/></DCArtboard>
    </DCSection>
  </DesignCanvas>
);

ReactDOM.createRoot(document.getElementById("canvas-root")).render(<App/>);
