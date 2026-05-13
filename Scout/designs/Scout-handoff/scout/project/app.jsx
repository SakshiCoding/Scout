// Scout · Atlas — focused canvas
// Scrapbook (per-location) + Editorial TOC (Journal tab),
// plus support screens, plus the new multi-circle layer.

function ScoutCanvas() {
  return (
    <DesignCanvas>

      <DCSection
        id="atlas-circles"
        title="Circles · the new top layer"
        subtitle="Scout now scopes everything — wishlist, map, picks, journal — to a CIRCLE. You can have one with your partner, one with family, one with roommates. The Atlas palette stays the brand everywhere; each circle just gets a small accent color used on the switcher pill, the first avatar, and a thin rule under the masthead."
      >
        <DCArtboard id="a-circle-picker"   label="Circle picker (tap the pill)"     width={402} height={874}><ACirclePicker /></DCArtboard>
        <DCArtboard id="a-wishlist-c"      label="Wishlist · Morgan & me (burnt)"   width={402} height={874}><AWishlist /></DCArtboard>
        <DCArtboard id="a-journal-idx-c"   label="Journal · Morgan & me (burnt)"    width={402} height={874}><AJournalIndex /></DCArtboard>
        <DCArtboard id="a-journal-fam"     label="Journal · Family (sage)"          width={402} height={874}><AJournalIndexEmpty /></DCArtboard>
        <DCPostIt rotate={-3} width={200}>
          <b>Accent colors</b><br/>
          · Morgan & me — <span style={{ color: '#CC5500' }}>burnt</span><br/>
          · Family — <span style={{ color: '#7A8B3C' }}>sage</span><br/>
          · Roommates — <span style={{ color: '#3D5A80' }}>slate</span><br/><br/>
          <b>Where it shows up:</b> the switcher pill, the first member avatar, and a 2px rule under the masthead. The rest of the UI stays Atlas burnt-orange so the brand reads consistently.<br/><br/>
          New circles let you pick any of ~8 accents.
        </DCPostIt>
      </DCSection>

      <DCSection
        id="atlas-core"
        title="Atlas · Core screens"
        subtitle="Wishlist / Detail / Pick / Map — every screen now carries the circle pill at the top, swappable in one tap."
      >
        <DCArtboard id="a-wishlist" label="Wishlist"        width={402} height={874}><AWishlist /></DCArtboard>
        <DCArtboard id="a-detail"   label="Restaurant card" width={402} height={874}><ADetail /></DCArtboard>
        <DCArtboard id="a-pick"     label="Pick for us"     width={402} height={874}><APickForUs /></DCArtboard>
        <DCArtboard id="a-map"      label="Map"             width={402} height={874}><AMap /></DCArtboard>
      </DCSection>

      <DCSection
        id="atlas-journal-picks"
        title="Journal · the two picks"
        subtitle="Scrapbook for the per-location page; Editorial table of contents for the Journal tab. Both scoped to the current circle."
      >
        <DCArtboard id="a-j-loc" label="Restaurant journal · Scrapbook"  width={402} height={874}><AJournalLocation /></DCArtboard>
        <DCArtboard id="a-j-idx" label="Journal tab · Editorial TOC"     width={402} height={874}><AJournalIndex /></DCArtboard>
      </DCSection>

      <DCSection
        id="atlas-journal-flows"
        title="Journal · flows"
        subtitle="The full lifecycle: marking a place visited auto-prompts a new entry → which lands in the location's scrapbook → which you can then cross-post to another circle (e.g. sharing the family dinner photo into your partner's journal too)."
      >
        <DCArtboard id="a-j-mark"    label="Marked visited \u2192 auto-prompt"     width={402} height={874}><AMarkedVisitedSheet /></DCArtboard>
        <DCArtboard id="a-j-compose" label="Full composer"                  width={402} height={874}><AJournalCompose /></DCArtboard>
        <DCArtboard id="a-j-viewer"  label="Fullscreen viewer"              width={402} height={874}><AJournalViewer /></DCArtboard>
        <DCArtboard id="a-j-cross"   label="Share \u2192 another circle"           width={402} height={874}><ACrossPostSheet /></DCArtboard>
        <DCPostIt rotate={2} width={190}>
          <b>Auto-prompt</b> appears immediately after tapping Mark visited. Tap save and it lands in that circle's journal; tap skip and it's silently logged (you can add media later).<br/><br/>
          <b>Cross-post</b> lets you push a single photo or video into another circle's journal — useful when, say, a family dinner happens to be at a place your roommates also love.
        </DCPostIt>
      </DCSection>

      <DCSection
        id="atlas-journal-empty"
        title="Journal · empty states"
        subtitle="What new circles and new places look like before they have content."
      >
        <DCArtboard id="a-j-empty-idx" label="New circle \u2014 no entries"   width={402} height={874}><AJournalIndexEmpty /></DCArtboard>
        <DCArtboard id="a-j-empty-loc" label="New place \u2014 first entry"   width={402} height={874}><AJournalLocationEmpty /></DCArtboard>
      </DCSection>

    </DesignCanvas>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<ScoutCanvas />);
