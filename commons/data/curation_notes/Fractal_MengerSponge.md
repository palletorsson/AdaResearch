# Curation Notes — Fractal_MengerSponge

**Sequence:** fractals · **Tier source:** `doc/fractal_concept_map.json` (concept "Menger sponge")
**Counts:** small 1 · medium 1 · large 2 · applied 2 (6 display artifacts)

## The argument

The map stages one idea and one counter-voice. The idea is the **Menger sponge**: *carve
the middle out of a cube, recurse, forever* — and you get D ≈ 2.727, **infinite surface
around zero volume, a solid made entirely of holes** (the artifact's own truth). The wall
makes that a walkable claim by showing the *same carving rule at four scales* — held toy →
bench → the body-scale walk-in → the working filter — so the player reads the recursion as
one unchanging rule, not four unrelated objects. The counter-voice, set back and low, is
**DLA**: the *other* road to a fractal — branching grown by pure chance instead of carved
by a rule — so the sponge's determinism is felt against something that isn't.

## Reading order (left → right, +X)

1. **Menger Toy** (small) — micropod, x=1, set back (z=0.6). The held sponge, eye-level on a
   sub-grid post. "Here is the thing, small enough to hold."
2. **Menger Bench** (medium) — 2×2 plinth, x=3.5, stepped forward (z=1.6). The iterations laid
   out: surface area climbing without bound.
3. **MENGER SPONGE** (large, **focal point**) — 4×4 stage, x=8, pushed furthest forward (z=2.4),
   alone in its bay under its own truth-panel. The 9 m walk-in: corridors through the
   cross-holes at human scale. Biggest base, most-forward depth, clear negative space on both
   sides — the eye and the feet both go here first.
4. **DLA** (large, counter-voice) — 3×3 stage, x=11, set far back (z=0.4) and low. Deliberately
   subordinate: a background sibling, "grown not carved."
5. **Menger Filter** (applied) — 2×2 plinth, x=13, mid-depth (z=1.2). All-surface put to work.
6. **Recursive Boolean Cube** (applied kin) — 2×2 plinth, x=15.5, set back (z=2.0). The boolean
   subtraction that *is* the carve — the operation behind the whole sequence, named at the end.

## Focal point

`menger_sponge` on the 4×4 stage at x=8, z=2.4. It wins on every channel the editor exposes:
largest footprint, lowest+broadest base (it's a walk-in, so it goes low and wide per the
brief), the most forward depth so it stands proud of the line when orbited, its own backing
wall + a dedicated truth-panel, and isolation (the two adjacent bays step back and away). The
4×4 stage caps the fp>9 walk-in per the brief; the 9 m sponge overhangs it intentionally — the
deck reads as "this is staged," not as a tight base.

## Why each prop (chosen for meaning, per the @identities)

- **station_micropod** (Menger Toy) — its identity is *the home for genuinely sub-1 m precious
  things*; the toy's leaf size is ~0.1 m, a true held object, so it gets the 0.6 m post that
  "doesn't over-claim the cell," not a full plinth.
- **station_plinth 2×2** (Bench, Filter, Boolean Cube) — fp-4 mid things; the plinth's own truth
  is *"size IS the argument."* Mid height (0.85–1.1) keeps them present but clearly below the
  centerpiece — the boolean cube sits lowest (0.85) and furthest back because it's a footnote,
  not a hero.
- **station_stage 4×4** (Sponge) and **3×3** (DLA) — the stage's truth is *"to stage a thing is
  to raise it a little and admit you are presenting it."* Both walk-ins go low+broad. The
  sponge's plate is on `name_plate` (not caption_text), per the stage's plate channel.
- **station_panel** (×4, wall) — carries the map's truth-beats as 2D-in-3D headers: "THE SAME
  HOLE, EVERY SCALE" / "INFINITE SURFACE, ZERO VOLUME" / "ALL SURFACE, PUT TO WORK" / "GROWN,
  NOT CARVED." These are the bay captions; the editor hides every artifact Label3D, so these +
  the plates are the only text.
- **station_wall** (×3) — backs the three Menger bays so the front elevation reads as composed
  alcoves, not a shelf.

## Labels (2D-in-3D plates — requirement 2, all present)

Every artifact has a surface-pinned plate set to its **display name**:
toy→micropod `caption_text` "Menger Toy (held sponge)"; bench→plinth `caption_text` "Menger
Bench (zero volume)"; filter→plinth "Menger Filter (all surface)"; boolean cube→plinth
"Recursive Boolean Cube (the carve)"; sponge→stage `name_plate` "MENGER SPONGE — walk inside
(D ≈ 2.727)"; DLA→stage `name_plate` "Diffusion-Limited Aggregation".

## On the kin pull (the map is thin)

The native map stages only `menger_sponge` + `diffusion_limited_aggregation` as displays
(`dark_sphere` is the void/sky backdrop — **kept off any base**). To build the ladder I pulled
three from the Menger concept tiers (`menger_toy`, `menger_bench`, `menger_filter`) and one
ontological neighbour, `recursive_boolean_cube` (similarity 0.885 to menger_sponge, and
literally the boolean-subtraction operation that carves the sponge). DLA is honoured as the
map's second native artifact but deliberately demoted to a back-corner counter-voice so it
never competes with the centerpiece.

## Prop gaps flagged

- **No vertical-circulation / lighting prop fit the bill** here, so none used — consistent with
  the known universal gaps (ladder/stair/handrail, luminaire). The sponge is a literal walk-in,
  so a ladder onto its stage was considered and rejected: the corridors are *through* it at
  floor level, not up.
- `station_luminaire` / `station_task_light` are referenced in `dna_props.json` but have **no
  scene in `station.json`** (confirmed missing) — could not light the focal bay with a station
  fixture even though the composition would benefit. Map lighting must carry it for now.
- The DLA neighbour data in `artifact_neighbors.json` is degenerate (≈0.997 to unrelated cave/
  WFC tokens) — unusable for kin selection; only the `menger_sponge` neighbour list was trusted.

## What to try next

- Once a `station_luminaire` scene lands, add one over the centerpiece stage to make the focal
  bay glow brighter than the flanks.
- Consider promoting `SierpinskiPyramid` (fp9 kin, "the same hole at every scale") into a second
  back-bay opposite DLA, turning the wall into *carve vs. grow vs. stack* — but only if a VR walk
  shows the current 0–16 m span doesn't already feel full; risk is drowning the sponge.
- VR-walk to confirm the 9 m sponge at z=2.4 doesn't clip the x=11 DLA stage when orbiting from
  behind; if it does, push DLA's x to ~10 or its z to 0.2.
