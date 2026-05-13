// ─────────────────────────────────────────────────────────────
// Atlas · Journal — picked direction
// ─────────────────────────────────────────────────────────────
//   • Per-location page: Scrapbook (polaroids, tape, italic notes)
//   • Journal tab:        Editorial table of contents
//   • Plus: empty states, new-entry composer, photo viewer
// ─────────────────────────────────────────────────────────────

// Sample journal data ----------------------------------------------------------
const A_JOURNAL_ENTRIES = [
  { date: 'Oct 14', day: '14', mo: 'OCT', year: '2024', tag: 'Birthday dinner',
    note: 'Lamb ribs lived up to the hype. Patio heater right above us — perfect October night.',
    media: [{ t: 'photo', hue: 14 }, { t: 'video', hue: 28, len: '0:15' }, { t: 'photo', hue: 36 }] },
  { date: 'Sep 02', day: '02', mo: 'SEP', year: '2024', tag: 'Casual Tuesday',
    note: 'Just cocktails + mezze at the bar. Bartender said try the Persian fairy floss next time.',
    media: [{ t: 'photo', hue: 22 }, { t: 'photo', hue: 18 }] },
  { date: 'Jul 22', day: '22', mo: 'JUL', year: '2024', tag: 'Out-of-town friends',
    note: 'Loud night but in a good way. Corner table by the window, all four of us.',
    media: [{ t: 'photo', hue: 8 }, { t: 'video', hue: 14, len: '0:09' }, { t: 'photo', hue: 30 }] },
];

const A_JOURNAL_LOCATIONS = [
  { id: 1, name: 'Kismet',                cuisine: 'Mediterranean', visits: 3, count: 8,  videos: 2, last: 'Oct 14', hue: 28 },
  { id: 3, name: 'Tartine Manufactory',   cuisine: 'Bakery',        visits: 5, count: 14, videos: 1, last: 'Oct 09', hue: 42 },
  { id: 6, name: 'State Bird Provisions', cuisine: 'New American',  visits: 4, count: 11, videos: 3, last: 'Sep 18', hue: 36 },
  { id: 5, name: 'Liholiho Yacht Club',   cuisine: 'Hawaiian',      visits: 2, count: 6,  videos: 1, last: 'Sep 02', hue: 22 },
  { id: 8, name: 'Nopa',                  cuisine: 'Californian',   visits: 2, count: 5,  videos: 2, last: 'Aug 30', hue: 18 },
  { id: 7, name: 'Marlowe',               cuisine: 'American',      visits: 1, count: 3,  videos: 0, last: 'Aug 12', hue: 32 },
];

// Shared header — circle pill + back chevron + kicker + serif title -----------
function AJournalSubhead({ title, kicker, extra }) {
  return (
    <>
      <div style={{ paddingTop: 46 }}>
        <ACircleHeader />
      </div>
      <div style={{ padding: '8px 24px 0' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 18 }}>
          <div style={{ width: 36, height: 36, borderRadius: 99, border: `1px solid ${A.rule}`, display: 'grid', placeItems: 'center' }}>
            <svg width="10" height="14" viewBox="0 0 10 14"><path d="M8 1 L2 7 L8 13" stroke={A.ink} strokeWidth="1.8" fill="none" strokeLinecap="round" /></svg>
          </div>
          <ACircleRule label={kicker} />
        </div>
        <div style={{ fontFamily: A.serif, fontSize: 40, lineHeight: 1, letterSpacing: -0.8 }}>
          {title}
        </div>
        {extra && (
          <div style={{ fontFamily: A.sans, fontSize: 13, color: A.ink2, marginTop: 8 }}>
            {extra}
          </div>
        )}
      </div>
    </>
  );
}

// Scrapbook primitives --------------------------------------------------------
function ATape({ x = '50%', y = -8, rotate = -4, width = 60, color = 'rgba(204,85,0,0.22)' }) {
  return (
    <div style={{
      position: 'absolute', left: x, top: y, transform: `translateX(-50%) rotate(${rotate}deg)`,
      width, height: 18, background: color, boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
    }} />
  );
}

function APolaroid({ hue, video, len, rotate = 0, w = 150, h = 170, label = 'photo' }) {
  return (
    <div style={{
      width: w, padding: '10px 10px 28px', background: A.paper,
      boxShadow: '0 8px 18px rgba(50,30,10,0.14), 0 0 0 1px rgba(27,22,18,0.05)',
      transform: `rotate(${rotate}deg)`, position: 'relative', flexShrink: 0,
    }}>
      <ScoutPhoto hue={hue} label={video ? 'video' : label} style={{ width: '100%', height: h }} radius={2} />
      {video && (
        <div style={{
          position: 'absolute', top: 18, left: 18, padding: '3px 7px',
          background: 'rgba(15,10,5,0.65)', color: A.paper, borderRadius: 4,
          fontFamily: 'ui-monospace, "SF Mono", monospace', fontSize: 9.5, letterSpacing: 0.5,
          display: 'flex', alignItems: 'center', gap: 4,
        }}>
          <svg width="6" height="6" viewBox="0 0 6 6"><path d="M1 0.5 L5 3 L1 5.5 Z" fill={A.paper}/></svg>
          {len}
        </div>
      )}
    </div>
  );
}

// =============================================================================
// Restaurant Journal — Scrapbook
// =============================================================================
function AJournalLocation() {
  const r = SCOUT_RESTAURANTS[0]; // Kismet
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, paddingBottom: 110 }}>
        <AJournalSubhead
          title={r.name}
          kicker="Journal"
          extra={<>
            <span style={{ fontFamily: A.serif, color: A.ink, fontSize: 15 }}>3</span> visits ·
            <span style={{ fontFamily: A.serif, color: A.ink, fontSize: 15 }}> 8</span> photos ·
            <span style={{ fontFamily: A.serif, color: A.ink, fontSize: 15 }}> 2</span> videos
          </>}
        />

        <div style={{ padding: '36px 0 0' }}>
          {A_JOURNAL_ENTRIES.map((e, i) => (
            <div key={e.date} style={{
              position: 'relative', padding: '32px 20px 28px',
              borderTop: i === 0 ? 'none' : `1px dashed ${A.rule}`,
            }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginBottom: 14 }}>
                <div style={{ fontFamily: A.serif, fontSize: 28, color: A.burnt, letterSpacing: -0.5 }}>{e.day}</div>
                <div style={{ fontFamily: A.sans, fontSize: 10.5, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.8 }}>
                  {e.mo} · {e.year}
                </div>
                <div style={{ flex: 1, height: 1, background: A.rule }} />
                <div style={{ fontFamily: A.serif, fontStyle: 'italic', fontSize: 14, color: A.ink2 }}>{e.tag}</div>
              </div>

              <div style={{
                display: 'flex', gap: 6, marginLeft: -6, marginRight: -6,
                overflow: 'visible', justifyContent: 'flex-start',
                paddingTop: 14, paddingBottom: 14,
              }}>
                {e.media.map((m, idx) => (
                  <div key={idx} style={{ position: 'relative', paddingTop: 8 }}>
                    {idx === 0 && <ATape x="50%" y={-2} rotate={-6} width={56} />}
                    {idx === 1 && <ATape x="60%" y={-4} rotate={4}  width={48} color="rgba(27,22,18,0.18)" />}
                    {idx === 2 && <ATape x="40%" y={-2} rotate={-2} width={50} />}
                    <APolaroid
                      hue={m.hue}
                      video={m.t === 'video'} len={m.len}
                      rotate={[-3, 1.5, -1][idx] || 0}
                      w={e.media.length === 3 ? 108 : 138}
                      h={e.media.length === 3 ? 124 : 150}
                    />
                  </div>
                ))}
              </div>

              <div style={{
                marginTop: 14, fontFamily: A.serif, fontStyle: 'italic',
                fontSize: 15.5, lineHeight: 1.4, color: A.ink, padding: '0 4px',
              }}>
                "{e.note}"
              </div>
            </div>
          ))}

          <div style={{
            margin: '8px 24px 0', padding: '16px 18px', border: `1px dashed ${A.rule}`, borderRadius: 16,
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{ width: 32, height: 32, borderRadius: 99, background: A.burnt, color: A.paper, display: 'grid', placeItems: 'center', fontFamily: A.serif, fontSize: 18, lineHeight: 1 }}>+</div>
            <div>
              <div style={{ fontFamily: A.serif, fontSize: 16 }}>New entry</div>
              <div style={{ fontFamily: A.sans, fontSize: 11.5, color: A.ink3 }}>Drop photos, videos & a note</div>
            </div>
          </div>
        </div>
      </div>
      <ATabBar active="journal" />
    </IOSDevice>
  );
}

// =============================================================================
// Journal tab — Editorial table of contents
// =============================================================================
function AJournalIndex() {
  const c = A_ACTIVE_CIRCLE;
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, paddingBottom: 110 }}>
        <div style={{ paddingTop: 46 }}>
          <ACircleHeader />
        </div>
        <div style={{ padding: '14px 24px 8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
            <ACircleRule label={`${c.short.toUpperCase()} · VOLUME 1`} />
            <div style={{ fontFamily: A.serif, fontSize: 13, color: A.ink2 }}>2024</div>
          </div>
          <div style={{ fontFamily: A.serif, fontSize: 56, lineHeight: 0.92, letterSpacing: -1.4 }}>
            Where <em style={{ color: A.burnt, fontStyle: 'italic' }}>we've</em><br/>been
          </div>
          <div style={{ display: 'flex', gap: 22, marginTop: 18 }}>
            <AStat value="06" label="Places" />
            <AStat value="47" label="Photos" />
            <AStat value="09" label="Videos" />
            <AStat value="17" label="Visits" />
          </div>
        </div>

        <div style={{ padding: '28px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 12 }}>
            <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6 }}>
              The Index
            </div>
            <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.2 }}>
              Most recent ↓
            </div>
          </div>

          {A_JOURNAL_LOCATIONS.map((loc, i) => (
            <div key={loc.id} style={{
              display: 'flex', alignItems: 'center', gap: 14, padding: '14px 0',
              borderTop: i === 0 ? `1px solid ${A.rule}` : 'none',
              borderBottom: `1px solid ${A.rule}`,
            }}>
              <div style={{ width: 32, fontFamily: A.serif, fontSize: 22, color: A.burnt, lineHeight: 1 }}>
                {String(i + 1).padStart(2, '0')}
              </div>
              <ScoutPhoto hue={loc.hue} label="" style={{ width: 56, height: 56, flexShrink: 0 }} radius={2} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontFamily: A.serif, fontSize: 18, lineHeight: 1.05, letterSpacing: -0.2 }}>{loc.name}</div>
                <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, marginTop: 4, letterSpacing: 0.4 }}>
                  {loc.cuisine.toUpperCase()} · {loc.visits} VISITS
                </div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: A.serif, fontSize: 14, color: A.ink, lineHeight: 1 }}>{loc.last}</div>
                <div style={{ fontFamily: A.sans, fontSize: 10, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.2, marginTop: 4 }}>
                  Last entry
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
      <ATabBar active="journal" />
    </IOSDevice>
  );
}

// =============================================================================
// Journal tab — empty state (first time / no entries yet)
// =============================================================================
function AJournalIndexEmpty() {
  const c = SCOUT_CIRCLES[1]; // Family — fresh circle, hasn't journaled yet
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, paddingBottom: 110, position: 'relative' }}>
        <div style={{ paddingTop: 46 }}>
          <ACircleHeader circle={c} />
        </div>
        <div style={{ padding: '14px 24px 8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 18 }}>
            <ACircleRule circle={c} label={`${c.short.toUpperCase()} · VOLUME 1`} />
            <div style={{ fontFamily: A.serif, fontSize: 13, color: A.ink2 }}>2024</div>
          </div>
          <div style={{ fontFamily: A.serif, fontSize: 56, lineHeight: 0.92, letterSpacing: -1.4 }}>
            Where <em style={{ color: A.burnt, fontStyle: 'italic' }}>we've</em><br/>been
          </div>
        </div>

        {/* Empty illustration — three blank polaroids waiting */}
        <div style={{ marginTop: 60, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 4, position: 'relative', height: 200 }}>
          <div style={{ position: 'relative', paddingTop: 8 }}>
            <ATape x="50%" y={-2} rotate={-6} width={56} />
            <div style={{
              width: 116, padding: '10px 10px 28px', background: A.paper,
              boxShadow: '0 8px 18px rgba(50,30,10,0.12), 0 0 0 1px rgba(27,22,18,0.05)',
              transform: 'rotate(-5deg)',
            }}>
              <div style={{ width: '100%', height: 132, background: A.paper2 }} />
            </div>
          </div>
          <div style={{ position: 'relative', paddingTop: 8 }}>
            <ATape x="60%" y={-4} rotate={4} width={48} color="rgba(27,22,18,0.18)" />
            <div style={{
              width: 116, padding: '10px 10px 28px', background: A.paper,
              boxShadow: '0 8px 18px rgba(50,30,10,0.12), 0 0 0 1px rgba(27,22,18,0.05)',
              transform: 'rotate(2deg)',
            }}>
              <div style={{ width: '100%', height: 132, background: A.paper2 }} />
            </div>
          </div>
          <div style={{ position: 'relative', paddingTop: 8 }}>
            <ATape x="40%" y={-2} rotate={-2} width={50} />
            <div style={{
              width: 116, padding: '10px 10px 28px', background: A.paper,
              boxShadow: '0 8px 18px rgba(50,30,10,0.12), 0 0 0 1px rgba(27,22,18,0.05)',
              transform: 'rotate(-1deg)',
            }}>
              <div style={{ width: '100%', height: 132, background: A.paper2 }} />
            </div>
          </div>
        </div>

        <div style={{ padding: '40px 36px 0', textAlign: 'center' }}>
          <div style={{ fontFamily: A.serif, fontStyle: 'italic', fontSize: 24, lineHeight: 1.15, letterSpacing: -0.3 }}>
            Your <span style={{ color: A.burnt }}>atlas</span> starts here.
          </div>
          <div style={{ fontFamily: A.sans, fontSize: 13.5, color: A.ink2, marginTop: 12, lineHeight: 1.5 }}>
            Mark a place visited and we'll open its journal automatically. Add photos, a video, a note — anything to remember the night by.
          </div>

          <div style={{ marginTop: 24, display: 'inline-flex', alignItems: 'center', gap: 10, padding: '14px 22px', background: A.ink, color: A.paper, borderRadius: 26, fontFamily: A.sans, fontSize: 13.5, fontWeight: 600, letterSpacing: 0.3 }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M5 2 L9 2 L9 5 L12 5 L12 9 L9 9 L9 12 L5 12 L5 9 L2 9 L2 5 L5 5 Z" fill={A.paper}/></svg>
            Browse your wishlist
          </div>
        </div>
      </div>
      <ATabBar active="journal" />
    </IOSDevice>
  );
}

// =============================================================================
// Per-location empty state (you've visited but no entries yet)
// =============================================================================
function AJournalLocationEmpty() {
  const r = SCOUT_RESTAURANTS[0];
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, paddingBottom: 110 }}>
        <AJournalSubhead
          title={r.name}
          kicker="Journal"
          extra={<>Marked visited · {r.cuisine} · {r.dist} mi</>}
        />

        {/* Single blank polaroid w/ + prompt */}
        <div style={{ marginTop: 64, display: 'flex', justifyContent: 'center', position: 'relative' }}>
          <div style={{ position: 'relative', paddingTop: 8 }}>
            <ATape x="50%" y={-2} rotate={-5} width={70} />
            <div style={{
              width: 220, padding: '14px 14px 36px', background: A.paper,
              boxShadow: '0 12px 26px rgba(50,30,10,0.18), 0 0 0 1px rgba(27,22,18,0.05)',
              transform: 'rotate(-2deg)',
            }}>
              <div style={{
                width: '100%', height: 240, background: A.paper2,
                border: `1px dashed ${A.rule}`,
                display: 'grid', placeItems: 'center', color: A.ink3,
              }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ width: 44, height: 44, borderRadius: 99, background: A.burnt, color: A.paper, display: 'grid', placeItems: 'center', margin: '0 auto', fontFamily: A.serif, fontSize: 24, lineHeight: 1 }}>+</div>
                  <div style={{ marginTop: 12, fontFamily: 'ui-monospace, "SF Mono", monospace', fontSize: 10.5, letterSpacing: 0.8 }}>add first photo</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div style={{ padding: '52px 32px 0', textAlign: 'center' }}>
          <div style={{ fontFamily: A.serif, fontStyle: 'italic', fontSize: 22, lineHeight: 1.2, letterSpacing: -0.3 }}>
            Your first night at <span style={{ color: A.burnt }}>Kismet</span>.
          </div>
          <div style={{ fontFamily: A.sans, fontSize: 13, color: A.ink2, marginTop: 12, lineHeight: 1.5 }}>
            Drop in a few photos, a quick video, and how the meal was. We'll keep the rest tidy.
          </div>
        </div>

        <div style={{ padding: '28px 24px 0', display: 'flex', gap: 10 }}>
          <div style={{ flex: 1, height: 52, borderRadius: 26, background: A.ink, color: A.paper, fontFamily: A.sans, fontSize: 14.5, fontWeight: 600, display: 'grid', placeItems: 'center', letterSpacing: 0.3 }}>
            Add your first entry
          </div>
          <div style={{ width: 52, height: 52, borderRadius: 26, background: A.paper, border: `1px solid ${A.rule}`, display: 'grid', placeItems: 'center' }}>
            <svg width="18" height="18" viewBox="0 0 18 18"><circle cx="9" cy="9" r="5.5" stroke={A.ink} strokeWidth="1.6" fill="none"/><path d="M9 6 V12 M6 9 H12" stroke={A.ink} strokeWidth="1.6" strokeLinecap="round"/></svg>
          </div>
        </div>
      </div>
      <ATabBar active="journal" />
    </IOSDevice>
  );
}

// =============================================================================
// New-entry composer
// =============================================================================
function AJournalCompose() {
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: A.paper, minHeight: '100%', fontFamily: A.sans, color: A.ink, paddingBottom: 32 }}>
        {/* Header: cancel / title / save */}
        <div style={{ padding: '58px 18px 14px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: A.sans, fontSize: 14, color: A.ink2 }}>Cancel</div>
          <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.6 }}>New Entry</div>
          <div style={{ fontFamily: A.sans, fontSize: 14, color: A.burnt, fontWeight: 600 }}>Save</div>
        </div>

        {/* Location card */}
        <div style={{
          margin: '4px 20px 0', padding: '14px 16px', background: A.paper2, borderRadius: 18,
          display: 'flex', alignItems: 'center', gap: 12,
        }}>
          <ScoutPhoto hue={28} label="" style={{ width: 48, height: 48 }} radius={10} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontFamily: A.serif, fontSize: 18, lineHeight: 1.05 }}>Kismet</div>
            <div style={{ fontFamily: A.sans, fontSize: 11.5, color: A.ink3, marginTop: 3, letterSpacing: 0.3 }}>
              Mediterranean · Mission District
            </div>
          </div>
          <div style={{ fontFamily: A.sans, fontSize: 12, color: A.ink2 }}>Change</div>
        </div>

        {/* Date + tag row */}
        <div style={{ margin: '18px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <div style={{ padding: '12px 14px', border: `1px solid ${A.rule}`, borderRadius: 14 }}>
            <div style={{ fontFamily: A.sans, fontSize: 10, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.4 }}>Date</div>
            <div style={{ fontFamily: A.serif, fontSize: 17, marginTop: 4 }}>
              <span style={{ color: A.burnt }}>14</span> Oct 2024
            </div>
          </div>
          <div style={{ padding: '12px 14px', border: `1px solid ${A.rule}`, borderRadius: 14 }}>
            <div style={{ fontFamily: A.sans, fontSize: 10, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.4 }}>Occasion</div>
            <div style={{ fontFamily: A.serif, fontStyle: 'italic', fontSize: 16, marginTop: 4 }}>
              Birthday dinner
            </div>
          </div>
        </div>

        {/* Media — added so far + add tile */}
        <div style={{ margin: '20px 20px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
            <div style={{ fontFamily: A.serif, fontSize: 18, letterSpacing: -0.2 }}>Photos & video</div>
            <div style={{ fontFamily: A.sans, fontSize: 11, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.2 }}>3 added</div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: 6 }}>
            {[
              { hue: 14, t: 'photo' },
              { hue: 28, t: 'video', len: '0:15' },
              { hue: 36, t: 'photo' },
            ].map((m, i) => (
              <div key={i} style={{ position: 'relative' }}>
                <ScoutPhoto hue={m.hue} label={m.t === 'video' ? 'video' : 'photo'} style={{ height: 80 }} radius={8} />
                {m.t === 'video' && (
                  <div style={{
                    position: 'absolute', bottom: 5, left: 5, padding: '2px 5px', borderRadius: 3,
                    background: 'rgba(15,10,5,0.65)', color: A.paper,
                    fontFamily: 'ui-monospace, monospace', fontSize: 9, letterSpacing: 0.3,
                  }}>{m.len}</div>
                )}
                <div style={{
                  position: 'absolute', top: 4, right: 4, width: 18, height: 18, borderRadius: 99,
                  background: 'rgba(15,10,5,0.55)', color: A.paper, display: 'grid', placeItems: 'center', fontSize: 11,
                }}>×</div>
              </div>
            ))}
            {/* Add tile */}
            <div style={{
              height: 80, borderRadius: 8, border: `1px dashed ${A.rule}`,
              display: 'grid', placeItems: 'center', color: A.ink3,
            }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontFamily: A.serif, fontSize: 22, lineHeight: 1, color: A.burnt }}>+</div>
                <div style={{ fontFamily: 'ui-monospace, monospace', fontSize: 8.5, letterSpacing: 0.6, marginTop: 2 }}>add</div>
              </div>
            </div>
          </div>
        </div>

        {/* Note field */}
        <div style={{ margin: '24px 20px 0' }}>
          <div style={{ fontFamily: A.serif, fontSize: 18, letterSpacing: -0.2, marginBottom: 10 }}>How was it?</div>
          <div style={{
            padding: 16, background: A.paper2, borderRadius: 14, minHeight: 140,
            fontFamily: A.serif, fontStyle: 'italic', fontSize: 15.5, lineHeight: 1.45, color: A.ink,
            position: 'relative',
          }}>
            "Lamb ribs lived up to the hype. Patio heater right above us — perfect October night.<span style={{ display: 'inline-block', width: 1.5, height: 18, background: A.burnt, marginLeft: 2, verticalAlign: 'text-bottom' }} />"
          </div>
        </div>

        {/* Quick mood chips */}
        <div style={{ margin: '18px 20px 0' }}>
          <div style={{ fontFamily: A.sans, fontSize: 10.5, color: A.ink3, textTransform: 'uppercase', letterSpacing: 1.4, marginBottom: 8 }}>
            Tag the vibe
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            <AChip active>Date night</AChip>
            <AChip>Group</AChip>
            <AChip>Solo</AChip>
            <AChip>Brunch</AChip>
            <AChip active>Patio</AChip>
            <AChip>Bar seat</AChip>
            <AChip>Loud</AChip>
            <AChip>Quiet</AChip>
          </div>
        </div>
      </div>
    </IOSDevice>
  );
}

// =============================================================================
// Fullscreen photo / video viewer
// =============================================================================
function AJournalViewer() {
  return (
    <IOSDevice width={402} height={874}>
      <div style={{ background: '#0E0905', minHeight: '100%', color: A.paper, fontFamily: A.sans, position: 'relative' }}>
        {/* Top bar */}
        <div style={{
          position: 'absolute', top: 56, left: 16, right: 16, zIndex: 10,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <div style={{ width: 38, height: 38, borderRadius: 99, background: 'rgba(255,240,220,0.12)', backdropFilter: 'blur(8px)', display: 'grid', placeItems: 'center' }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><path d="M3 3 L11 11 M11 3 L3 11" stroke={A.paper} strokeWidth="1.6" strokeLinecap="round"/></svg>
          </div>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontFamily: A.serif, fontSize: 16 }}>Kismet</div>
            <div style={{ fontFamily: A.sans, fontSize: 11, opacity: 0.6, marginTop: 2, letterSpacing: 0.4 }}>Oct 14 · 2 of 3</div>
          </div>
          <div style={{ width: 38, height: 38, borderRadius: 99, background: 'rgba(255,240,220,0.12)', backdropFilter: 'blur(8px)', display: 'grid', placeItems: 'center' }}>
            <svg width="14" height="14" viewBox="0 0 14 14"><circle cx="3" cy="7" r="1.2" fill={A.paper}/><circle cx="7" cy="7" r="1.2" fill={A.paper}/><circle cx="11" cy="7" r="1.2" fill={A.paper}/></svg>
          </div>
        </div>

        {/* Hero media */}
        <div style={{ paddingTop: 130 }}>
          <ScoutPhoto hue={28} label="video · 0:15" dark style={{ height: 480, width: '100%' }} radius={0} />
          {/* Play badge */}
          <div style={{
            position: 'absolute', top: 130 + 220, left: '50%', transform: 'translateX(-50%)',
            width: 64, height: 64, borderRadius: 99, background: 'rgba(255,240,220,0.18)',
            backdropFilter: 'blur(10px)', display: 'grid', placeItems: 'center',
            border: `1px solid rgba(255,240,220,0.3)`,
          }}>
            <svg width="22" height="22" viewBox="0 0 22 22"><path d="M6 4 L18 11 L6 18 Z" fill={A.paper}/></svg>
          </div>
          {/* Length tag */}
          <div style={{
            position: 'absolute', top: 130 + 16, right: 28, padding: '4px 9px', borderRadius: 99,
            background: 'rgba(15,10,5,0.6)', fontFamily: 'ui-monospace, monospace', fontSize: 11, letterSpacing: 0.4,
          }}>0:15</div>
        </div>

        {/* Page indicators */}
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 20 }}>
          {[0, 1, 2].map(i => (
            <div key={i} style={{
              width: i === 1 ? 22 : 6, height: 6, borderRadius: 99,
              background: i === 1 ? A.burnt : 'rgba(255,240,220,0.25)',
              transition: 'width .2s',
            }} />
          ))}
        </div>

        {/* Caption / note tied to entry */}
        <div style={{ padding: '28px 24px 0' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
            <div style={{ fontFamily: A.serif, fontSize: 28, color: A.burnt, lineHeight: 1, letterSpacing: -0.4 }}>14</div>
            <div style={{ fontFamily: A.sans, fontSize: 10.5, color: 'rgba(255,240,220,0.55)', textTransform: 'uppercase', letterSpacing: 1.6 }}>
              Oct · 2024
            </div>
            <div style={{ flex: 1, height: 1, background: 'rgba(255,240,220,0.12)' }} />
            <div style={{ fontFamily: A.serif, fontStyle: 'italic', fontSize: 13, color: 'rgba(255,240,220,0.7)' }}>
              Birthday dinner
            </div>
          </div>
          <div style={{ marginTop: 14, fontFamily: A.serif, fontStyle: 'italic', fontSize: 16, lineHeight: 1.4, color: 'rgba(255,240,220,0.92)' }}>
            "Lamb ribs lived up to the hype. Patio heater right above us — perfect October night."
          </div>
        </div>

        {/* Bottom thumb strip */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 24,
          padding: '14px 24px', display: 'flex', gap: 8, alignItems: 'center',
        }}>
          {[14, 28, 36].map((h, i) => (
            <div key={i} style={{
              flex: 1, height: 58, borderRadius: 6, overflow: 'hidden', position: 'relative',
              border: i === 1 ? `2px solid ${A.burnt}` : `1px solid rgba(255,240,220,0.18)`,
              opacity: i === 1 ? 1 : 0.7,
            }}>
              <ScoutPhoto hue={h} label="" dark style={{ height: '100%', width: '100%' }} radius={0} />
              {i === 1 && (
                <div style={{
                  position: 'absolute', inset: 0, display: 'grid', placeItems: 'center',
                  background: 'rgba(15,10,5,0.25)',
                }}>
                  <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2 1 L8 5 L2 9 Z" fill={A.paper}/></svg>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </IOSDevice>
  );
}

Object.assign(window, {
  AJournalLocation, AJournalIndex,
  AJournalIndexEmpty, AJournalLocationEmpty,
  AJournalCompose, AJournalViewer,
});
