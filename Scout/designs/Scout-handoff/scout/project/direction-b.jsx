// ─────────────────────────────────────────────────────────────
// Direction B · Heat — Bold, modern, vibrant orange, chunky UI
// ─────────────────────────────────────────────────────────────
//   • Palette:  bone white, vivid orange, deep ink
//   • Type:     Space Grotesk (display) + Geist Mono (numerals/labels)
//   • Voice:    Fast, confident, signage-like

const B = {
  bone:    '#FBFAF7',
  bone2:   '#F0EDE6',
  ink:     '#0E0E0C',
  ink2:    'rgba(14,14,12,0.62)',
  ink3:    'rgba(14,14,12,0.40)',
  rule:    'rgba(14,14,12,0.10)',
  orange:  '#FF6B00',
  burnt:   '#CC5500',
  sun:     '#FFB16B',
  display: '"Space Grotesk", "Geist", -apple-system, system-ui, sans-serif',
  mono:    '"Geist Mono", "JetBrains Mono", ui-monospace, "SF Mono", monospace',
};

function BStatusBadge({ status, big = false }) {
  const map = {
    open:   { c: '#0BAA51', t: 'Open' },
    closes: { c: B.orange,  t: 'Closes soon' },
    opens:  { c: B.ink3,    t: 'Opens later' },
  };
  const s = map[status] || map.open;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: big ? '5px 10px' : '3px 8px', borderRadius: 99,
      background: `${s.c}1A`, color: s.c,
      fontFamily: B.mono, fontSize: big ? 11 : 10, fontWeight: 600,
      letterSpacing: 0.4, textTransform: 'uppercase',
    }}>
      <span style={{ width: 6, height: 6, borderRadius: 99, background: s.c }} />
      {s.t}
    </span>
  );
}

function BChip({ children, active = false, accent = false }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', height: 34,
      padding: '0 14px', borderRadius: 12,
      fontFamily: B.display, fontSize: 13, fontWeight: 600,
      background: active ? B.ink : (accent ? B.orange : 'transparent'),
      color: active ? B.bone : (accent ? '#fff' : B.ink),
      border: active || accent ? 'none' : `1.5px solid ${B.rule}`,
      whiteSpace: 'nowrap',
    }}>{children}</span>
  );
}

function BTabBar({ active = 'list' }) {
  const items = [
    { k: 'list',  l: 'List',  i: (c)=>(<svg width="18" height="18" viewBox="0 0 18 18"><rect x="2" y="3" width="14" height="2.4" rx="1" fill={c}/><rect x="2" y="8" width="14" height="2.4" rx="1" fill={c}/><rect x="2" y="13" width="9" height="2.4" rx="1" fill={c}/></svg>) },
    { k: 'map',   l: 'Map',   i: (c)=>(<svg width="18" height="18" viewBox="0 0 18 18"><path d="M9 1 C6 1 4 3 4 6 C4 9 9 16 9 16 C9 16 14 9 14 6 C14 3 12 1 9 1 Z" stroke={c} strokeWidth="1.6" fill="none"/><circle cx="9" cy="6" r="1.8" fill={c}/></svg>) },
    { k: 'pick',  l: 'Pick',  i: (c)=>(<svg width="18" height="18" viewBox="0 0 18 18"><path d="M9 15 s-6 -4 -6 -8 c0 -2 1.5 -3.5 3.5 -3.5 c1 0 2 0.5 2.5 1.5 c0.5 -1 1.5 -1.5 2.5 -1.5 c2 0 3.5 1.5 3.5 3.5 c0 4 -6 8 -6 8 z" stroke={c} strokeWidth="1.6" fill="none"/></svg>) },
    { k: 'me',    l: 'Saved', i: (c)=>(<svg width="18" height="18" viewBox="0 0 18 18"><path d="M4 2 H14 V16 L9 12 L4 16 Z" stroke={c} strokeWidth="1.6" fill="none" strokeLinejoin="round"/></svg>) },
  ];
  return (
    <div style={{
      position: 'absolute', left: 0, right: 0, bottom: 0, height: 84,
      background: B.bone, borderTop: `1px solid ${B.rule}`,
      display: 'flex', alignItems: 'flex-start', justifyContent: 'space-around',
      padding: '10px 12px 0', zIndex: 30,
    }}>
      {items.map(it => {
        const a = active === it.k;
        return (
          <div key={it.k} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, padding: '6px 10px' }}>
            {it.i(a ? B.orange : B.ink3)}
            <span style={{
              fontFamily: B.mono, fontSize: 10, fontWeight: 600,
              letterSpacing: 0.6, textTransform: 'uppercase',
              color: a ? B.orange : B.ink3,
            }}>{it.l}</span>
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen B1 — Wishlist
// ─────────────────────────────────────────────────────────────
function BWishlist() {
  const items = SCOUT_RESTAURANTS.slice(0, 5);
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: B.bone, minHeight: '100%', fontFamily: B.display, color: B.ink, paddingBottom: 100 }}>
        {/* Top: logo + avatars */}
        <div style={{ padding: '58px 20px 6px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <ScoutPinS size={28} color={B.orange} />
            <span style={{ fontFamily: B.display, fontSize: 22, fontWeight: 700, letterSpacing: -0.5 }}>Scout</span>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: B.bone2, display: 'grid', placeItems: 'center' }}>
              <svg width="16" height="16" viewBox="0 0 16 16"><circle cx="8" cy="8" r="6" stroke={B.ink} strokeWidth="1.6" fill="none"/><path d="M11 11 L14 14" stroke={B.ink} strokeWidth="1.6" strokeLinecap="round"/></svg>
            </div>
            <div style={{ width: 36, height: 36, borderRadius: 12, background: B.ink, display: 'grid', placeItems: 'center', color: B.bone, fontFamily: B.display, fontWeight: 700, fontSize: 13 }}>+</div>
          </div>
        </div>

        {/* Massive headline */}
        <div style={{ padding: '14px 20px 4px' }}>
          <div style={{ fontFamily: B.display, fontSize: 56, lineHeight: 0.92, fontWeight: 700, letterSpacing: -2.5 }}>
            42 spots,
          </div>
          <div style={{ fontFamily: B.display, fontSize: 56, lineHeight: 0.92, fontWeight: 700, letterSpacing: -2.5, color: B.orange }}>
            yours to try.
          </div>
        </div>

        {/* Sub */}
        <div style={{ padding: '14px 20px 16px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: B.mono, fontSize: 11, color: B.ink2, letterSpacing: 0.4, textTransform: 'uppercase' }}>
            Sorted: walking distance
          </div>
          <div style={{ fontFamily: B.mono, fontSize: 11, color: B.ink2, letterSpacing: 0.4, textTransform: 'uppercase', display: 'inline-flex', alignItems: 'center', gap: 4 }}>
            <span style={{ width: 6, height: 6, background: B.orange, borderRadius: 99 }} />
            Mission District
          </div>
        </div>

        {/* Tabs as segmented control */}
        <div style={{ margin: '0 20px 14px', height: 44, background: B.bone2, borderRadius: 14, padding: 4, display: 'flex' }}>
          <div style={{ flex: 1, borderRadius: 11, background: B.ink, color: B.bone, display: 'grid', placeItems: 'center', fontFamily: B.display, fontWeight: 600, fontSize: 13 }}>
            Want to try · 42
          </div>
          <div style={{ flex: 1, display: 'grid', placeItems: 'center', fontFamily: B.display, fontWeight: 600, fontSize: 13, color: B.ink2 }}>
            Visited · 18
          </div>
        </div>

        {/* Filter chips */}
        <div style={{ padding: '0 20px 14px', display: 'flex', gap: 7, overflow: 'hidden' }}>
          <BChip active>All</BChip>
          <BChip accent>Open now</BChip>
          <BChip>&lt; 1 mi</BChip>
          <BChip>$$</BChip>
          <BChip>Date</BChip>
        </div>

        {/* Cards */}
        <div style={{ padding: '0 20px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          {items.map((r, i) => (
            <div key={r.id} style={{
              display: 'flex', gap: 14, padding: 14, borderRadius: 22,
              background: i === 0 ? B.ink : B.bone, color: i === 0 ? B.bone : B.ink,
              border: i === 0 ? 'none' : `1.5px solid ${B.rule}`,
            }}>
              <ScoutPhoto hue={r.hue} label="photo" style={{ width: 84, height: 100 }} radius={14} dark={i === 0} />
              <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
                <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
                  <div style={{ fontFamily: B.display, fontSize: 19, fontWeight: 700, letterSpacing: -0.4, lineHeight: 1.1 }}>{r.name}</div>
                </div>
                <div style={{ marginTop: 4, fontFamily: B.mono, fontSize: 11, color: i === 0 ? 'rgba(255,255,255,0.6)' : B.ink2, letterSpacing: 0.3, textTransform: 'uppercase' }}>
                  {r.cuisine} · {r.price}
                </div>
                <div style={{ flex: 1 }} />
                <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between' }}>
                  <BStatusBadge status={r.status} />
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontFamily: B.display, fontSize: 24, fontWeight: 700, lineHeight: 1, letterSpacing: -0.8, color: i === 0 ? B.sun : B.orange }}>
                      {r.dist}<span style={{ fontFamily: B.mono, fontSize: 11, marginLeft: 3, letterSpacing: 0.4, color: i === 0 ? 'rgba(255,255,255,0.5)' : B.ink3 }}>MI</span>
                    </div>
                    <div style={{ fontFamily: B.mono, fontSize: 10, color: i === 0 ? 'rgba(255,255,255,0.5)' : B.ink3, marginTop: 2, letterSpacing: 0.5 }}>
                      ★ {r.rating.toFixed(1)}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Floating Pick CTA */}
        <div style={{
          position: 'absolute', bottom: 100, left: '50%', transform: 'translateX(-50%)',
          background: B.orange, color: '#fff', padding: '14px 22px', borderRadius: 99,
          boxShadow: '0 12px 28px rgba(255,107,0,0.40)', zIndex: 28,
          display: 'flex', alignItems: 'center', gap: 10,
          fontFamily: B.display, fontWeight: 700, fontSize: 14, letterSpacing: -0.2,
        }}>
          <span style={{ fontSize: 16 }}>♥</span> Pick for us
        </div>
      </div>
      <BTabBar active="list" />
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen B2 — Restaurant detail
// ─────────────────────────────────────────────────────────────
function BDetail() {
  const r = SCOUT_RESTAURANTS[1]; // Mister Jiu's
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: B.bone, minHeight: '100%', fontFamily: B.display, color: B.ink, paddingBottom: 110 }}>
        {/* Hero with overlap */}
        <div style={{ position: 'relative' }}>
          <ScoutPhoto hue={r.hue} label="hero photo" radius={0} style={{ height: 360, width: '100%' }} />
          <div style={{ position: 'absolute', top: 56, left: 16, right: 16, display: 'flex', justifyContent: 'space-between' }}>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: B.bone, display: 'grid', placeItems: 'center' }}>
              <svg width="10" height="16" viewBox="0 0 10 16"><path d="M8 2 L2 8 L8 14" stroke={B.ink} strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
            </div>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: B.orange, color: '#fff', display: 'grid', placeItems: 'center', fontSize: 18 }}>♥</div>
          </div>
          {/* Photo counter */}
          <div style={{
            position: 'absolute', bottom: 16, left: 16, padding: '6px 12px',
            background: B.ink, color: B.bone, borderRadius: 99,
            fontFamily: B.mono, fontSize: 11, letterSpacing: 0.5, fontWeight: 600,
          }}>1/12 PHOTOS</div>
        </div>

        {/* Title block — bone bleed over hero */}
        <div style={{ marginTop: -36, background: B.bone, borderRadius: '28px 28px 0 0', padding: '24px 20px 0', position: 'relative' }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
            <div>
              <div style={{ fontFamily: B.display, fontSize: 36, fontWeight: 700, letterSpacing: -1.2, lineHeight: 1 }}>
                {r.name}
              </div>
              <div style={{ marginTop: 8, fontFamily: B.mono, fontSize: 12, color: B.ink2, letterSpacing: 0.4, textTransform: 'uppercase' }}>
                {r.cuisine} · {r.price} · {r.dist} mi away
              </div>
            </div>
            <div style={{
              minWidth: 64, height: 64, borderRadius: 18, background: B.ink, color: B.bone,
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
            }}>
              <div style={{ fontFamily: B.display, fontSize: 24, fontWeight: 700, lineHeight: 1 }}>{r.rating.toFixed(1)}</div>
              <div style={{ fontFamily: B.mono, fontSize: 9, letterSpacing: 0.6, marginTop: 2, color: B.sun }}>★ RATING</div>
            </div>
          </div>

          <div style={{ marginTop: 14, display: 'flex', gap: 8, alignItems: 'center' }}>
            <BStatusBadge status="open" big />
            <span style={{ fontFamily: B.mono, fontSize: 11, color: B.ink2, letterSpacing: 0.4 }}>CLOSES 10PM</span>
          </div>
        </div>

        {/* Action row */}
        <div style={{ padding: '20px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
          {[
            { l: 'Directions',  i: <svg width="16" height="16" viewBox="0 0 16 16"><path d="M2 8 L14 8 M10 4 L14 8 L10 12" stroke={B.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg> },
            { l: 'Reserve',     i: <svg width="16" height="16" viewBox="0 0 16 16"><rect x="2" y="3" width="12" height="11" rx="2" stroke={B.ink} strokeWidth="1.6" fill="none"/><path d="M2 6 L14 6 M6 1.5 V4 M10 1.5 V4" stroke={B.ink} strokeWidth="1.6"/></svg> },
            { l: 'Share',       i: <svg width="16" height="16" viewBox="0 0 16 16"><path d="M8 1 V10 M5 4 L8 1 L11 4 M3 9 V13 A1 1 0 0 0 4 14 H12 A1 1 0 0 0 13 13 V9" stroke={B.ink} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg> },
          ].map(a => (
            <div key={a.l} style={{
              height: 54, borderRadius: 14, background: B.bone2,
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2,
            }}>
              {a.i}
              <span style={{ fontFamily: B.display, fontSize: 11, fontWeight: 600, letterSpacing: 0.1 }}>{a.l}</span>
            </div>
          ))}
        </div>

        {/* Note from partner */}
        <div style={{ margin: '20px 20px 0', padding: 16, borderRadius: 18, background: B.orange, color: '#fff' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <div style={{ width: 22, height: 22, borderRadius: 99, background: '#fff', color: B.orange, display: 'grid', placeItems: 'center', fontFamily: B.display, fontWeight: 700, fontSize: 11 }}>J</div>
            <span style={{ fontFamily: B.mono, fontSize: 10, letterSpacing: 0.4, textTransform: 'uppercase', opacity: 0.9 }}>Jordan saved this · 3d</span>
          </div>
          <div style={{ fontFamily: B.display, fontSize: 16, fontWeight: 500, lineHeight: 1.35, letterSpacing: -0.2 }}>
            Anna Sou's tasting menu, the salt &amp; pepper crab is non-negotiable.
          </div>
        </div>

        {/* Dishes */}
        <div style={{ margin: '24px 20px 0' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontFamily: B.display, fontSize: 22, fontWeight: 700, letterSpacing: -0.6 }}>What to order</div>
            <div style={{ fontFamily: B.mono, fontSize: 10, color: B.ink3, letterSpacing: 0.5, textTransform: 'uppercase' }}>3 picks</div>
          </div>
          <div style={{ display: 'flex', gap: 10, overflow: 'hidden' }}>
            {[
              { n: 'Salt & pepper crab', tag: '★ Must',  hue: 14 },
              { n: 'Whole roast duck',   tag: 'Share',   hue: 26 },
              { n: 'Mapo tofu',          tag: 'Spicy',   hue: 8 },
            ].map(d => (
              <div key={d.n} style={{ flex: 1 }}>
                <ScoutPhoto hue={d.hue} label="dish" style={{ height: 110 }} radius={14} />
                <div style={{ marginTop: 8, fontFamily: B.display, fontSize: 13, fontWeight: 600, lineHeight: 1.2 }}>{d.n}</div>
                <div style={{ marginTop: 3, fontFamily: B.mono, fontSize: 9.5, color: B.orange, letterSpacing: 0.5, textTransform: 'uppercase' }}>{d.tag}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Hours condensed grid */}
        <div style={{ margin: '24px 20px 0' }}>
          <div style={{ fontFamily: B.display, fontSize: 22, fontWeight: 700, letterSpacing: -0.6, marginBottom: 12 }}>Hours</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 6 }}>
            {['Mo','Tu','We','Th','Fr','Sa','Su'].map((d, i) => {
              const today = i === 0;
              const closed = i === 6;
              return (
                <div key={d} style={{
                  height: 56, borderRadius: 12, padding: 6,
                  background: today ? B.orange : (closed ? B.bone2 : B.bone),
                  border: today ? 'none' : `1.5px solid ${B.rule}`,
                  color: today ? '#fff' : (closed ? B.ink3 : B.ink),
                  display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 2,
                }}>
                  <div style={{ fontFamily: B.mono, fontSize: 10, letterSpacing: 0.5, opacity: 0.85 }}>{d}</div>
                  <div style={{ fontFamily: B.display, fontSize: 11, fontWeight: 700 }}>{closed ? '—' : (i === 5 ? '11–12' : '5–10')}</div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Visited toggle CTA */}
        <div style={{ padding: '24px 20px 0' }}>
          <div style={{ height: 56, borderRadius: 16, background: B.ink, color: B.bone, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, fontFamily: B.display, fontWeight: 700, fontSize: 15, letterSpacing: -0.2 }}>
            <span style={{ fontSize: 18 }}>✓</span>
            We've been here
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen B3 — Pick for Us (swipe match — full-bleed)
// ─────────────────────────────────────────────────────────────
function BPickForUs() {
  const top = SCOUT_RESTAURANTS[4]; // Liholiho
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: B.ink, minHeight: '100%', fontFamily: B.display, color: B.bone, position: 'relative' }}>
        {/* Top bar */}
        <div style={{ padding: '58px 20px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 32, height: 32, borderRadius: 10, background: 'rgba(255,255,255,0.08)', display: 'grid', placeItems: 'center' }}>
              <svg width="10" height="14" viewBox="0 0 10 14"><path d="M8 2 L2 7 L8 12" stroke={B.bone} strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
            </div>
            <div style={{ fontFamily: B.mono, fontSize: 11, color: 'rgba(255,255,255,0.6)', letterSpacing: 0.5, textTransform: 'uppercase' }}>Pick for us</div>
          </div>
          <div style={{ fontFamily: B.mono, fontSize: 11, color: 'rgba(255,255,255,0.6)', letterSpacing: 0.5 }}>2/5</div>
        </div>

        {/* Headline */}
        <div style={{ padding: '14px 20px 0' }}>
          <div style={{ fontFamily: B.display, fontSize: 32, fontWeight: 700, lineHeight: 1, letterSpacing: -1 }}>
            Both of you, <br/>swiping <span style={{ color: B.orange }}>right now.</span>
          </div>
        </div>

        {/* Filter row */}
        <div style={{ padding: '14px 20px 0', display: 'flex', gap: 6, overflow: 'hidden' }}>
          <span style={{ display: 'inline-flex', alignItems: 'center', height: 28, padding: '0 12px', borderRadius: 99, background: 'rgba(255,255,255,0.08)', fontFamily: B.mono, fontSize: 10.5, color: 'rgba(255,255,255,0.85)', letterSpacing: 0.4, textTransform: 'uppercase' }}>Walking</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', height: 28, padding: '0 12px', borderRadius: 99, background: 'rgba(255,255,255,0.08)', fontFamily: B.mono, fontSize: 10.5, color: 'rgba(255,255,255,0.85)', letterSpacing: 0.4, textTransform: 'uppercase' }}>$ – $$</span>
          <span style={{ display: 'inline-flex', alignItems: 'center', height: 28, padding: '0 12px', borderRadius: 99, background: 'rgba(255,255,255,0.08)', fontFamily: B.mono, fontSize: 10.5, color: 'rgba(255,255,255,0.85)', letterSpacing: 0.4, textTransform: 'uppercase' }}>Open now</span>
        </div>

        {/* Card stack */}
        <div style={{ margin: '22px 20px 0', height: 470, position: 'relative' }}>
          {/* back card */}
          <div style={{ position: 'absolute', inset: '20px 16px 0 16px', borderRadius: 26, background: 'rgba(255,255,255,0.08)' }} />
          <div style={{ position: 'absolute', inset: '10px 8px 0 8px', borderRadius: 26, background: 'rgba(255,255,255,0.14)' }} />
          {/* top card */}
          <div style={{
            position: 'absolute', inset: 0, borderRadius: 26, background: B.bone, color: B.ink, overflow: 'hidden',
            transform: 'rotate(3deg)',
            boxShadow: '0 20px 50px rgba(0,0,0,0.45)',
          }}>
            <ScoutPhoto hue={top.hue} label="hero" radius={0} style={{ height: 280 }} />
            <div style={{ padding: '18px 18px 0' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontFamily: B.mono, fontSize: 10, color: B.ink3, letterSpacing: 0.5, textTransform: 'uppercase' }}>
                    {top.cuisine} · {top.price}
                  </div>
                  <div style={{ fontFamily: B.display, fontSize: 26, fontWeight: 700, letterSpacing: -0.9, lineHeight: 1.05, marginTop: 4 }}>
                    {top.name}
                  </div>
                </div>
                <div style={{ minWidth: 56, height: 56, borderRadius: 14, background: B.orange, color: '#fff', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                  <div style={{ fontFamily: B.display, fontSize: 18, fontWeight: 700, lineHeight: 1 }}>{top.dist}</div>
                  <div style={{ fontFamily: B.mono, fontSize: 8.5, letterSpacing: 0.6 }}>MILES</div>
                </div>
              </div>
              <div style={{ marginTop: 14, display: 'flex', gap: 18 }}>
                <div>
                  <div style={{ fontFamily: B.display, fontSize: 16, fontWeight: 700 }}>★ {top.rating}</div>
                  <div style={{ fontFamily: B.mono, fontSize: 9.5, color: B.ink3, letterSpacing: 0.5 }}>RATING</div>
                </div>
                <div>
                  <div style={{ fontFamily: B.display, fontSize: 16, fontWeight: 700 }}>19 min</div>
                  <div style={{ fontFamily: B.mono, fontSize: 9.5, color: B.ink3, letterSpacing: 0.5 }}>WALK</div>
                </div>
                <div>
                  <div style={{ fontFamily: B.display, fontSize: 16, fontWeight: 700, color: '#0BAA51' }}>Open</div>
                  <div style={{ fontFamily: B.mono, fontSize: 9.5, color: B.ink3, letterSpacing: 0.5 }}>NOW</div>
                </div>
              </div>
            </div>
          </div>

          {/* Yes overlay */}
          <div style={{
            position: 'absolute', top: 30, right: -12, transform: 'rotate(8deg)',
            background: B.orange, color: '#fff', padding: '8px 16px', borderRadius: 8,
            fontFamily: B.display, fontWeight: 800, fontSize: 24, letterSpacing: 0.5,
            border: '3px solid #fff', boxShadow: '0 10px 30px rgba(255,107,0,0.4)',
          }}>YES</div>
        </div>

        {/* Big action buttons */}
        <div style={{ marginTop: 26, display: 'flex', justifyContent: 'center', gap: 18 }}>
          <div style={{ width: 64, height: 64, borderRadius: 20, background: 'rgba(255,255,255,0.10)', display: 'grid', placeItems: 'center', fontFamily: B.display, fontSize: 28, fontWeight: 700, color: B.bone }}>×</div>
          <div style={{ width: 84, height: 64, borderRadius: 20, background: B.orange, display: 'grid', placeItems: 'center', color: '#fff', fontSize: 26 }}>♥</div>
          <div style={{ width: 64, height: 64, borderRadius: 20, background: 'rgba(255,255,255,0.10)', display: 'grid', placeItems: 'center', fontFamily: B.display, fontSize: 24, color: B.bone }}>↺</div>
        </div>

        {/* Partner ticker */}
        <div style={{ margin: '22px 20px 0', padding: 14, borderRadius: 16, background: 'rgba(255,255,255,0.06)', display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ display: 'flex' }}>
            <div style={{ width: 30, height: 30, borderRadius: 99, background: B.orange, border: `2px solid ${B.ink}`, color: '#fff', display: 'grid', placeItems: 'center', fontFamily: B.display, fontSize: 12, fontWeight: 700 }}>M</div>
            <div style={{ width: 30, height: 30, borderRadius: 99, background: B.sun, border: `2px solid ${B.ink}`, color: B.ink, display: 'grid', placeItems: 'center', fontFamily: B.display, fontSize: 12, fontWeight: 700, marginLeft: -10 }}>J</div>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontFamily: B.display, fontSize: 13, fontWeight: 600 }}>Morgan just liked Liholiho</div>
            <div style={{ fontFamily: B.mono, fontSize: 10, color: 'rgba(255,255,255,0.55)', letterSpacing: 0.4, textTransform: 'uppercase', marginTop: 2 }}>1 match · 3 to go</div>
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen B4 — Map view
// ─────────────────────────────────────────────────────────────
function BMap() {
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ position: 'relative', height: '100%', background: B.bone2 }}>
        {/* abstract map */}
        <div style={{ position: 'absolute', inset: 0, background:
          `linear-gradient(180deg, #efe9dc 0, #e6dec8 100%)` }}>
          {/* roads (orthogonal) */}
          {[0.18, 0.32, 0.46, 0.62, 0.78].map(t => (
            <div key={`h${t}`} style={{ position: 'absolute', left: '-5%', right: '-5%', top: `${t * 100}%`, height: 3, background: 'rgba(255,255,255,0.85)', transform: 'rotate(-3deg)' }} />
          ))}
          {[0.22, 0.48, 0.74].map(t => (
            <div key={`v${t}`} style={{ position: 'absolute', top: '-5%', bottom: '-5%', left: `${t * 100}%`, width: 3, background: 'rgba(255,255,255,0.85)' }} />
          ))}
          {/* park blob */}
          <div style={{ position: 'absolute', left: '55%', top: '20%', width: 140, height: 100, borderRadius: '40% 60% 50% 50%', background: '#cfdcb8', opacity: 0.7 }} />
        </div>

        {/* Top search */}
        <div style={{ position: 'absolute', top: 56, left: 16, right: 16, zIndex: 12 }}>
          <div style={{ height: 56, borderRadius: 18, background: B.bone, display: 'flex', alignItems: 'center', padding: '0 8px 0 16px', boxShadow: '0 10px 24px rgba(0,0,0,0.12)' }}>
            <ScoutPinS size={20} color={B.orange} />
            <div style={{ marginLeft: 12, flex: 1, fontFamily: B.display, fontWeight: 600, fontSize: 14, letterSpacing: -0.2 }}>
              42 places <span style={{ fontFamily: B.mono, fontWeight: 500, fontSize: 11, color: B.ink2, marginLeft: 6, letterSpacing: 0.3, textTransform: 'uppercase' }}>Want to try</span>
            </div>
            <div style={{ width: 40, height: 40, borderRadius: 12, background: B.bone2, display: 'grid', placeItems: 'center' }}>
              <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 4 H12 M4 7 H10 M6 10 H8" stroke={B.ink} strokeWidth="1.6" strokeLinecap="round"/></svg>
            </div>
          </div>
          {/* chip row */}
          <div style={{ marginTop: 10, display: 'flex', gap: 7, overflow: 'hidden' }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', height: 30, padding: '0 12px', borderRadius: 10, background: B.ink, color: B.bone, fontFamily: B.display, fontSize: 12, fontWeight: 600 }}>All</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', height: 30, padding: '0 12px', borderRadius: 10, background: B.bone, fontFamily: B.display, fontSize: 12, fontWeight: 600 }}>Open now</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', height: 30, padding: '0 12px', borderRadius: 10, background: B.bone, fontFamily: B.display, fontSize: 12, fontWeight: 600 }}>Visited</span>
          </div>
        </div>

        {/* Pins */}
        {SCOUT_PINS.map(p => {
          const r = SCOUT_RESTAURANTS.find(x => x.id === p.id);
          const featured = p.id === 1;
          return (
            <div key={p.id} style={{
              position: 'absolute', left: `${p.x * 100}%`, top: `${p.y * 100}%`,
              transform: 'translate(-50%, -100%)', zIndex: featured ? 8 : 7,
            }}>
              {featured ? (
                <div style={{ background: B.orange, color: '#fff', padding: '8px 14px', borderRadius: 14, fontFamily: B.display, fontWeight: 700, fontSize: 13, letterSpacing: -0.2, boxShadow: '0 8px 18px rgba(255,107,0,0.5)' }}>
                  {p.label} · <span style={{ fontFamily: B.mono, fontWeight: 600, fontSize: 11 }}>{r?.dist}MI</span>
                </div>
              ) : (
                <div style={{ width: 32, height: 32, borderRadius: '50% 50% 50% 4px', background: B.ink, transform: 'rotate(-45deg)', display: 'grid', placeItems: 'center', boxShadow: '0 4px 10px rgba(0,0,0,0.25)' }}>
                  <span style={{ transform: 'rotate(45deg)', color: B.orange, fontFamily: B.display, fontWeight: 700, fontSize: 11 }}>S</span>
                </div>
              )}
            </div>
          );
        })}

        {/* Bottom horizontal card carousel */}
        <div style={{ position: 'absolute', bottom: 96, left: 0, right: 0, padding: '0 16px', display: 'flex', gap: 10, overflow: 'hidden', zIndex: 8 }}>
          {SCOUT_RESTAURANTS.slice(0, 3).map((r, i) => (
            <div key={r.id} style={{
              width: 220, flexShrink: 0,
              background: i === 0 ? B.ink : B.bone, color: i === 0 ? B.bone : B.ink,
              borderRadius: 18, padding: 12,
              boxShadow: '0 14px 30px rgba(0,0,0,0.18)',
            }}>
              <div style={{ display: 'flex', gap: 10 }}>
                <ScoutPhoto hue={r.hue} label="ph" style={{ width: 56, height: 56 }} radius={10} dark={i === 0} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontFamily: B.display, fontSize: 14, fontWeight: 700, letterSpacing: -0.3, lineHeight: 1.1 }}>{r.name}</div>
                  <div style={{ fontFamily: B.mono, fontSize: 9.5, color: i === 0 ? 'rgba(255,255,255,0.55)' : B.ink3, letterSpacing: 0.4, textTransform: 'uppercase', marginTop: 3 }}>
                    {r.cuisine} · {r.price}
                  </div>
                  <div style={{ marginTop: 6, fontFamily: B.display, fontSize: 16, fontWeight: 700, color: i === 0 ? B.sun : B.orange, letterSpacing: -0.5 }}>
                    {r.dist}<span style={{ fontFamily: B.mono, fontSize: 9, letterSpacing: 0.5, marginLeft: 3, color: i === 0 ? 'rgba(255,255,255,0.5)' : B.ink3 }}>MI</span>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>

        <BTabBar active="map" />
      </div>
    </IOSDevice>
  );
}

Object.assign(window, { BWishlist, BDetail, BPickForUs, BMap });
