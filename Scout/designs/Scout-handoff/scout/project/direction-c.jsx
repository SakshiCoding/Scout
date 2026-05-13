// ─────────────────────────────────────────────────────────────
// Direction C · Ember — Cozy dark, glowing burnt orange, intimate
// ─────────────────────────────────────────────────────────────
//   • Palette:  deep cocoa, ember orange, cream highlights
//   • Type:     Instrument Serif (display, italic) + Manrope (UI)
//   • Voice:    Quiet, intimate, evening date-night

const C = {
  bg:     '#16110D',
  surf:   '#1F1812',
  surf2:  '#2A1F16',
  edge:   'rgba(255,210,170,0.08)',
  rule:   'rgba(255,210,170,0.10)',
  cream:  '#F5EBDD',
  cream2: 'rgba(245,235,221,0.62)',
  cream3: 'rgba(245,235,221,0.40)',
  orange: '#FF7A1A',
  ember:  '#FF9F4A',
  burnt:  '#CC5500',
  serif:  '"Instrument Serif", "Newsreader", Georgia, serif',
  sans:   '"Manrope", -apple-system, system-ui, sans-serif',
};

function CStatusDot({ status, size = 'sm' }) {
  const map = {
    open:   { c: '#5EE292', t: 'Open now' },
    closes: { c: C.ember,   t: 'Closes soon' },
    opens:  { c: C.cream3,  t: 'Opens later' },
  };
  const s = map[status] || map.open;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
      <span style={{
        width: 7, height: 7, borderRadius: 99, background: s.c,
        boxShadow: `0 0 8px ${s.c}`,
      }} />
      <span style={{ fontFamily: C.sans, fontSize: size === 'lg' ? 12.5 : 11, color: C.cream2, letterSpacing: 0.2 }}>
        {s.t}
      </span>
    </span>
  );
}

function CChip({ children, active = false }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', height: 30,
      padding: '0 13px', borderRadius: 99,
      fontFamily: C.sans, fontSize: 12, fontWeight: 500,
      background: active ? C.orange : 'rgba(255,210,170,0.06)',
      color: active ? '#1A0C00' : C.cream2,
      border: active ? 'none' : `1px solid ${C.edge}`,
      whiteSpace: 'nowrap',
    }}>{children}</span>
  );
}

function CTabBar({ active = 'list' }) {
  const items = [
    { k: 'list', l: 'List' },
    { k: 'map',  l: 'Map'  },
    { k: 'pick', l: 'Pick' },
    { k: 'me',   l: 'Saved' },
  ];
  return (
    <div style={{
      position: 'absolute', left: 16, right: 16, bottom: 22, height: 58, zIndex: 30,
      borderRadius: 29, background: 'rgba(31,24,18,0.85)',
      backdropFilter: 'blur(20px) saturate(160%)',
      WebkitBackdropFilter: 'blur(20px) saturate(160%)',
      border: `1px solid ${C.edge}`,
      display: 'flex', alignItems: 'center', justifyContent: 'space-around',
      padding: '0 12px',
      boxShadow: '0 12px 30px rgba(0,0,0,0.4)',
    }}>
      {items.map(it => (
        <div key={it.k} style={{
          fontFamily: C.sans, fontSize: 12, fontWeight: 600, letterSpacing: 0.3,
          color: active === it.k ? C.orange : C.cream3,
          padding: '8px 14px', borderRadius: 18,
          background: active === it.k ? 'rgba(255,122,26,0.10)' : 'transparent',
        }}>{it.l}</div>
      ))}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen C1 — Wishlist
// ─────────────────────────────────────────────────────────────
function CWishlist() {
  const items = SCOUT_RESTAURANTS.slice(0, 5);
  return (
    <IOSDevice width={402} height={874} dark>
      <div style={{
        background: `radial-gradient(circle at 20% 0%, rgba(255,122,26,0.18) 0, transparent 50%), ${C.bg}`,
        minHeight: '100%', fontFamily: C.sans, color: C.cream, paddingBottom: 110,
      }}>
        {/* Header */}
        <div style={{ padding: '58px 22px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <ScoutBinoculars size={22} color={C.orange} />
            <span style={{ fontFamily: C.serif, fontSize: 20, color: C.cream, letterSpacing: 0.3 }}>Scout</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 0 }}>
            <div style={{ width: 30, height: 30, borderRadius: 99, background: C.orange, border: `2px solid ${C.bg}`, display: 'grid', placeItems: 'center', color: '#1A0C00', fontFamily: C.sans, fontWeight: 700, fontSize: 12 }}>J</div>
            <div style={{ width: 30, height: 30, borderRadius: 99, background: C.ember, border: `2px solid ${C.bg}`, marginLeft: -10, display: 'grid', placeItems: 'center', color: '#1A0C00', fontFamily: C.sans, fontWeight: 700, fontSize: 12 }}>M</div>
          </div>
        </div>

        {/* Greeting + headline */}
        <div style={{ padding: '14px 22px 4px' }}>
          <div style={{ fontFamily: C.sans, fontSize: 12, color: C.cream3, letterSpacing: 0.6, textTransform: 'uppercase' }}>Tuesday · 7:14 pm</div>
          <div style={{ fontFamily: C.serif, fontSize: 40, lineHeight: 1.05, marginTop: 10, letterSpacing: -0.5 }}>
            Hungry? <em style={{ fontStyle: 'italic', color: C.ember }}>You've got</em>
            <br/>42 ideas tonight.
          </div>
        </div>

        {/* Tabs */}
        <div style={{ margin: '20px 22px 14px', display: 'flex', gap: 18, alignItems: 'center' }}>
          <div style={{
            fontFamily: C.sans, fontSize: 13.5, fontWeight: 700, color: C.cream,
            display: 'inline-flex', alignItems: 'center', gap: 6,
          }}>
            Want to try
            <span style={{
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              minWidth: 22, height: 18, padding: '0 6px', borderRadius: 9,
              background: C.orange, color: '#1A0C00', fontSize: 11, fontWeight: 700,
            }}>42</span>
          </div>
          <div style={{ fontFamily: C.sans, fontSize: 13.5, fontWeight: 500, color: C.cream3 }}>
            Visited · 18
          </div>
        </div>

        {/* Filter chips */}
        <div style={{ padding: '0 22px 16px', display: 'flex', gap: 7, overflow: 'hidden' }}>
          <CChip active>All</CChip>
          <CChip>&lt; 1 mi</CChip>
          <CChip>$ – $$</CChip>
          <CChip>Open now</CChip>
          <CChip>Date</CChip>
        </div>

        {/* Cards */}
        <div style={{ padding: '0 22px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          {items.map((r, i) => (
            <div key={r.id} style={{
              padding: 14, borderRadius: 22, background: C.surf, border: `1px solid ${C.edge}`,
              display: 'flex', gap: 14,
              boxShadow: i === 0 ? '0 0 0 1px rgba(255,122,26,0.18), 0 10px 30px rgba(0,0,0,0.35)' : 'none',
              position: 'relative', overflow: 'hidden',
            }}>
              {i === 0 && <div style={{ position: 'absolute', inset: 0, background: 'radial-gradient(circle at 90% 0%, rgba(255,122,26,0.08), transparent 60%)', pointerEvents: 'none' }} />}
              <ScoutPhoto hue={r.hue} dark label="photo" style={{ width: 78, height: 92, flexShrink: 0 }} radius={14} />
              <div style={{ flex: 1, minWidth: 0, position: 'relative' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', gap: 8 }}>
                  <div style={{ minWidth: 0 }}>
                    <div style={{ fontFamily: C.serif, fontSize: 20, color: C.cream, lineHeight: 1.05, letterSpacing: -0.2 }}>{r.name}</div>
                    <div style={{ marginTop: 5, fontFamily: C.sans, fontSize: 12, color: C.cream2 }}>
                      {r.cuisine} · {r.price} · ★ {r.rating}
                    </div>
                  </div>
                  <div style={{ textAlign: 'right', flexShrink: 0 }}>
                    <div style={{ fontFamily: C.serif, fontSize: 22, color: C.ember, lineHeight: 1 }}>
                      {r.dist}
                      <span style={{ fontFamily: C.sans, fontSize: 9.5, color: C.cream3, marginLeft: 3, letterSpacing: 0.6 }}>MI</span>
                    </div>
                    <div style={{ fontFamily: C.sans, fontSize: 9.5, color: C.cream3, marginTop: 2, letterSpacing: 0.4, textTransform: 'uppercase' }}>walk · {r.dist === '0.4' ? '6m' : '14m'}</div>
                  </div>
                </div>

                <div style={{ marginTop: 10, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                  <CStatusDot status={r.status} />
                  <div style={{ display: 'flex', gap: 4 }}>
                    {r.vibe.slice(0, 1).map(v => (
                      <span key={v} style={{
                        fontFamily: C.sans, fontSize: 10.5, color: C.cream2,
                        padding: '2px 8px', borderRadius: 99,
                        background: 'rgba(255,210,170,0.06)', border: `1px solid ${C.edge}`,
                      }}>{v}</span>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Floating action: Pick for Us */}
      <div style={{
        position: 'absolute', bottom: 100, right: 22, zIndex: 28,
        width: 60, height: 60, borderRadius: 30,
        background: `radial-gradient(circle at 30% 30%, ${C.ember}, ${C.orange} 70%)`,
        display: 'grid', placeItems: 'center', color: '#fff', fontSize: 24,
        boxShadow: '0 0 30px rgba(255,122,26,0.6), 0 10px 24px rgba(0,0,0,0.4)',
      }}>♥</div>

      <CTabBar active="list" />
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen C2 — Detail
// ─────────────────────────────────────────────────────────────
function CDetail() {
  const r = SCOUT_RESTAURANTS[5]; // State Bird Provisions
  return (
    <IOSDevice width={402} height={874} dark>
      <div style={{ background: C.bg, minHeight: '100%', fontFamily: C.sans, color: C.cream, paddingBottom: 110 }}>
        {/* Hero with vignette */}
        <div style={{ position: 'relative' }}>
          <ScoutPhoto hue={r.hue} dark label="hero photo" radius={0} style={{ height: 380 }} />
          <div style={{ position: 'absolute', inset: 0, background: `linear-gradient(180deg, rgba(22,17,13,0.55) 0%, transparent 30%, transparent 55%, ${C.bg} 100%)` }} />

          {/* Top bar */}
          <div style={{ position: 'absolute', top: 56, left: 16, right: 16, display: 'flex', justifyContent: 'space-between' }}>
            <div style={{ width: 40, height: 40, borderRadius: 99, background: 'rgba(31,24,18,0.7)', backdropFilter: 'blur(12px)', border: `1px solid ${C.edge}`, display: 'grid', placeItems: 'center' }}>
              <svg width="10" height="16" viewBox="0 0 10 16"><path d="M8 2 L2 8 L8 14" stroke={C.cream} strokeWidth="2" fill="none" strokeLinecap="round"/></svg>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <div style={{ width: 40, height: 40, borderRadius: 99, background: 'rgba(31,24,18,0.7)', backdropFilter: 'blur(12px)', border: `1px solid ${C.edge}`, display: 'grid', placeItems: 'center' }}>
                <svg width="14" height="14" viewBox="0 0 14 14"><path d="M7 1 V13 M1 7 H13" stroke={C.cream} strokeWidth="1.6" strokeLinecap="round"/></svg>
              </div>
              <div style={{ width: 40, height: 40, borderRadius: 99, background: C.orange, color: '#1A0C00', display: 'grid', placeItems: 'center', fontSize: 18, boxShadow: '0 0 20px rgba(255,122,26,0.5)' }}>♥</div>
            </div>
          </div>

          {/* Title overlay on hero */}
          <div style={{ position: 'absolute', left: 22, right: 22, bottom: 24 }}>
            <div style={{ fontFamily: C.sans, fontSize: 11, color: C.cream2, letterSpacing: 1.4, textTransform: 'uppercase', marginBottom: 6 }}>
              {r.cuisine} · {r.price} · {r.dist} miles
            </div>
            <div style={{ fontFamily: C.serif, fontSize: 38, lineHeight: 1, letterSpacing: -0.6, textShadow: '0 4px 20px rgba(0,0,0,0.5)' }}>
              {r.name}
            </div>
          </div>
        </div>

        {/* Status + stats card */}
        <div style={{ margin: '-30px 22px 0', padding: 18, borderRadius: 22, background: C.surf, border: `1px solid ${C.edge}`, position: 'relative', zIndex: 5, boxShadow: '0 18px 40px rgba(0,0,0,0.4)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <CStatusDot status="open" size="lg" />
            <span style={{ fontFamily: C.sans, fontSize: 11.5, color: C.cream3 }}>Closes 11 pm</span>
          </div>
          <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
            <div>
              <div style={{ fontFamily: C.serif, fontSize: 28, color: C.cream, lineHeight: 1 }}>{r.rating.toFixed(1)}</div>
              <div style={{ fontFamily: C.sans, fontSize: 10, color: C.cream3, letterSpacing: 0.6, textTransform: 'uppercase', marginTop: 5 }}>★ Rating</div>
            </div>
            <div style={{ borderLeft: `1px solid ${C.edge}`, paddingLeft: 12 }}>
              <div style={{ fontFamily: C.serif, fontSize: 28, color: C.cream, lineHeight: 1 }}>{r.price}</div>
              <div style={{ fontFamily: C.sans, fontSize: 10, color: C.cream3, letterSpacing: 0.6, textTransform: 'uppercase', marginTop: 5 }}>Price</div>
            </div>
            <div style={{ borderLeft: `1px solid ${C.edge}`, paddingLeft: 12 }}>
              <div style={{ fontFamily: C.serif, fontSize: 28, color: C.ember, lineHeight: 1 }}>14<span style={{ fontSize: 13, color: C.cream3, marginLeft: 2 }}>min</span></div>
              <div style={{ fontFamily: C.sans, fontSize: 10, color: C.cream3, letterSpacing: 0.6, textTransform: 'uppercase', marginTop: 5 }}>Walk</div>
            </div>
          </div>
        </div>

        {/* Saved-by note (intimate) */}
        <div style={{ margin: '20px 22px 0', padding: '0 4px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
            <div style={{ width: 26, height: 26, borderRadius: 99, background: C.ember, color: '#1A0C00', display: 'grid', placeItems: 'center', fontFamily: C.sans, fontWeight: 700, fontSize: 12 }}>M</div>
            <span style={{ fontFamily: C.sans, fontSize: 11.5, color: C.cream2 }}>
              <span style={{ color: C.cream }}>Morgan</span> saved this · last week
            </span>
          </div>
          <div style={{ fontFamily: C.serif, fontStyle: 'italic', fontSize: 19, lineHeight: 1.35, color: C.cream, letterSpacing: -0.1 }}>
            "Dim-sum-style, but new American. Apparently the world's best pancake. We HAVE to go before it gets too cold."
          </div>
        </div>

        {/* Top dishes */}
        <div style={{ margin: '28px 22px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 12 }}>
            <div style={{ fontFamily: C.serif, fontSize: 22 }}>What to order</div>
            <div style={{ fontFamily: C.sans, fontSize: 10.5, color: C.cream3, letterSpacing: 0.6, textTransform: 'uppercase' }}>Top picks</div>
          </div>
          <div style={{ display: 'flex', gap: 10, overflow: 'hidden' }}>
            {[
              { n: 'World\'s best pancake', tag: 'Iconic', hue: 38 },
              { n: 'Quail with rye toast',  tag: 'Share',  hue: 16 },
              { n: 'Garlic bread soup',     tag: 'Cozy',   hue: 26 },
            ].map(d => (
              <div key={d.n} style={{ flex: 1 }}>
                <ScoutPhoto hue={d.hue} dark label="dish" style={{ height: 102 }} radius={14} />
                <div style={{ marginTop: 8, fontFamily: C.serif, fontSize: 14, color: C.cream, lineHeight: 1.2 }}>{d.n}</div>
                <div style={{ marginTop: 3, fontFamily: C.sans, fontSize: 10, color: C.ember, letterSpacing: 0.5, textTransform: 'uppercase' }}>{d.tag}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Hours mini */}
        <div style={{ margin: '26px 22px 0', padding: 16, borderRadius: 18, background: C.surf, border: `1px solid ${C.edge}` }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontFamily: C.serif, fontSize: 17 }}>Tonight</div>
            <span style={{ fontFamily: C.sans, fontSize: 11.5, color: C.cream3 }}>5:30 pm — 11 pm</span>
          </div>
          <div style={{ marginTop: 12, height: 6, borderRadius: 99, background: 'rgba(255,210,170,0.10)', overflow: 'hidden', position: 'relative' }}>
            <div style={{ position: 'absolute', left: '38%', right: '4%', top: 0, bottom: 0, background: `linear-gradient(90deg, ${C.orange}, ${C.ember})`, borderRadius: 99 }} />
            <div style={{ position: 'absolute', left: '50%', top: -3, width: 2, height: 12, background: C.cream }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, fontFamily: C.sans, fontSize: 10, color: C.cream3, letterSpacing: 0.5 }}>
            <span>5pm</span><span style={{ color: C.cream }}>now · 7:14p</span><span>11pm</span>
          </div>
        </div>

        {/* CTA row */}
        <div style={{ padding: '22px 22px 0', display: 'flex', gap: 8 }}>
          <div style={{ flex: 1, height: 52, borderRadius: 26, background: `linear-gradient(180deg, ${C.ember}, ${C.orange})`, color: '#1A0C00', display: 'grid', placeItems: 'center', fontFamily: C.sans, fontSize: 14, fontWeight: 700, letterSpacing: 0.2, boxShadow: '0 10px 24px rgba(255,122,26,0.35)' }}>
            Reserve · OpenTable
          </div>
          <div style={{ width: 52, height: 52, borderRadius: 26, background: C.surf, border: `1px solid ${C.edge}`, display: 'grid', placeItems: 'center' }}>
            <svg width="16" height="16" viewBox="0 0 16 16"><path d="M3 8 H13 M9 4 L13 8 L9 12" stroke={C.cream} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
          </div>
          <div style={{ width: 52, height: 52, borderRadius: 26, background: C.surf, border: `1px solid ${C.edge}`, display: 'grid', placeItems: 'center', fontFamily: C.sans, fontSize: 22, color: C.cream }}>✓</div>
        </div>
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen C3 — Pick for Us / Match reveal
// ─────────────────────────────────────────────────────────────
function CPickForUs() {
  const match = SCOUT_RESTAURANTS[0]; // Kismet — the match
  return (
    <IOSDevice width={402} height={874} dark>
      <div style={{
        background: `radial-gradient(circle at 50% 30%, rgba(255,122,26,0.30) 0, transparent 50%), ${C.bg}`,
        minHeight: '100%', fontFamily: C.sans, color: C.cream, position: 'relative',
      }}>
        {/* Top bar */}
        <div style={{ padding: '58px 22px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ width: 36, height: 36, borderRadius: 99, background: 'rgba(31,24,18,0.6)', border: `1px solid ${C.edge}`, display: 'grid', placeItems: 'center' }}>
            <svg width="12" height="12" viewBox="0 0 12 12"><path d="M2 2 L10 10 M10 2 L2 10" stroke={C.cream} strokeWidth="1.8" strokeLinecap="round"/></svg>
          </div>
          <div style={{ fontFamily: C.sans, fontSize: 11, color: C.cream2, letterSpacing: 1.4, textTransform: 'uppercase' }}>It's a match</div>
          <div style={{ width: 36, height: 36 }} />
        </div>

        {/* Match headline */}
        <div style={{ padding: '40px 22px 0', textAlign: 'center' }}>
          <div style={{ fontFamily: C.serif, fontSize: 56, lineHeight: 0.95, letterSpacing: -1.2 }}>
            You both
          </div>
          <div style={{ fontFamily: C.serif, fontStyle: 'italic', fontSize: 56, lineHeight: 0.95, letterSpacing: -1.2, color: C.ember }}>
            said yes.
          </div>
        </div>

        {/* Match card */}
        <div style={{ margin: '36px 22px 0', position: 'relative' }}>
          {/* glowing ring */}
          <div style={{ position: 'absolute', inset: -6, borderRadius: 28, background: `linear-gradient(135deg, ${C.orange}, ${C.ember}, transparent)`, filter: 'blur(12px)', opacity: 0.6 }} />
          <div style={{ position: 'relative', borderRadius: 24, overflow: 'hidden', background: C.surf, border: `1px solid ${C.edge}` }}>
            <ScoutPhoto hue={match.hue} dark label="hero" radius={0} style={{ height: 220 }} />
            <div style={{ padding: '18px 18px 16px' }}>
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontFamily: C.serif, fontSize: 30, color: C.cream, lineHeight: 1.0, letterSpacing: -0.5 }}>
                    {match.name}
                  </div>
                  <div style={{ marginTop: 8, fontFamily: C.sans, fontSize: 12, color: C.cream2 }}>
                    {match.cuisine} · {match.price} · ★ {match.rating}
                  </div>
                </div>
                <div style={{
                  padding: '6px 12px', borderRadius: 99,
                  background: 'rgba(94,226,146,0.12)', color: '#5EE292',
                  fontFamily: C.sans, fontSize: 11, fontWeight: 700,
                  letterSpacing: 0.4, textTransform: 'uppercase',
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  border: '1px solid rgba(94,226,146,0.30)',
                }}>
                  <span style={{ width: 6, height: 6, borderRadius: 99, background: '#5EE292', boxShadow: '0 0 6px #5EE292' }} />
                  Open
                </div>
              </div>

              {/* Both said yes badge */}
              <div style={{ marginTop: 16, padding: 12, borderRadius: 14, background: 'rgba(255,122,26,0.08)', border: `1px solid rgba(255,122,26,0.20)`, display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ display: 'flex' }}>
                  <div style={{ width: 28, height: 28, borderRadius: 99, background: C.orange, border: `2px solid ${C.surf}`, color: '#1A0C00', display: 'grid', placeItems: 'center', fontFamily: C.sans, fontWeight: 700, fontSize: 11 }}>J</div>
                  <div style={{ width: 28, height: 28, borderRadius: 99, background: C.ember, border: `2px solid ${C.surf}`, marginLeft: -8, color: '#1A0C00', display: 'grid', placeItems: 'center', fontFamily: C.sans, fontWeight: 700, fontSize: 11 }}>M</div>
                </div>
                <div style={{ flex: 1, fontFamily: C.sans, fontSize: 12, color: C.cream }}>
                  Both <span style={{ fontStyle: 'italic', fontFamily: C.serif, color: C.ember, fontSize: 14 }}>swiped yes</span> — round 1
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div style={{ padding: '28px 22px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <div style={{ height: 56, borderRadius: 28, background: `linear-gradient(180deg, ${C.ember}, ${C.orange})`, color: '#1A0C00', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, fontFamily: C.sans, fontWeight: 700, fontSize: 14.5, letterSpacing: 0.2, boxShadow: '0 14px 30px rgba(255,122,26,0.35)' }}>
            <svg width="16" height="16" viewBox="0 0 16 16"><path d="M3 8 H13 M9 4 L13 8 L9 12" stroke="#1A0C00" strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
            Get directions · 6 min walk
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ flex: 1, height: 52, borderRadius: 26, background: C.surf, border: `1px solid ${C.edge}`, color: C.cream, display: 'grid', placeItems: 'center', fontFamily: C.sans, fontSize: 13.5, fontWeight: 600 }}>
              Reserve
            </div>
            <div style={{ flex: 1, height: 52, borderRadius: 26, background: C.surf, border: `1px solid ${C.edge}`, color: C.cream, display: 'grid', placeItems: 'center', fontFamily: C.sans, fontSize: 13.5, fontWeight: 600 }}>
              Keep swiping
            </div>
          </div>
        </div>

        {/* hint */}
        <div style={{ position: 'absolute', bottom: 30, left: 0, right: 0, textAlign: 'center', fontFamily: C.sans, fontSize: 11, color: C.cream3, letterSpacing: 0.4 }}>
          3 more spots both of you might love →
        </div>
      </div>
    </IOSDevice>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen C4 — Map view (dark)
// ─────────────────────────────────────────────────────────────
function CMap() {
  return (
    <IOSDevice width={402} height={874} dark>
      <div style={{ position: 'relative', height: '100%', background: '#0E0A07' }}>
        {/* Dark abstract map */}
        <div style={{ position: 'absolute', inset: 0, background:
          `radial-gradient(circle at 50% 40%, #1A130D 0, #0E0A07 70%)` }}>
          {/* warm rings */}
          {[140, 220, 320, 440].map(r => (
            <div key={r} style={{
              position: 'absolute', left: '50%', top: '50%',
              width: r * 2, height: r * 2, marginLeft: -r, marginTop: -r,
              borderRadius: '50%', border: `1px solid rgba(255,122,26,0.06)`,
            }} />
          ))}
          {/* roads */}
          {[0.22, 0.40, 0.58, 0.76].map(t => (
            <div key={`h${t}`} style={{ position: 'absolute', left: 0, right: 0, top: `${t * 100}%`, height: 1, background: 'rgba(255,210,170,0.06)', transform: 'rotate(-2deg)' }} />
          ))}
          {[0.30, 0.55, 0.78].map(t => (
            <div key={`v${t}`} style={{ position: 'absolute', top: 0, bottom: 0, left: `${t * 100}%`, width: 1, background: 'rgba(255,210,170,0.06)' }} />
          ))}
          {/* "you are here" glow */}
          <div style={{ position: 'absolute', left: '46%', top: '47%', width: 80, height: 80, marginLeft: -40, marginTop: -40, borderRadius: '50%', background: 'rgba(255,122,26,0.18)', filter: 'blur(20px)' }} />
        </div>

        {/* Top bar */}
        <div style={{ position: 'absolute', top: 56, left: 16, right: 16, height: 52, zIndex: 12, borderRadius: 26, background: 'rgba(31,24,18,0.85)', backdropFilter: 'blur(20px)', border: `1px solid ${C.edge}`, display: 'flex', alignItems: 'center', padding: '0 8px 0 18px' }}>
          <ScoutBinoculars size={18} color={C.orange} />
          <div style={{ marginLeft: 10, flex: 1, fontFamily: C.sans, fontSize: 13.5, color: C.cream }}>
            42 places <span style={{ color: C.cream3, marginLeft: 6, fontSize: 12 }}>· nearby</span>
          </div>
          <div style={{ width: 36, height: 36, borderRadius: 99, background: 'rgba(255,210,170,0.06)', display: 'grid', placeItems: 'center' }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M2 4 H12 M4 7 H10 M6 10 H8" stroke={C.cream} strokeWidth="1.5" strokeLinecap="round"/></svg>
          </div>
        </div>

        {/* You-are-here dot */}
        <div style={{ position: 'absolute', left: '46%', top: '47%', transform: 'translate(-50%, -50%)', zIndex: 6 }}>
          <div style={{ width: 16, height: 16, borderRadius: 99, background: '#4F9EFF', border: '3px solid #fff', boxShadow: '0 0 14px #4F9EFF' }} />
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
                <div style={{
                  background: `linear-gradient(180deg, ${C.ember}, ${C.orange})`,
                  color: '#1A0C00', padding: '8px 14px', borderRadius: 16,
                  fontFamily: C.sans, fontSize: 12, fontWeight: 700, letterSpacing: -0.1,
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  boxShadow: '0 0 24px rgba(255,122,26,0.6), 0 6px 12px rgba(0,0,0,0.4)',
                }}>
                  {p.label} · {r?.dist}mi
                </div>
              ) : (
                <div style={{
                  width: 26, height: 26, borderRadius: 99, background: C.surf,
                  border: `2px solid ${C.orange}`, display: 'grid', placeItems: 'center',
                  boxShadow: '0 0 12px rgba(255,122,26,0.3)',
                }}>
                  <span style={{ width: 8, height: 8, borderRadius: 99, background: C.orange }} />
                </div>
              )}
            </div>
          );
        })}

        {/* Bottom sheet preview */}
        <div style={{
          position: 'absolute', left: 16, right: 16, bottom: 96, zIndex: 8,
          padding: 16, borderRadius: 22, background: 'rgba(31,24,18,0.92)', backdropFilter: 'blur(20px)',
          border: `1px solid ${C.edge}`, boxShadow: '0 20px 50px rgba(0,0,0,0.5)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <div style={{ fontFamily: C.sans, fontSize: 10.5, color: C.cream3, letterSpacing: 1.4, textTransform: 'uppercase' }}>Closest 3</div>
            <div style={{ fontFamily: C.sans, fontSize: 11.5, color: C.ember }}>See all 42 →</div>
          </div>
          {SCOUT_RESTAURANTS.slice(0, 3).map((r, i) => (
            <div key={r.id} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 0',
              borderTop: i === 0 ? 'none' : `1px solid ${C.edge}`,
            }}>
              <div style={{ width: 22, height: 22, borderRadius: 99, background: i === 0 ? C.orange : 'rgba(255,122,26,0.12)', color: i === 0 ? '#1A0C00' : C.ember, display: 'grid', placeItems: 'center', fontFamily: C.serif, fontSize: 12 }}>
                {i + 1}
              </div>
              <div style={{ flex: 1, fontFamily: C.serif, fontSize: 16, color: C.cream }}>{r.name}</div>
              <div style={{ fontFamily: C.sans, fontSize: 11.5, color: C.cream3 }}>{r.cuisine}</div>
              <div style={{ fontFamily: C.serif, fontSize: 17, color: C.ember }}>{r.dist}<span style={{ fontSize: 10, marginLeft: 2, color: C.cream3, fontFamily: C.sans }}>mi</span></div>
            </div>
          ))}
        </div>

        <CTabBar active="map" />
      </div>
    </IOSDevice>
  );
}

Object.assign(window, { CWishlist, CDetail, CPickForUs, CMap });
