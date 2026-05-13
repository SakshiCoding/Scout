// Shared sample data for all three Scout design directions.

const SCOUT_RESTAURANTS = [
  { id: 1,  name: 'Kismet',                cuisine: 'Mediterranean', price: '$$',  rating: 4.7, dist: '0.4',  status: 'open',   closes: '11p',  vibe: ['Date night', 'Patio'], hue: 28 },
  { id: 2,  name: "Mister Jiu's",          cuisine: 'Cantonese',     price: '$$$', rating: 4.8, dist: '1.2',  status: 'open',   closes: '10p',  vibe: ['Special occasion'],    hue: 16 },
  { id: 3,  name: 'Tartine Manufactory',   cuisine: 'Bakery',        price: '$',   rating: 4.6, dist: '0.8',  status: 'closes', closes: '8p',   vibe: ['Casual', 'Brunch'],    hue: 42 },
  { id: 4,  name: 'Sons & Daughters',      cuisine: 'New American',  price: '$$$', rating: 4.9, dist: '2.1',  status: 'opens',  closes: '5p',   vibe: ['Tasting menu'],        hue: 8  },
  { id: 5,  name: 'Liholiho Yacht Club',   cuisine: 'Hawaiian',      price: '$$',  rating: 4.7, dist: '1.5',  status: 'open',   closes: '10p',  vibe: ['Lively'],              hue: 22 },
  { id: 6,  name: 'State Bird Provisions', cuisine: 'New American',  price: '$$$', rating: 4.8, dist: '0.9',  status: 'open',   closes: '11p',  vibe: ['Buzzy'],               hue: 36 },
  { id: 7,  name: 'Marlowe',               cuisine: 'American',      price: '$$',  rating: 4.5, dist: '0.3',  status: 'closes', closes: '10p',  vibe: ['Quick bite'],          hue: 32 },
  { id: 8,  name: 'Nopa',                  cuisine: 'Californian',   price: '$$',  rating: 4.6, dist: '1.0',  status: 'open',   closes: '1a',   vibe: ['Late night'],          hue: 18 },
];

// Map pins (relative to a 360×500 viewport) — used in MapView mocks.
const SCOUT_PINS = [
  { id: 1, x: 0.32, y: 0.42, label: 'Kismet' },
  { id: 2, x: 0.62, y: 0.28, label: "Jiu's" },
  { id: 3, x: 0.48, y: 0.55, label: 'Tartine' },
  { id: 4, x: 0.78, y: 0.62, label: 'S&D' },
  { id: 5, x: 0.22, y: 0.68, label: 'Liholiho' },
  { id: 6, x: 0.55, y: 0.72, label: 'State Bird' },
  { id: 8, x: 0.40, y: 0.30, label: 'Nopa' },
];

// A reusable "subtle striped" photo placeholder — keeps things print-friendly
// without needing real food photos. Each card gets a unique hue from the data.
function ScoutPhoto({ hue = 28, label = 'food photo', dark = false, radius = 16, style = {} }) {
  const sat = dark ? 38 : 62;
  const l1 = dark ? 22 : 78;
  const l2 = dark ? 28 : 86;
  return (
    <div style={{
      borderRadius: radius, overflow: 'hidden',
      background: `repeating-linear-gradient(135deg, hsl(${hue} ${sat}% ${l1}%) 0 14px, hsl(${hue} ${sat}% ${l2}%) 14px 28px)`,
      position: 'relative',
      ...style,
    }}>
      <div style={{
        position: 'absolute', inset: 0, display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
        fontSize: 10, letterSpacing: 0.4, textTransform: 'lowercase',
        color: dark ? 'rgba(255,240,220,0.45)' : 'rgba(60,30,10,0.45)',
      }}>{label}</div>
    </div>
  );
}

// Compass-rose SVG — used as a logo motif (A · Atlas direction).
function ScoutCompass({ size = 28, color = '#CC5500', strokeWidth = 1.4 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
      <circle cx="16" cy="16" r="14" stroke={color} strokeWidth={strokeWidth} />
      <circle cx="16" cy="16" r="1.6" fill={color} />
      {/* N point — fork as the needle */}
      <path d="M16 3 L16 11 M14 5 L14 8 M18 5 L18 8 M14 5 L14 4 M18 5 L18 4 M16 5 L16 4"
            stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
      {/* S point */}
      <path d="M16 29 L16 21" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
      {/* E + W points */}
      <path d="M3 16 L11 16 M29 16 L21 16" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" />
      {/* Inner diamond */}
      <path d="M16 9 L20 16 L16 23 L12 16 Z" stroke={color} strokeWidth={strokeWidth * 0.7} fill="none" />
    </svg>
  );
}

// "S" map pin — used as a logo motif (B · Heat direction).
function ScoutPinS({ size = 28, color = '#FF6B00' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
      <path d="M16 2c-6 0-11 4.6-11 10.6 0 8 11 17.4 11 17.4s11-9.4 11-17.4C27 6.6 22 2 16 2z"
            fill={color} />
      <path d="M19.5 9.5 c -1.5 -1 -4 -1.2 -5.6 0 c -1.5 1.2 -1.2 3 0.4 3.6 l 2.6 1
               c 1.6 0.6 2 2.4 0.4 3.6 c -1.6 1.2 -4.1 1 -5.6 0"
            stroke="#fff" strokeWidth="1.8" strokeLinecap="round" fill="none" />
    </svg>
  );
}

// Binoculars-ish silhouette — used as a logo motif (C · Ember direction).
function ScoutBinoculars({ size = 28, color = '#FF7A1A' }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" fill="none">
      <circle cx="9" cy="20" r="6" stroke={color} strokeWidth="1.6" />
      <circle cx="23" cy="20" r="6" stroke={color} strokeWidth="1.6" />
      <circle cx="9" cy="20" r="2" fill={color} />
      <circle cx="23" cy="20" r="2" fill={color} />
      <path d="M9 14 L13 8 L19 8 L23 14" stroke={color} strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
      <path d="M14 11 L18 11" stroke={color} strokeWidth="1.6" strokeLinecap="round" />
    </svg>
  );
}

Object.assign(window, {
  SCOUT_RESTAURANTS, SCOUT_PINS,
  ScoutPhoto, ScoutCompass, ScoutPinS, ScoutBinoculars,
});
