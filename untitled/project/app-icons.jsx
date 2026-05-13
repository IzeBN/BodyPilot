// App icons — fitness-forward variants. Each is 1024×1024 SVG inside
// iOS-style squircle (~22.5% radius). Display size 220px.

const IconBase = ({ children, bg, sub, defs }) => (
  <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
    <svg width="220" height="220" viewBox="0 0 1024 1024" style={{ borderRadius: 230, boxShadow: "0 18px 40px rgba(17,24,39,0.18), 0 4px 12px rgba(17,24,39,0.08)" }}>
      {defs}
      <defs>
        <clipPath id={`clip-${sub}`}>
          <rect x="0" y="0" width="1024" height="1024" rx="230" ry="230"/>
        </clipPath>
      </defs>
      <g clipPath={`url(#clip-${sub})`}>
        <rect width="1024" height="1024" fill={bg}/>
        {children}
      </g>
    </svg>
    <div style={{ fontSize: 11, color: "#6B7280", fontWeight: 600, fontFamily: "Inter" }}>{sub}</div>
  </div>
);

// Reusable dumbbell silhouette
const Dumbbell = ({ x = 0, y = 0, scale = 1, color = "#fff" }) => (
  <g transform={`translate(${x},${y}) scale(${scale})`} fill={color}>
    {/* left outer plate */}
    <rect x="0"   y="80"  width="80"  height="200" rx="30"/>
    {/* left inner plate */}
    <rect x="80"  y="120" width="50"  height="120" rx="18"/>
    {/* handle */}
    <rect x="130" y="155" width="320" height="50"  rx="22"/>
    {/* right inner plate */}
    <rect x="450" y="120" width="50"  height="120" rx="18"/>
    {/* right outer plate */}
    <rect x="500" y="80"  width="80"  height="200" rx="30"/>
  </g>
);

// 1 · Dumbbell on brand blue
const Icon1 = () => (
  <IconBase
    sub="01 · Dumbbell"
    bg="url(#ic1)"
    defs={
      <defs>
        <linearGradient id="ic1" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#3B82F6"/>
          <stop offset="1" stopColor="#1D4ED8"/>
        </linearGradient>
      </defs>
    }
  >
    <Dumbbell x={222} y={342} scale={1} color="#fff"/>
    {/* subtle highlight */}
    <circle cx="780" cy="260" r="56" fill="#fff" opacity="0.14"/>
    <circle cx="240" cy="780" r="40" fill="#fff" opacity="0.10"/>
  </IconBase>
);

// 2 · Flex bicep — silhouette arm on coral gradient (energy/strength)
const Icon2 = () => (
  <IconBase
    sub="02 · Flex"
    bg="url(#ic2)"
    defs={
      <defs>
        <linearGradient id="ic2" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#F97316"/>
          <stop offset="1" stopColor="#F43F5E"/>
        </linearGradient>
      </defs>
    }
  >
    {/* Stylized flexed arm — forearm vertical, biceps bulge upper-left */}
    <path d="
      M 360 760
      L 360 540
      C 360 470, 400 410, 470 380
      C 540 350, 600 360, 660 410
      C 700 440, 730 480, 730 530
      C 730 575, 700 600, 660 605
      C 615 610, 580 580, 575 540
      C 565 470, 520 430, 460 440
      C 420 446, 400 470, 400 520
      L 400 760
      Z" fill="#fff"/>
    {/* wrist band */}
    <rect x="354" y="730" width="54" height="36" rx="10" fill="#fff" opacity="0.6"/>
    {/* fist */}
    <circle cx="380" cy="780" r="36" fill="#fff"/>
  </IconBase>
);

// 3 · Heart + ECG pulse (cardio / form / wellness)
const Icon3 = () => (
  <IconBase
    sub="03 · Pulse"
    bg="url(#ic3)"
    defs={
      <defs>
        <linearGradient id="ic3" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#0F172A"/>
          <stop offset="1" stopColor="#1E40AF"/>
        </linearGradient>
      </defs>
    }
  >
    {/* heart */}
    <path d="
      M 512 760
      C 380 660, 240 560, 240 430
      C 240 350, 305 290, 380 290
      C 440 290, 490 320, 512 370
      C 534 320, 584 290, 644 290
      C 719 290, 784 350, 784 430
      C 784 560, 644 660, 512 760 Z"
      fill="#fff"/>
    {/* ECG line through heart */}
    <path d="
      M 200 510
      L 350 510
      L 400 440
      L 470 580
      L 540 380
      L 600 540
      L 660 510
      L 824 510"
      fill="none" stroke="#EF4444" strokeWidth="22" strokeLinecap="round" strokeLinejoin="round"/>
  </IconBase>
);

// 4 · K + barbell — wordmark with horizontal barbell underline
const Icon4 = () => (
  <IconBase sub="04 · K bar" bg="#EFF6FF">
    <text x="512" y="640" textAnchor="middle" fontFamily="JetBrains Mono, monospace" fontWeight="800" fontSize="540" fill="#1D4ED8" letterSpacing="-26">K</text>
    {/* barbell underline */}
    <g transform="translate(232,720)">
      <rect x="0"   y="36" width="40"  height="80" rx="14" fill="#2563EB"/>
      <rect x="40"  y="50" width="26"  height="52" rx="10" fill="#2563EB"/>
      <rect x="66"  y="64" width="428" height="24" rx="10" fill="#2563EB"/>
      <rect x="494" y="50" width="26"  height="52" rx="10" fill="#2563EB"/>
      <rect x="520" y="36" width="40"  height="80" rx="14" fill="#2563EB"/>
    </g>
  </IconBase>
);

// 5 · Runner — stylized motion figure
const Icon5 = () => (
  <IconBase
    sub="05 · Run"
    bg="url(#ic5)"
    defs={
      <defs>
        <linearGradient id="ic5" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#22C55E"/>
          <stop offset="1" stopColor="#0EA5E9"/>
        </linearGradient>
      </defs>
    }
  >
    {/* speed lines behind */}
    <rect x="120" y="380" width="180" height="22" rx="11" fill="#fff" opacity="0.35"/>
    <rect x="80"  y="460" width="240" height="22" rx="11" fill="#fff" opacity="0.5"/>
    <rect x="140" y="540" width="160" height="22" rx="11" fill="#fff" opacity="0.3"/>

    {/* runner silhouette */}
    {/* head */}
    <circle cx="640" cy="260" r="64" fill="#fff"/>
    {/* torso */}
    <path d="M 560 340 C 590 330, 640 330, 700 380 C 740 410, 740 460, 720 520 L 660 580 C 640 560, 600 540, 560 520 L 530 460 C 520 410, 530 370, 560 340 Z" fill="#fff"/>
    {/* front arm */}
    <path d="M 720 380 L 800 480 L 770 540 L 700 470 Z" fill="#fff"/>
    {/* back arm */}
    <path d="M 560 380 L 480 460 L 510 510 L 590 440 Z" fill="#fff"/>
    {/* front leg (lifted) */}
    <path d="M 660 580 L 720 680 L 800 680 L 800 730 L 680 730 L 620 640 Z" fill="#fff"/>
    {/* back leg (extended) */}
    <path d="M 560 540 L 460 700 L 380 720 L 380 770 L 500 770 L 620 600 Z" fill="#fff"/>
  </IconBase>
);

// 6 · Duo — apple + dumbbell (питание + тренировки)
const Icon6 = () => (
  <IconBase
    sub="06 · Eat + Train"
    bg="url(#ic6)"
    defs={
      <defs>
        <linearGradient id="ic6" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#22C55E"/>
          <stop offset="0.5" stopColor="#16A34A"/>
          <stop offset="0.5" stopColor="#2563EB"/>
          <stop offset="1" stopColor="#1D4ED8"/>
        </linearGradient>
      </defs>
    }
  >
    {/* diagonal divider */}
    <line x1="80" y1="944" x2="944" y2="80" stroke="#fff" strokeWidth="14" opacity="0.35"/>

    {/* Apple — upper-left half */}
    <g transform="translate(170,200)">
      {/* leaf */}
      <path d="M 140 0 C 170 -20, 210 -10, 220 30 C 200 50, 160 50, 140 30 Z" fill="#fff"/>
      {/* stem */}
      <rect x="138" y="20" width="8" height="30" rx="3" fill="#fff"/>
      {/* apple body */}
      <path d="
        M 140 50
        C 60 50, 20 110, 20 190
        C 20 280, 80 360, 140 360
        C 160 360, 175 348, 142 348
        C 110 348, 125 360, 145 360
        C 205 360, 265 280, 265 190
        C 265 110, 225 50, 145 50
        Z" fill="#fff"/>
    </g>

    {/* Dumbbell — lower-right half */}
    <Dumbbell x={460} y={620} scale={0.9} color="#fff"/>
  </IconBase>
);

const AppIconsRow = () => (
  <div style={{ display: "flex", gap: 36, padding: "40px 40px", flexWrap: "wrap", background: "transparent" }}>
    <Icon1/><Icon2/><Icon3/><Icon4/><Icon5/><Icon6/>
  </div>
);

Object.assign(window, { AppIconsRow });
