// ─────────────────────────────────────────────────────────────
// Direction A · Atlas — Editorial, cream, serif numerals, compass motif
// ─────────────────────────────────────────────────────────────
//   • Palette:  cream paper, ink near-black, burnt orange accent
//   • Type:     DM Serif Display (numerals + display) + DM Sans (UI)
//   • Voice:    Travel journal / restaurant atlas

const A = {
  paper:  '#F7F1E6',
  paper2: '#EFE6D4',
  ink:    '#1B1612',
  ink2:   'rgba(27,22,18,0.62)',
  ink3:   'rgba(27,22,18,0.42)',
  rule:   'rgba(27,22,18,0.10)',
  burnt:  '#CC5500',
  orange: '#E5651C',
  serif:  '"DM Serif Display", "Newsreader", Georgia, serif',
  sans:   '"DM Sans", -apple-system, system-ui, sans-serif',
};

// Tiny stat block w/ serif numerals over a label — used throughout Atlas
function AStat({ value, label, big = false, align = 'left', color = A.ink }) {
  return (
    <div style={{ textAlign: align, lineHeight: 1 }}>
      <div style={{
        fontFamily: A.serif, fontSize: big ? 38 : 26, color,
        fontWeight: 400, letterSpacing: -0.5,
      }}>{value}</div>
      <div style={{
        fontFamily: A.sans, fontSize: 9.5, color: A.ink3,
        textTransform: 'uppercase', letterSpacing: 1.4, marginTop: 6,
      }}>{label}</div>
    </div>
  );
}

function AStatusDot({ status }) {
  const map = {
    open:   { c: '#1E7A3A', t: 'Open' },
    closes: { c: A.burnt,   t: 'Closes soon' },
    opens:  { c: A.ink3,    t: 'Opens later' },
  };
  const s = map[status] || map.open;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <span style={{ width: 6, height: 6, borderRadius: 99, background: s.c }} />
      <span style={{ fontFamily: A.sans, fontSize: 11, color: A.ink2, letterSpacing: 0.2 }}>
        {s.t}
      </span>
    </span>
  );
}

// Burnt-orange pill chip
function AChip({ children, active = false }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', height: 26,
      padding: '0 11px', borderRadius: 99,
      fontFamily: A.sans, fontSize: 11.5, fontWeight: 500,
      letterSpacing: 0.2, whiteSpace: 'nowrap',
      background: active ? A.ink : 'transparent',
      color: active ? A.paper : A.ink2,
      border: `1px solid ${active ? A.ink : A.rule}`,
    }}>{children}</span>
  );
}

// Tab icons — line-drawn, ~1.6 stroke to match Atlas weight.
function AIcon({ name, color = A.ink3, size = 22 }) {
  const s = { stroke: color, strokeWidth: 1.6, fill: 'none', strokeLinecap: 'round', strokeLinejoin: 'round' };
  switch (name) {
    case 'list':
      return (
        <svg width={size} height={size} viewBox="0 0 22 22">
          <circle cx="5" cy="6"  r="0.9" fill={color} />
          <circle cx="5" cy="11" r="0.9" fill={color} />
          <circle cx="5" cy="16" r="0.9" fill={color} />
          <path d="M9 6 H17 M9 11 H17 M9 16 H15" {...s} />
        </svg>
      );
    case 'map':
      return (
        <svg width={size} height={size} viewBox="0 0 22 22">
          <path d="M11 3.5 C7.7 3.5 5.5 5.9 5.5 9 C5.5 12.8 11 18.5 11 18.5 C11 18.5 16.5 12.8 16.5 9 C16.5 5.9 14.3 3.5 11 3.5 Z" {...s} />
          <circle cx="11" cy="9" r="2.1" {...s} />
        </svg>
      );
    case 'pick':
      // Two overlapping cards / picks
      return (
        <svg width={size} height={size} viewBox="0 0 22 22">
          <rect x="3.5" y="5.5" width="9" height="12" rx="2" {...s} transform="rotate(-8 8 11.5)" />
          <rect x="9.5" y="4.5" width="9" height="12" rx="2" {...s} transform="rotate(8 14 10.5)" />
        </svg>
      );
    case 'journal':
      // Open book
      return (
        <svg width={size} height={size} viewBox="0 0 22 22">
          <path d="M11 6 C9 4.6 6.6 4.2 4 4.4 V16.4 C6.6 16.2 9 16.6 11 18" {...s} />
          <path d="M11 6 C13 4.6 15.4 4.2 18 4.4 V16.4 C15.4 16.2 13 16.6 11 18" {...s} />
          <path d="M11 6 V18" {...s} />
        </svg>
      );
    default: return null;
  }
}

function ATabBar({ active = 'list' }) {
  const items = [
    { k: 'list',    icon: 'list'    },
    { k: 'map',     icon: 'map'     },
    { k: 'pick',    icon: 'pick'    },
    { k: 'journal', icon: 'journal' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 16, right: 16, bottom: 22, height: 60,
      borderRadius: 30, background: A.paper, zIndex: 30,
      boxShadow: '0 10px 30px rgba(50,30,10,0.18), 0 0 0 1px rgba(27,22,18,0.08)',
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      padding: '0 14px',
    }}>
      {items.map(it => {
        const on = active === it.k;
        return (
          <div key={it.k} style={{
            width: 46, height: 44, borderRadius: 22,
            display: 'grid', placeItems: 'center',
            background: on ? 'rgba(204,85,0,0.10)' : 'transparent',
            position: 'relative',
          }}>
            <AIcon name={it.icon} color={on ? A.burnt : A.ink3} />
            {on && (
              <div style={{
                position: 'absolute', bottom: -2, left: '50%', transform: 'translateX(-50%)',
                width: 4, height: 4, borderRadius: 99, background: A.burnt,
              }} />
            )}
          </div>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen A1 — Wishlist (the home / atlas)
// ─────────────────────────────────────────────────────────────
function AWishlist() {
  const items = SCOUT_RESTAURANTS.slice(0, 5);
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, paddingBottom: 110 }}>
        {/* Circle switcher */}
        <div style={{ paddingTop: 46 }}>
          <ACircleHeader />
        </div>
        {/* Masthead */}
        <div style={{ padding: '14px 24px 16px' }}>
          <ACircleRule label={`${A_ACTIVE_CIRCLE.short.toUpperCase()}'S ATLAS`} />
          <div style={{ fontFamily: A.serif, fontSize: 44, lineHeight: 1, letterSpacing: -0.8, marginTop: 10 }}>
            Your <em style={{ color: A.burnt, fontStyle: 'italic' }}>atlas</em>
          </div>
          <div style={{ fontFamily: A.sans, fontSize: 13.5, color: A.ink2, marginTop: 8 }}>
            42 places to try · sorted by distance from <span style={{ color: A.ink }}>Mission&nbsp;District</span>
          </div>
        </div>

        {/* Toggle: Want to try / Visited */}
        <div style={{
          margin: '4px 24px 18px', display: 'flex', borderBottom: `1px solid ${A.rule}`,
        }}>
          <div style={{ padding: '12px 0 14px', marginRight: 28, fontFamily: A.sans, fontSize: 13, fontWeight: 600, borderBottom: `2px solid ${A.burnt}`, color: A.ink }}>
            Want to try <span style={{ color: A.ink3, marginLeft: 4 }}>42</span>
          </div>
          <div style={{ padding: '12px 0 14px', fontFamily: A.sans, fontSize: 13, fontWeight: 500, color: A.ink3 }}>
            Visited <span style={{ marginLeft: 4 }}>18</span>
          </div>
        </div>

        {/* Filter chips */}
        <div style={{ padding: '0 24px 14px', display: 'flex', gap: 6, overflow: 'hidden' }}>
          <AChip active>All</AChip>
          <AChip>Walking</AChip>
          <AChip>$ – $$</AChip>
          <AChip>Open now</AChip>
          <AChip>Date</AChip>
        </div>

        {/* Entries */}
        <div style={{ padding: '0 24px' }}>
          {items.map((r, i) => (
            <div key={r.id} style={{
              display: 'flex', gap: 14, padding: '18px 0',
              borderTop: i === 0 ? `1px solid ${A.rule}` : 'none',
              borderBottom: `1px solid ${A.rule}`,
              alignItems: 'flex-start',
            }}>
              {/* Index numeral */}
              <div style={{ width: 30, paddingTop: 4 }}>
                <div style={{ fontFamily: A.serif, fontSize: 22, color: A.burnt, lineHeight: 1 }}>
                  {String(i + 1).padStart(2, '0')}
                </div>
              </div>

              {/* Body */}
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', gap: 8 }}>
                  <div style={{ fontFamily: A.serif, fontSize: 20, lineHeight: 1.1, letterSpacing: -0.2, color: A.ink }}>
                    {r.name}
                  </div>
                  <div style={{ fontFamily: A.serif, fontSize: 18, color: A.ink, whiteSpace: 'nowrap' }}>
                    {r.dist}<span style={{ fontFamily: A.sans, fontSize: 10, color: A.ink3, marginLeft: 3, letterSpacing: 0.5 }}>MI</span>
                  </div>
                </div>
                <div style={{ marginTop: 4, fontFamily: A.sans, fontSize: 12.5, color: A.ink2, display: 'flex', gap: 6, alignItems: 'center' }}>
                  <span>{r.cuisine}</span>
                  <span style={{ color: A.ink3 }}>·</span>
                  <span>{r.price}</span>
                  <span style={{ color: A.ink3 }}>·</span>
                  <span style={{ fontFamily: A.serif, color: A.ink }}>{r.rating.toFixed(1)}</span>
                </div>
                <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <AStatusDot status={r.status} />
                  <div style={{ display: 'flex', gap: 5 }}>
                    {r.vibe.slice(0, 2).map(v => (
                      <span key={v} style={{ fontFamily: A.sans, fontSize: 10.5, color: A.ink3, letterSpacing: 0.3, textTransform: 'lowercase' }}>· {v}</span>
                    ))}
                  </div>
                </div>
              </div>

              {/* Tiny photo */}
              <ScoutPhoto hue={r.hue} label="photo" style={{ width: 64, height: 76, flexShrink: 0 }} radius={10} />
            </div>
          ))}
        </div>
      </div>
      <ATabBar active="list" />
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen A2 — Restaurant detail (rich info card)
// ─────────────────────────────────────────────────────────────
function ADetail() {
  const r = SCOUT_RESTAURANTS[0]; // Kismet
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, paddingBottom: 32 }}>
        {/* Hero photo */}
        <div style={{ position: 'relative' }}>
          <ScoutPhoto hue={r.hue} label="hero photo" radius={0} style={{ height: 340, width: '100%' }} />

          {/* Top controls overlay — back + circle pill + heart */}
          <div style={{ position: 'absolute', top: 56, left: 16, right: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 38, height: 38, borderRadius: 99, background: 'rgba(247,241,230,0.92)', backdropFilter: 'blur(10px)', display: 'grid', placeItems: 'center', boxShadow: '0 4px 12px rgba(50,30,10,0.18)' }}>
              <svg width="10" height="16" viewBox="0 0 10 16"><path d="M8 2 L2 8 L8 14" stroke={A.ink} strokeWidth="2" fill="none" strokeLinecap="round" /></svg>
            </div>
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 8, height: 38,
              padding: '0 12px 0 6px', borderRadius: 99,
              background: 'rgba(247,241,230,0.92)', backdropFilter: 'blur(10px)',
              boxShadow: '0 4px 12px rgba(50,30,10,0.18), 0 0 0 1px rgba(27,22,18,0.06)',
            }}>
              <div style={{ display: 'flex' }}>
                {A_ACTIVE_CIRCLE.members.map((m, i) => (
                  <div key={i} style={{ width: 26, height: 26, borderRadius: 99, background: i === 0 ? A_ACTIVE_CIRCLE.accent : A.ink, color: A.paper, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 11.5, border: `1.5px solid ${A.paper}`, marginLeft: i === 0 ? 0 : -9, zIndex: 5 - i }}>{m}</div>
                ))}
              </div>
              <span style={{ fontFamily: A.serif, fontSize: 14, color: A.ink, lineHeight: 1 }}>{A_ACTIVE_CIRCLE.name}</span>
              <svg width="9" height="5" viewBox="0 0 10 6"><path d="M1 1 L5 5 L9 1" stroke={A.ink2} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
            </div>
            <div style={{ width: 38, height: 38, borderRadius: 99, background: A.burnt, display: 'grid', placeItems: 'center', color: A.paper, fontFamily: A.serif, fontSize: 14, boxShadow: '0 4px 12px rgba(204,85,0,0.35)' }}>♥</div>
          </div>

          {/* Photo strip / count */}
          <div style={{
            position: 'absolute', bottom: 14, right: 14, padding: '5px 10px', borderRadius: 99,
            background: 'rgba(15,10,5,0.55)', color: A.paper, fontFamily: A.sans, fontSize: 11,
            display: 'inline-flex', alignItems: 'center', gap: 6,
          }}>
            <span>1 / 12</span>
          </div>
        </div>

        {/* Title block */}
        <div style={{ padding: '22px 24px 0' }}>
          <div style={{ fontFamily: A.sans, fontSize: 11.5, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6 }}>
            {r.cuisine} · {r.price} · 0.4 mi
          </div>
          <div style={{ fontFamily: A.serif, fontSize: 40, lineHeight: 1, letterSpacing: -0.8, marginTop: 8 }}>
            {r.name}
          </div>
          <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 14 }}>
            <AStatusDot status="open" />
            <span style={{ fontFamily: A.sans, fontSize: 12, color: A.ink2 }}>Closes 11 pm</span>
          </div>
        </div>

        {/* Stat row */}
        <div style={{
          margin: '22px 24px 0', display: 'grid', gridTemplateColumns: '1fr 1fr 1fr',
          borderTop: `1px solid ${A.rule}`, borderBottom: `1px solid ${A.rule}`,
          padding: '18px 0', gap: 12,
        }}>
          <AStat value="4.7" label="Rating" big />
          <AStat value="$$" label="Price" big align="center" />
          <AStat value="0.4" label="Miles away" big align="right" />
        </div>

        {/* Saved by + note */}
        <div style={{ margin: '20px 24px 0', padding: 18, background: A.paper2, borderRadius: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
            <div style={{ width: 26, height: 26, borderRadius: 99, background: A.burnt, color: A.paper, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 12 }}>J</div>
            <span style={{ fontFamily: A.sans, fontSize: 12, color: A.ink2 }}>
              Saved by <span style={{ color: A.ink, fontWeight: 600 }}>Jordan</span> · 3 days ago
            </span>
          </div>
          <div style={{ fontFamily: A.serif, fontStyle: 'italic', fontSize: 16, lineHeight: 1.35, color: A.ink }}>
            "Saw it on Eater — apparently the lamb ribs and the spicy fried cauliflower are the move. Patio for warm nights."
          </div>
        </div>

        {/* Your journal entry point */}
        <div style={{ margin: '20px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 12 }}>
            <div style={{ fontFamily: A.serif, fontSize: 22, letterSpacing: -0.3 }}>Your journal</div>
            <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.2 }}>3 visits · 6 photos</div>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            {[14, 36, 22, 8].map((h, i) => (
              <div key={i} style={{ flex: 1, position: 'relative' }}>
                <ScoutPhoto hue={h} label={i === 1 ? 'video' : 'photo'} style={{ height: 78 }} radius={10} />
                {i === 1 && (
                  <div style={{
                    position: 'absolute', top: 6, right: 6, width: 18, height: 18, borderRadius: 99,
                    background: 'rgba(15,10,5,0.55)', display: 'grid', placeItems: 'center',
                  }}>
                    <svg width="7" height="7" viewBox="0 0 7 7"><path d="M1 0.5 L6 3.5 L1 6.5 Z" fill={A.paper}/></svg>
                  </div>
                )}
                {i === 3 && (
                  <div style={{
                    position: 'absolute', inset: 0, borderRadius: 10,
                    background: 'rgba(15,10,5,0.55)', display: 'grid', placeItems: 'center',
                    fontFamily: A.serif, color: A.paper, fontSize: 18,
                  }}>+ 8</div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Top dishes */}
        <div style={{ margin: '26px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 12 }}>
            <div style={{ fontFamily: A.serif, fontSize: 22, letterSpacing: -0.3 }}>Top dishes</div>
            <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.2 }}>From reviews</div>
          </div>
          <div style={{ display: 'flex', gap: 10, overflow: 'hidden' }}>
            {[
              { n: 'Lamb ribs',          hue: 14 },
              { n: 'Spicy cauliflower',  hue: 36 },
              { n: 'Persian fairy floss',hue: 28 },
            ].map(d => (
              <div key={d.n} style={{ flex: 1 }}>
                <ScoutPhoto hue={d.hue} label="dish" style={{ height: 96 }} radius={12} />
                <div style={{ marginTop: 8, fontFamily: A.serif, fontSize: 14, color: A.ink }}>{d.n}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Hours */}
        <div style={{ margin: '26px 24px 0' }}>
          <div style={{ fontFamily: A.serif, fontSize: 22, letterSpacing: -0.3, marginBottom: 10 }}>Hours</div>
          <div>
            {[
              ['Today',  '5 pm — 11 pm', true],
              ['Tue',    '5 pm — 11 pm'],
              ['Wed',    '5 pm — 11 pm'],
              ['Thu',    '5 pm — 11 pm'],
              ['Fri',    '5 pm — 12 am'],
              ['Sat',    '11 am — 12 am'],
              ['Sun',    'Closed', false, true],
            ].map(([d, h, today, closed], i) => (
              <div key={d} style={{
                display: 'flex', justifyContent: 'space-between', padding: '10px 0',
                borderTop: i === 0 ? `1px solid ${A.rule}` : 'none',
                borderBottom: `1px solid ${A.rule}`,
                fontFamily: A.sans, fontSize: 14,
                color: closed ? A.ink3 : (today ? A.ink : A.ink2),
                fontWeight: today ? 600 : 400,
              }}>
                <span>{d}</span><span style={{ fontFamily: A.serif }}>{h}</span>
              </div>
            ))}
          </div>
        </div>

        {/* CTA */}
        <div style={{ padding: '26px 24px 0', display: 'flex', gap: 10 }}>
          <div style={{ flex: 1, height: 52, borderRadius: 26, background: A.ink, color: A.paper, fontFamily: A.sans, fontSize: 14.5, fontWeight: 600, display: 'grid', placeItems: 'center', letterSpacing: 0.3 }}>
            Mark as visited
          </div>
          <div style={{ width: 52, height: 52, borderRadius: 26, background: A.paper, border: `1px solid ${A.rule}`, display: 'grid', placeItems: 'center' }}>
            <svg width="16" height="16" viewBox="0 0 16 16"><path d="M3 4 H13 M3 8 H13 M3 12 H10" stroke={A.ink} strokeWidth="1.6" strokeLinecap="round" /></svg>
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen A3 — Pick for Us (swipe match)
// ─────────────────────────────────────────────────────────────
function APickForUs() {
  const top = SCOUT_RESTAURANTS[2]; // Tartine on top of the stack
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, position: 'relative' }}>
        <div style={{ paddingTop: 46 }}>
          <ACircleHeader />
        </div>
        <div style={{ padding: '12px 24px 8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <ACircleRule label="TONIGHT" />
            <div style={{ fontFamily: A.serif, fontSize: 13, color: A.ink2 }}>Round&nbsp;2 of 5</div>
          </div>
          <div style={{ fontFamily: A.serif, fontSize: 36, lineHeight: 1, letterSpacing: -0.5, marginTop: 12 }}>
            Pick <em style={{ color: A.burnt, fontStyle: 'italic' }}>for us</em>
          </div>
          <div style={{ fontFamily: A.sans, fontSize: 13.5, color: A.ink2, marginTop: 8 }}>
            Walking distance · <span style={{ color: A.ink }}>$ – $$</span> · open now
          </div>
        </div>

        {/* Card stack */}
        <div style={{ margin: '24px auto 0', width: 320, height: 460, position: 'relative' }}>
          {/* back card */}
          <div style={{
            position: 'absolute', inset: '24px 18px 0 18px', borderRadius: 28,
            background: A.paper2, transform: 'rotate(-2.5deg)',
            boxShadow: '0 6px 18px rgba(50,30,10,0.10)',
          }} />
          <div style={{
            position: 'absolute', inset: '12px 8px 0 8px', borderRadius: 28,
            background: A.paper, transform: 'rotate(1.5deg)',
            boxShadow: '0 8px 24px rgba(50,30,10,0.12)', border: `1px solid ${A.rule}`,
          }} />
          {/* top card */}
          <div style={{
            position: 'absolute', inset: 0, borderRadius: 28, background: A.paper, overflow: 'hidden',
            boxShadow: '0 18px 50px rgba(50,30,10,0.22), 0 0 0 1px rgba(27,22,18,0.06)',
            transform: 'rotate(-1deg)',
          }}>
            <ScoutPhoto hue={top.hue} label="hero" radius={0} style={{ width: '100%', height: 280 }} />
            <div style={{ padding: '18px 20px 14px' }}>
              <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.4 }}>
                {top.cuisine} · {top.price} · {top.dist} mi
              </div>
              <div style={{ fontFamily: A.serif, fontSize: 28, lineHeight: 1.05, letterSpacing: -0.4, marginTop: 6 }}>
                {top.name}
              </div>
              <div style={{ marginTop: 12, display: 'flex', gap: 18 }}>
                <AStat value={top.rating.toFixed(1)} label="Rating" />
                <AStat value="13" label="min walk" />
                <AStat value={top.price} label="Tier" />
              </div>
            </div>
          </div>

          {/* swipe verdict — peeking heart on right edge */}
          <div style={{
            position: 'absolute', top: 40, right: -8, padding: '6px 12px',
            background: A.burnt, color: A.paper, borderRadius: 99,
            fontFamily: A.sans, fontSize: 11, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase',
            transform: 'rotate(-1deg)',
            boxShadow: '0 8px 20px rgba(204,85,0,0.4)',
          }}>♥ Yes</div>
        </div>

        {/* Swipe actions */}
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 28, marginTop: 30 }}>
          <div style={{ width: 56, height: 56, borderRadius: 99, background: A.paper, border: `1px solid ${A.rule}`, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 22, color: A.ink2 }}>×</div>
          <div style={{ width: 72, height: 72, borderRadius: 99, background: A.burnt, color: A.paper, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 28, boxShadow: '0 10px 24px rgba(204,85,0,0.35)' }}>♥</div>
          <div style={{ width: 56, height: 56, borderRadius: 99, background: A.paper, border: `1px solid ${A.rule}`, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 20, color: A.ink2 }}>↺</div>
        </div>

        {/* Partner status */}
        <div style={{ margin: '24px 24px 0', padding: '14px 16px', background: A.paper2, borderRadius: 18, display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ width: 30, height: 30, borderRadius: 99, background: A.ink, display: 'grid', placeItems: 'center', color: A.paper, fontFamily: A.serif, fontSize: 13 }}>M</div>
          <div style={{ flex: 1, fontFamily: A.sans, fontSize: 12.5, color: A.ink2 }}>
            <span style={{ color: A.ink, fontWeight: 600 }}>Morgan</span> is also picking · 4 of 5 done
          </div>
          <div style={{ width: 36, height: 6, background: A.rule, borderRadius: 99, overflow: 'hidden' }}>
            <div style={{ width: '80%', height: '100%', background: A.burnt }} />
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen A4 — Map view
// ─────────────────────────────────────────────────────────────
function AMap() {
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ position: 'relative', height: '100%', background: A.paper2 }}>
        {/* Map "canvas" — abstract topo lines */}
        <div style={{ position: 'absolute', inset: 0, background:
          `radial-gradient(circle at 30% 40%, #efe2c8 0, transparent 50%),
           radial-gradient(circle at 70% 70%, #ebd9b8 0, transparent 55%),
           ${A.paper2}` }}>
          {/* topo-like rings */}
          {[120, 180, 250, 340, 440].map(r => (
            <div key={r} style={{
              position: 'absolute', left: '50%', top: '52%',
              width: r * 2, height: r * 2, marginLeft: -r, marginTop: -r,
              borderRadius: '50%', border: `1px solid rgba(204,85,0,0.07)`,
            }} />
          ))}
          {/* a few roads */}
          <div style={{ position: 'absolute', left: 0, top: '40%', right: 0, height: 2, background: 'rgba(27,22,18,0.06)', transform: 'rotate(-4deg)' }} />
          <div style={{ position: 'absolute', left: 0, top: '60%', right: 0, height: 2, background: 'rgba(27,22,18,0.06)', transform: 'rotate(2deg)' }} />
          <div style={{ position: 'absolute', left: '38%', top: 0, bottom: 0, width: 2, background: 'rgba(27,22,18,0.06)' }} />
        </div>

        {/* Header bar — circle pill (glass) + filters */}
        <div style={{ position: 'absolute', top: 46, left: 0, right: 0, zIndex: 10 }}>
          <ACircleHeader onHero={true} right={(
            <div style={{
              display: 'inline-flex', alignItems: 'center', gap: 6, height: 36,
              padding: '0 14px', borderRadius: 99,
              background: 'rgba(247,241,230,0.92)', backdropFilter: 'blur(10px)',
              boxShadow: '0 4px 12px rgba(50,30,10,0.15), 0 0 0 1px rgba(27,22,18,0.06)',
              fontFamily: A.sans, fontSize: 12, color: A.ink2,
            }}>
              <svg width="12" height="12" viewBox="0 0 14 14"><path d="M2 4 H12 M4 7 H10 M6 10 H8" stroke={A.ink} strokeWidth="1.5" strokeLinecap="round" /></svg>
              Filters
            </div>
          )} />
          <div style={{ padding: '6px 16px 0', display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ height: 30, padding: '0 12px', borderRadius: 99, background: 'rgba(247,241,230,0.92)', backdropFilter: 'blur(10px)', display: 'flex', alignItems: 'center', gap: 6, boxShadow: '0 4px 12px rgba(50,30,10,0.10), 0 0 0 1px rgba(27,22,18,0.06)', fontFamily: A.sans, fontSize: 11.5, color: A.ink2 }}>
              <span style={{ color: A.ink, fontWeight: 600 }}>42 places</span> · Walking, $–$$
            </div>
          </div>
        </div>

        {/* Pins */}
        {SCOUT_PINS.map(p => {
          const r = SCOUT_RESTAURANTS.find(x => x.id === p.id);
          const featured = p.id === 1;
          return (
            <div key={p.id} style={{
              position: 'absolute', left: `${p.x * 100}%`, top: `${p.y * 100}%`,
              transform: 'translate(-50%, -100%)', zIndex: featured ? 6 : 5,
            }}>
              <div style={{
                background: featured ? A.ink : A.paper,
                color: featured ? A.paper : A.ink,
                border: `1px solid ${featured ? A.ink : A.rule}`,
                padding: '6px 10px', borderRadius: 14, fontFamily: A.sans, fontSize: 11.5, fontWeight: 600,
                whiteSpace: 'nowrap', display: 'flex', alignItems: 'center', gap: 6,
                boxShadow: '0 4px 12px rgba(50,30,10,0.18)',
              }}>
                <span style={{ width: 6, height: 6, borderRadius: 99, background: A.burnt }} />
                {p.label}
                {featured && <span style={{ fontFamily: A.serif, fontSize: 12, marginLeft: 2 }}>{r?.dist}mi</span>}
              </div>
              <div style={{ width: 2, height: 8, background: featured ? A.ink : A.rule, margin: '0 auto' }} />
              <div style={{ width: 8, height: 8, borderRadius: 99, background: A.burnt, margin: '0 auto' }} />
            </div>
          );
        })}

        {/* Bottom card peek */}
        <div style={{
          position: 'absolute', left: 16, right: 16, bottom: 96,
          background: A.paper, borderRadius: 24, padding: 16,
          boxShadow: '0 18px 48px rgba(50,30,10,0.18), 0 0 0 1px rgba(27,22,18,0.06)',
          display: 'flex', gap: 14, alignItems: 'center',
        }}>
          <ScoutPhoto hue={28} label="photo" style={{ width: 64, height: 64 }} radius={12} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: A.serif, fontSize: 19, color: A.ink, lineHeight: 1.05 }}>Kismet</div>
            <div style={{ fontFamily: A.sans, fontSize: 12, color: A.ink2, marginTop: 4 }}>Mediterranean · $$ · 0.4 mi</div>
            <div style={{ marginTop: 6 }}><AStatusDot status="open" /></div>
          </div>
          <div style={{ width: 40, height: 40, borderRadius: 99, background: A.burnt, color: A.paper, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 20 }}>›</div>
        </div>

        <ATabBar active="map" />
      </div>
    </IOSDevice>
  );
}

Object.assign(window, { AWishlist, ADetail, APickForUs, AMap });
