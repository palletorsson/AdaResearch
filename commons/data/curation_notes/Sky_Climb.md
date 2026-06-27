# Sky_Climb — Curation Notes

*Sequence: forces. The wall as a walkable argument for the map's lesson:*
**"A launch is a velocity you are given; gravity writes the rest."**

## The argument
Sky_Climb is a vertical shaft where chained `force_pad`s throw the climber up past hanging
Calder mobiles, then a `return_launcher` drops them back to loop. Its aesthetic wager (from
`intent.md`): the **most kinetic force** (launch) set among the **most patient** (balance). The
wall makes that wager legible — it is not a ladder (every staged artifact is *applied* tier), so
the composition argues by **pairing, depth, and height**, not by small→large progression.

Read left → right (+X, the reading axis), the wall says:

1. **The throw** — `force_pad`, the verb of the whole map, raised highest and set forward (the
   focal point).
2. **The throw home** — `return_launcher`, its kin in the *Projectile / launch* concept (the
   catapult that solves `v0 = (home − here)/t − ½g·t` to land you on spawn). Mid-depth.
3. **The balance law, drifting** — the two `calder_mobile` variants, low and broad and set
   **back**, framed by pillars: the still court the launches pass through.

So the eye crosses from a single bright launch verb, through its homeward twin, into a quiet
paired sculpture-court — kinetic foreground resolving into patient background. That *is* the
map's argument, composed in space.

## Reading order & focal point
- **Focal point:** `force_pad` — slimmest+tallest plinth (1.35 m), lit, pushed forward to z=0.55.
  It is the one thing you do in this map (step on it, get thrown), so it gets the highest, most
  isolated lift. Its plate reads "Force Pad"; the foot stencil reads "v0".
- **Reading path:** force_pad (x0, forward) → return_launcher (x3, mid) → the Calder pair
  (x7 + x10.5, deep back). Left-to-right reads cleanly from the iso front; depth rewards orbiting.

## Why each prop (chosen for MEANING, per the @identity files)
- **force_pad → slim 1×1 `station_plinth`, top_height 1.35, cap_inset 0.3.** Footprint is 1 cell
  (`measurements`/`size_group: small`). The plinth's own truth: *"what you raise high and narrow,
  you call precious."* The launch is the precious verb, so it rides a tall narrow podium at eye
  height. `caption_text: "Force Pad"`, `stencil_text: "v0"` (the given velocity).
- **return_launcher → 2×2 `station_plinth`, top_height 0.9.** Footprint 4 cells
  (`spatial_needs.footprint_cells: 4`) → a 2-cell-square base sized exactly to it, mid height so it
  sits *below* the force_pad — the homeward throw is the answer to the launch, not its equal.
  `caption_text: "Return Launcher"`, `stencil_text: "HOME"` (it always aims at the beginning).
- **calder_object_mobile & calder_mobile → low broad 3×3 `station_plinth`, top_height 0.4.**
  Footprint 9 cells each. The brief's footprint rule routes 5–9 to `station_stage`, **but** Req 2
  demands a 2D-in-3D caption plate per artifact and only `station_plinth` renders `caption_text`.
  A *low, broad* plinth is exactly the plinth's other mode — *"what you set low and broad, you call
  a world"* — so I used a 3×3 plinth at a near-floor 0.4 m cap. This satisfies **both** Req 1
  (big → low+broad, sized to the real footprint) **and** Req 2 (a caption plate). Plates read
  "Calder Mobile — project primitives" and "Calder Mobile — real weights", distinguishing the
  two variants the baseline left unlabelled. They sit as a **pair**, the balance law twice over
  (primitives vs. real aluminium discs), which is the map's still counterpoint to the throw.
- **station_pillar ×2 (height 3.2, z=2.75).** Set *behind* the Calder pair to turn the open back
  of the shaft into a framed bay — the pillar's truth: *"one upright, repeated, makes a room out
  of an open floor."* They give the background real depth and read the sculpture-court as
  architecture, not furniture in a void.
- **station_panel ×2 (wall, 2D-in-3D, z=0.06).** The map ships with an empty `description` and no
  subtitle beats (flagged as a gap in `blurb.md`), so the wall supplies the missing voice as
  surface-pinned headers:
  - Left, over the launchers: **"THE LAUNCH, VERTICAL"** / "v0 IS GIVEN · GRAVITY WRITES THE
    REST" / "the throw, and the throw home".
  - Right, over the Calders: **"THE BALANCE LAW, DRIFTING"** / "τ = w·d at every arm" / "the
    still counterpoint to the throw".
  Together they name the two forces in dialogue — exactly the map's unspoken thesis.

## Using the 3D space (Req 3)
Nothing is on one flat z. The depth staggers **0.55 → 1.5 → 2.4 → 2.75**:
- `force_pad` foreground (z 0.55, y 1.35) — set forward and high, the clear focal lift.
- `return_launcher` mid-ground (z 1.5, y 0.9).
- the Calder pair deep (z 2.4, near floor) with the two pillars deepest (z 2.75, 3.2 m tall)
  backing them — a genuine alcove/bay you discover by orbiting the free-cam.
Height also staggers (1.35 → 0.9 → 0.4 caps), so the silhouette descends left-to-right from the
kinetic verb to the patient floor. Wide walkable gaps (x 0 / 3 / 7 / 10.5) keep it traversable;
the empty middle band (x≈4–6, foreground) is deliberate negative space the climber rises through.

## Baseline beaten
The current `spine_walls.json` entry lines all six pieces up on a single `z=0.8`, stands the two
9-cell Calders on **1×1** stage/plinth feet (footprint-wrong), gives **no** plinth a
`caption_text` (no labels — Req 2 unmet), and ships a content-less `station_panel`. This curation
fits every base to its real footprint, labels every artifact with a plate, fills both panels with
the map's own truth-beats, and stages a real foreground/background composition.

## Prop gaps flagged
- **force_pad is a sub-1 m glowing floor plate.** Even a slim 1×1 plinth's foot is visually
  heavier than the pad itself, and conceptually a launch pad belongs *on the floor*, not lifted
  onto a podium. I used the slim 1×1 plinth as the brief instructs (for the caption plate + a
  measured patch of ground), **but flag it as a prop gap**: a future **micro-pedestal / floor
  inlay** (a flush 1×1 lit ground-tile that frames a pad-height artifact without raising it)
  would serve `force_pad` and the other ground-launch artifacts (`jump_pad`, `return_launcher`'s
  ring) far better than a podium.
- **No caption channel on `station_stage`.** The clean footprint rule (5–9 → stage) collides with
  the per-artifact-plate rule because only `station_plinth` exposes `caption_text`. A future
  `caption_text` field on `station_stage` would let big artifacts use the proper low deck *and*
  carry their plate, removing the workaround used here (low broad plinth standing in for a stage).

## What to try next
- Capture a multi-angle pass (`--mode=map --target=Sky_Climb`) to confirm the Calder pair reads
  as sculpture from the climbing arcs (a stated beauty-anchor risk in `blurb.md`) and that the
  back pillars frame rather than crowd.
- The mobiles are ceiling-mounted (`top_y`), so their *bodies* hang above the plinths; the broad
  low plinths mainly mark each one's ground patch + caption. If they read as floating free of
  their plinths in capture, consider tightening the plinth-to-mobile coupling or lowering `top_y`.
- Consider promoting the two panel beats into the map's real `subtitles`/`description` so the
  truth is spoken in-world too, not only on the curated wall.
