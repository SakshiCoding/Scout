// ─────────────────────────────────────────────────────────────
// Atlas · Circles — multi-group support
// ─────────────────────────────────────────────────────────────
//   Scout is keyed on "circles", not a single partner. You can
//   have a circle with your girlfriend, one with family, one
//   with roommates — each with its own wishlist, map, journal.
//
//   Visual rule: Atlas palette (cream + burnt orange) stays the
//   primary brand everywhere. Each circle just gets a small
//   ACCENT color that identifies it — shown on the switcher pill,
//   member avatars, accent rules, and the journal cover.
//
//   Active circle below = "Morgan & me" (burnt — it happens to
//   match the brand). Switch and the rest of the UI stays Atlas;
//   only the accent dot + member chips change.
// ─────────────────────────────────────────────────────────────

const SCOUT_CIRCLES = [
  { id: 'jm',  name: 'Morgan & me', short: 'Morgan',  accent: '#CC5500', members: ['M', 'J'],
    counts: { places: 42, visited: 18, photos: 47, videos: 9 }, last: 'Oct 14' },
  { id: 'fam', name: 'Family',      short: 'Family',  accent: '#7A8B3C', members: ['M', 'D', 'A'],
    counts: { places: 28, visited:  9, photos: 22, videos: 4 }, last: 'Sep 28' },
  { id: 'rm',  name: 'Roommates',   short: 'Roomies', accent: '#3D5A80', members: ['K', 'L', 'B'],
    counts: { places: 19, visited: 12, photos: 31, videos: 6 }, last: 'Oct 03' },
];

const A_ACTIVE_CIRCLE = SCOUT_CIRCLES[0];

// ─────────────────────────────────────────────────────────────
// ACircleHeader — the switcher pill at the top of every screen.
// `onHero` flips the styling to a glass version that floats over
// photo heroes (detail page).
// ─────────────────────────────────────────────────────────────
function ACircleHeader({ circle = A_ACTIVE_CIRCLE, onHero = false, right = null }) {
  const bg = onHero ? 'rgba(247,241,230,0.85)' : A.paper;
  return (
    <div style={{
      padding: '12px 16px 10px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    }}>
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 10, height: 36,
        padding: '0 14px 0 6px', borderRadius: 99, background: bg,
        boxShadow: onHero
          ? '0 4px 12px rgba(50,30,10,0.15), 0 0 0 1px rgba(27,22,18,0.06)'
          : '0 2px 8px rgba(50,30,10,0.06), 0 0 0 1px rgba(27,22,18,0.06)',
        backdropFilter: onHero ? 'blur(10px)' : undefined,
      }}>
        {/* Avatar stack — first member is filled with accent so the circle is visually identified */}
        <div style={{ display: 'flex' }}>
          {circle.members.slice(0, 3).map((m, i) => (
            <div key={i} style={{
              width: 24, height: 24, borderRadius: 99,
              background: i === 0 ? circle.accent : A.ink,
              color: A.paper, display: 'grid', placeItems: 'center',
              fontFamily: A.serif, fontSize: 11.5, lineHeight: 1,
              border: `1.5px solid ${A.paper}`,
              marginLeft: i === 0 ? 0 : -9, zIndex: 5 - i,
            }}>{m}</div>
          ))}
        </div>
        <span style={{ fontFamily: A.serif, fontSize: 15, letterSpacing: 0.1, color: A.ink, lineHeight: 1 }}>
          {circle.name}
        </span>
        <svg width="10" height="6" viewBox="0 0 10 6"><path d="M1 1 L5 5 L9 1" stroke={A.ink2} strokeWidth="1.5" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
      </div>

      {right || (
        <div style={{
          width: 36, height: 36, borderRadius: 99, background: bg,
          display: 'grid', placeItems: 'center',
          boxShadow: onHero
            ? '0 4px 12px rgba(50,30,10,0.15), 0 0 0 1px rgba(27,22,18,0.06)'
            : '0 2px 8px rgba(50,30,10,0.06), 0 0 0 1px rgba(27,22,18,0.06)',
          backdropFilter: onHero ? 'blur(10px)' : undefined,
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16">
            <circle cx="8" cy="8" r="1.4" fill={A.ink}/>
            <circle cx="8" cy="3" r="1.4" fill={A.ink}/>
            <circle cx="8" cy="13" r="1.4" fill={A.ink}/>
          </svg>
        </div>
      )}
    </div>
  );
}

// Thin accent rule that sits below the masthead on key screens, in the
// active circle's color. Reinforces which circle you're inside.
function ACircleRule({ circle = A_ACTIVE_CIRCLE, label }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <div style={{ width: 18, height: 2, background: circle.accent, borderRadius: 99 }} />
      <span style={{ fontFamily: A.sans, fontSize: 10.5, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6 }}>
        {label || `${circle.short}'s atlas`}
      </span>
    </div>
  );
}

// =============================================================================
// Circle picker — opens when you tap the pill
// =============================================================================
function ACirclePicker() {
  return (
    <IOSDevice width={402} height={874}>
      {/* Dimmed background to suggest sheet over content */}
      <div style={{ position: 'relative', minHeight: '100%', background: 'rgba(15,10,5,0.55)' }}>

        {/* Behind: faint hint of the previous screen */}
        <div style={{ position: 'absolute', inset: 0, opacity: 0.18 }}>
          <div style={{ padding: '58px 24px' }}>
            <div style={{ fontFamily: A.serif, fontSize: 44, color: A.paper, letterSpacing: -0.8 }}>
              Your atlas
            </div>
          </div>
        </div>

        {/* Sheet */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: A.paper, borderRadius: '24px 24px 0 0',
          padding: '12px 0 36px',
          boxShadow: '0 -8px 30px rgba(15,10,5,0.25)',
        }}>
          {/* Drag handle */}
          <div style={{ width: 44, height: 4, background: A.rule, borderRadius: 99, margin: '0 auto 14px' }} />

          {/* Sheet header */}
          <div style={{ padding: '4px 24px 18px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div>
              <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6 }}>
                Switch circle
              </div>
              <div style={{ fontFamily: A.serif, fontSize: 30, lineHeight: 1, letterSpacing: -0.5, marginTop: 6 }}>
                Whose atlas?
              </div>
            </div>
            <div style={{ width: 32, height: 32, borderRadius: 99, background: A.paper2, display: 'grid', placeItems: 'center' }}>
              <svg width="12" height="12" viewBox="0 0 12 12"><path d="M2 2 L10 10 M10 2 L2 10" stroke={A.ink} strokeWidth="1.6" strokeLinecap="round"/></svg>
            </div>
          </div>

          {/* Circles list */}
          <div style={{ padding: '0 12px' }}>
            {SCOUT_CIRCLES.map((c, i) => {
              const active = i === 0;
              return (
                <div key={c.id} style={{
                  display: 'flex', alignItems: 'center', gap: 14,
                  padding: '14px 14px',
                  background: active ? A.paper2 : 'transparent',
                  borderRadius: 18,
                  marginBottom: 4,
                  position: 'relative',
                }}>
                  {/* Accent stripe on left */}
                  <div style={{
                    position: 'absolute', left: 4, top: 16, bottom: 16, width: 3,
                    borderRadius: 99, background: c.accent,
                    opacity: active ? 1 : 0.4,
                  }} />
                  {/* Avatars */}
                  <div style={{ display: 'flex', marginLeft: 8 }}>
                    {c.members.map((m, j) => (
                      <div key={j} style={{
                        width: 32, height: 32, borderRadius: 99,
                        background: j === 0 ? c.accent : A.ink,
                        color: A.paper, display: 'grid', placeItems: 'center',
                        fontFamily: A.serif, fontSize: 14, lineHeight: 1,
                        border: `2px solid ${active ? A.paper2 : A.paper}`,
                        marginLeft: j === 0 ? 0 : -12, zIndex: 5 - j,
                      }}>{m}</div>
                    ))}
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                      <div style={{ fontFamily: A.serif, fontSize: 19, lineHeight: 1.05, letterSpacing: -0.2 }}>{c.name}</div>
                      <div style={{ width: 5, height: 5, borderRadius: 99, background: c.accent }} />
                    </div>
                    <div style={{ fontFamily: A.sans, fontSize: 11.5, color: A.ink3, marginTop: 4, letterSpacing: 0.3 }}>
                      <span style={{ fontFamily: A.serif, color: A.ink2, fontSize: 13 }}>{c.counts.places}</span> places ·
                      <span style={{ fontFamily: A.serif, color: A.ink2, fontSize: 13 }}> {c.counts.visited}</span> visited ·
                      <span style={{ fontFamily: A.serif, color: A.ink2, fontSize: 13 }}> {c.counts.photos}</span> photos
                    </div>
                  </div>
                  {active ? (
                    <div style={{ width: 24, height: 24, borderRadius: 99, background: c.accent, display: 'grid', placeItems: 'center' }}>
                      <svg width="11" height="9" viewBox="0 0 11 9"><path d="M1 5 L4 8 L10 1" stroke={A.paper} strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
                    </div>
                  ) : (
                    <svg width="10" height="14" viewBox="0 0 10 14"><path d="M2 1 L8 7 L2 13" stroke={A.ink3} strokeWidth="1.6" fill="none" strokeLinecap="round"/></svg>
                  )}
                </div>
              );
            })}

            {/* New circle */}
            <div style={{
              display: 'flex', alignItems: 'center', gap: 14, padding: '14px 22px',
              border: `1px dashed ${A.rule}`, borderRadius: 18, marginTop: 8,
            }}>
              <div style={{ width: 36, height: 36, borderRadius: 99, background: A.paper2, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 22, color: A.burnt, lineHeight: 1 }}>+</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontFamily: A.serif, fontSize: 17 }}>Start a new circle</div>
                <div style={{ fontFamily: A.sans, fontSize: 11.5, color: A.ink3, marginTop: 3 }}>
                  Coworkers, a travel group, a city crew…
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// =============================================================================
// Marked-visited auto-prompt — shown after tapping "Mark visited" on detail
// =============================================================================
function AMarkedVisitedSheet() {
  const r = SCOUT_RESTAURANTS[0];
  const c = A_ACTIVE_CIRCLE;
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ position: 'relative', minHeight: '100%', background: 'rgba(15,10,5,0.55)' }}>

        {/* Behind: dimmed detail */}
        <div style={{ position: 'absolute', inset: 0, opacity: 0.22 }}>
          <ScoutPhoto hue={r.hue} label="" style={{ height: 340, width: '100%' }} radius={0} />
          <div style={{ padding: '22px 24px' }}>
            <div style={{ fontFamily: A.serif, fontSize: 40, color: A.paper, letterSpacing: -0.8 }}>{r.name}</div>
          </div>
        </div>

        {/* Sheet */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: A.paper, borderRadius: '24px 24px 0 0',
          padding: '12px 0 32px',
          boxShadow: '0 -10px 36px rgba(15,10,5,0.3)',
        }}>
          <div style={{ width: 44, height: 4, background: A.rule, borderRadius: 99, margin: '0 auto 16px' }} />

          {/* Confetti / kicker */}
          <div style={{ padding: '4px 24px 0' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
              <div style={{ width: 8, height: 8, borderRadius: 99, background: c.accent }} />
              <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6 }}>
                Logged for {c.short}
              </div>
            </div>
            <div style={{ fontFamily: A.serif, fontSize: 32, lineHeight: 1, letterSpacing: -0.5 }}>
              You went to <em style={{ color: A.burnt, fontStyle: 'italic' }}>{r.name}</em>.
            </div>
            <div style={{ fontFamily: A.sans, fontSize: 13.5, color: A.ink2, marginTop: 10, lineHeight: 1.5 }}>
              While it's fresh — drop a photo or two and a quick note. Adds straight to {c.short}'s journal.
            </div>
          </div>

          {/* Compact media tray */}
          <div style={{ padding: '20px 24px 0' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 6 }}>
              {[14, 28, 36].map((h, i) => (
                <div key={i} style={{ position: 'relative' }}>
                  <ScoutPhoto hue={h} label="photo" style={{ height: 78 }} radius={8} />
                  <div style={{
                    position: 'absolute', top: 4, right: 4, width: 16, height: 16, borderRadius: 99,
                    background: 'rgba(15,10,5,0.55)', color: A.paper, display: 'grid', placeItems: 'center', fontSize: 9,
                  }}>×</div>
                </div>
              ))}
              <div style={{
                height: 78, borderRadius: 8, border: `1px dashed ${A.rule}`,
                display: 'grid', placeItems: 'center', color: A.ink3,
              }}>
                <div style={{ textAlign: 'center' }}>
                  <svg width="20" height="16" viewBox="0 0 20 16">
                    <rect x="1" y="3" width="18" height="12" rx="2" stroke={A.ink2} strokeWidth="1.4" fill="none"/>
                    <circle cx="10" cy="9" r="3" stroke={A.ink2} strokeWidth="1.4" fill="none"/>
                    <path d="M6 3 L7.5 1 L12.5 1 L14 3" stroke={A.ink2} strokeWidth="1.4" fill="none" strokeLinecap="round"/>
                  </svg>
                  <div style={{ fontFamily: 'ui-monospace, monospace', fontSize: 8.5, letterSpacing: 0.6, marginTop: 2 }}>add</div>
                </div>
              </div>
            </div>
          </div>

          {/* Note row */}
          <div style={{ padding: '16px 24px 0' }}>
            <div style={{
              padding: '14px 16px', background: A.paper2, borderRadius: 14,
              fontFamily: A.serif, fontStyle: 'italic', fontSize: 14.5, color: A.ink3, lineHeight: 1.4,
            }}>
              Add a quick note…
            </div>
          </div>

          {/* CTAs */}
          <div style={{ padding: '20px 24px 0', display: 'flex', gap: 10 }}>
            <div style={{ flex: 1, height: 50, borderRadius: 25, border: `1px solid ${A.rule}`, fontFamily: A.sans, fontSize: 13.5, color: A.ink2, display: 'grid', placeItems: 'center' }}>
              Skip for now
            </div>
            <div style={{ flex: 1.4, height: 50, borderRadius: 25, background: A.ink, color: A.paper, fontFamily: A.sans, fontSize: 14.5, fontWeight: 600, display: 'grid', placeItems: 'center', letterSpacing: 0.3 }}>
              Save to journal
            </div>
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// =============================================================================
// Cross-post sheet — share a photo / video from one circle's journal to another
// =============================================================================
function ACrossPostSheet() {
  const c = A_ACTIVE_CIRCLE;
  const otherCircles = SCOUT_CIRCLES.filter(x => x.id !== c.id);
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ position: 'relative', minHeight: '100%', background: '#0E0905' }}>
        {/* Dimmed viewer background */}
        <div style={{ position: 'absolute', inset: 0, opacity: 0.4 }}>
          <ScoutPhoto hue={28} dark label="" style={{ height: 520, width: '100%', marginTop: 100 }} radius={0} />
        </div>

        {/* Sheet */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: A.paper, borderRadius: '24px 24px 0 0',
          padding: '12px 0 32px',
          boxShadow: '0 -10px 36px rgba(15,10,5,0.45)',
        }}>
          <div style={{ width: 44, height: 4, background: A.rule, borderRadius: 99, margin: '0 auto 14px' }} />

          {/* Header */}
          <div style={{ padding: '4px 24px 14px', display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 48, height: 48, borderRadius: 8, overflow: 'hidden', position: 'relative', flexShrink: 0 }}>
              <ScoutPhoto hue={28} label="" style={{ width: '100%', height: '100%' }} radius={0} />
              <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', background: 'rgba(15,10,5,0.3)' }}>
                <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2 1 L8 5 L2 9 Z" fill={A.paper}/></svg>
              </div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontFamily: A.serif, fontSize: 20, lineHeight: 1, letterSpacing: -0.3 }}>Share this clip</div>
              <div style={{ fontFamily: A.sans, fontSize: 11.5, color: A.ink3, marginTop: 4, letterSpacing: 0.3 }}>
                Kismet · Oct 14 · {c.name}
              </div>
            </div>
          </div>

          {/* Section: cross-post */}
          <div style={{ padding: '6px 24px 8px' }}>
            <div style={{ fontFamily: A.sans, fontSize: 10.5, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6, marginBottom: 10 }}>
              Add to another circle
            </div>
            {otherCircles.map((oc, i) => (
              <div key={oc.id} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '12px 4px',
                borderBottom: i === otherCircles.length - 1 ? 'none' : `1px solid ${A.rule}`,
              }}>
                <div style={{ display: 'flex' }}>
                  {oc.members.map((m, j) => (
                    <div key={j} style={{
                      width: 28, height: 28, borderRadius: 99,
                      background: j === 0 ? oc.accent : A.ink, color: A.paper,
                      display: 'grid', placeItems: 'center',
                      fontFamily: A.serif, fontSize: 12, lineHeight: 1,
                      border: `2px solid ${A.paper}`,
                      marginLeft: j === 0 ? 0 : -10, zIndex: 5 - j,
                    }}>{m}</div>
                  ))}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                    <div style={{ fontFamily: A.serif, fontSize: 17, lineHeight: 1.05 }}>{oc.name}</div>
                    <div style={{ width: 5, height: 5, borderRadius: 99, background: oc.accent }} />
                  </div>
                  <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, marginTop: 3, letterSpacing: 0.3 }}>
                    {oc.counts.places} places · {oc.counts.photos} photos
                  </div>
                </div>
                {/* Selected state on first */}
                {i === 0 ? (
                  <div style={{
                    width: 22, height: 22, borderRadius: 6, background: oc.accent,
                    display: 'grid', placeItems: 'center',
                  }}>
                    <svg width="11" height="9" viewBox="0 0 11 9"><path d="M1 5 L4 8 L10 1" stroke={A.paper} strokeWidth="1.8" fill="none" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  </div>
                ) : (
                  <div style={{ width: 22, height: 22, borderRadius: 6, border: `1.5px solid ${A.rule}` }} />
                )}
              </div>
            ))}
          </div>

          {/* Section: external */}
          <div style={{ padding: '18px 24px 0' }}>
            <div style={{ fontFamily: A.sans, fontSize: 10.5, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6, marginBottom: 10 }}>
              Or send somewhere else
            </div>
            <div style={{ display: 'flex', gap: 12 }}>
              {[
                { l: 'Messages',  c: '#34C759', icon: (<svg width="20" height="20" viewBox="0 0 20 20"><path d="M10 2.5 C5 2.5 1.5 5.4 1.5 9 C1.5 11 2.5 12.8 4.2 14 L3 17.5 L7 16 C7.9 16.3 8.9 16.5 10 16.5 C15 16.5 18.5 13.6 18.5 9 C18.5 5.4 15 2.5 10 2.5 Z" fill="#fff"/></svg>) },
                { l: 'Mail',      c: '#0A84FF', icon: (<svg width="20" height="20" viewBox="0 0 20 20"><rect x="2" y="5" width="16" height="11" rx="1.5" fill="#fff"/><path d="M2.5 6 L10 11 L17.5 6" stroke="#0A84FF" strokeWidth="1.4" fill="none"/></svg>) },
                { l: 'Copy link', c: A.ink,     icon: (<svg width="20" height="20" viewBox="0 0 20 20"><path d="M8 7 L6 7 C4 7 3 8.5 3 10 C3 11.5 4 13 6 13 L8 13 M12 7 L14 7 C16 7 17 8.5 17 10 C17 11.5 16 13 14 13 L12 13 M7 10 H13" stroke="#F7F1E6" strokeWidth="1.5" fill="none" strokeLinecap="round"/></svg>) },
                { l: 'More',      c: A.paper2,  icon: (<svg width="20" height="20" viewBox="0 0 20 20"><circle cx="5" cy="10" r="1.4" fill={A.ink}/><circle cx="10" cy="10" r="1.4" fill={A.ink}/><circle cx="15" cy="10" r="1.4" fill={A.ink}/></svg>) },
              ].map(x => (
                <div key={x.l} style={{ flex: 1, textAlign: 'center' }}>
                  <div style={{
                    width: 52, height: 52, borderRadius: 16, background: x.c,
                    display: 'grid', placeItems: 'center', margin: '0 auto',
                    border: x.l === 'More' ? `1px solid ${A.rule}` : 'none',
                  }}>{x.icon}</div>
                  <div style={{ fontFamily: A.sans, fontSize: 10.5, color: A.ink2, marginTop: 6, letterSpacing: 0.2 }}>
                    {x.l}
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Confirm CTA */}
          <div style={{ padding: '22px 24px 0' }}>
            <div style={{ height: 52, borderRadius: 26, background: A.ink, color: A.paper, fontFamily: A.sans, fontSize: 14.5, fontWeight: 600, display: 'grid', placeItems: 'center', letterSpacing: 0.3 }}>
              Share to Family
            </div>
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

Object.assign(window, {
  SCOUT_CIRCLES, A_ACTIVE_CIRCLE,
  ACircleHeader, ACircleRule,
  ACirclePicker, AMarkedVisitedSheet, ACrossPostSheet,
});
