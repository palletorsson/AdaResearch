# Force_Preview — Curation Notes

**Sequence:** forces · **Pieces:** 28 · **Counts:** small 4 / medium 0 / large 2 / applied 4
**Focal centerpiece:** `weather_vector_field` (Storm Chamber).

## The argument
The map's own truth is the spine: *"One shelf, the whole subject. This room is a table of
contents."* The tutorial names the journey order explicitly — Foundations names the arrows →
Operations teaches dot/cross → Motion sets them moving → Forces/fields → the arena where it all
collides. So the wall **is that curriculum, read left→right**, broken into four tier-bays whose
`station_panel` headers carry the map's own truth-beats. Curation is an argument made with
placement: the small precious primitives are raised high and narrow up front; the big station
"worlds" are set low and broad behind; the storm is thrust forward into the room as the one focal
claim that a field *is* a vector at every point — the idea that subsumes projectile and reflection.

## Reading order (left → right on +X)
1. **NAME THE ARROWS — Foundations (small).** Four bench primitives, each a single grabbable
   operation: `adder_board` (sum), `length_lantern` (magnitude), `stretch_bench` (scalar ·k),
   `agreement_gauge` (dot). Slim **1×1 high-narrow plinths** (top_height 1.15–1.30, cap_inset 0.30)
   per the plinth's own rule — *size IS the argument; what you raise high and narrow you call
   precious.* Depth is **checkerboarded** (z 1.4 / 0.7 / 1.4 / 0.7) so the four read as a clustered
   field, not a flat line. Closed by a corner `station_pillar`.
2. **FORCES YOU FEEL — applied, body-scale.** `force_pad` (a 1×1 launch disc) on a slim plinth;
   `force_vortex` (4×3×4) on a **low broad 4×4 `station_stage`** set back (z 0.5) — a field you
   stand inside.
3. **THREE ROOMS, ONE SHELF — the headline trio (large/applied), the focal zone.**
   `weather_vector_field` is the **centerpiece**: 6×6 footprint capped to a 4×4 stage, low + broad,
   **thrust forward into the room (z 2.4)** with its own depth so the free-cam orbit rewards it.
   Behind it, an **alcove**: `mortar_vector_siege` (3×3 stage) back-left at z 0.4, `reflection_hall`
   (5×5 capped 4×4) back-right at z 0.5. Two flanking pillars frame the alcove. This is the one clear
   focal point; the storm is the thing set forward.
4. **LAUNCHED — the payoff (applied).** `human_catapult` (2×4×2) on a tall 2×2 plinth at z 1.6 — the
   body-scale finale the tutorial's "Try: fire the human catapult" points at. Panel: "YOU ARE THE
   SHELL / NOW WALK THE ARC."

## Why each prop (chosen for meaning, not just size)
- **station_plinth (1×1 slim)** for every held bench instrument + force_pad: the plinth's truth is
  *"a claim that one thing is worth isolating, cut to the thing's own measure."* High-narrow = precious
  primitive. Each carries `caption_text` = the artifact's **display name**, rendered as the framed,
  surface-pinned 2D-in-3D plate — these are the only labels (the editor hides the floating Label3D).
- **station_plinth (2×2)** for human_catapult: a long/heavy thing laid across a broad-but-still-raised
  podium, lower top_height (0.85) so the timber frame reads grounded.
- **station_stage (4×4 / 3×3, low)** for the three big stations + the vortex: the stage's truth is
  *"to stage a thing is to raise it a little and admit you are presenting it"* — the broad low deck for
  a world you walk into, never a tall pedestal. weather (6×6) and reflection (5×5) are **capped to 4×4**
  per the brief's >9-cell rule; mortar (3×3) sits at its true footprint.
- **station_wall** — one continuous 30-cell backing run (capped both ends), height 3: the built
  *behind* that turns an open floor into bays (*"a place was built to a measure"*).
- **station_pillar ×3** mark where the room turns — close the foundations bay and frame the headline
  alcove, so the exhibit reads as architecture, not furniture in a void.
- **station_panel ×4** carry the truth-beat headers (2D-in-3D, never billboard) — the station
  *admitting it has something to say, in plain pinned words.* They double as the tier-group labels and
  as the journey signposting the map's `intent.md` Gap explicitly asks for ("a single entry sign naming
  the three stations").

## 3D composition (rewards orbiting; still reads left→right from the iso front)
- **Depth** spans z 0.06 (wall) → 2.4 (storm forward). Foreground: bench cluster + catapult + storm.
  Background: vortex, mortar, reflection in alcoves against the backing wall.
- **Height** ladder: tall slim foundation plinths (~1.15–1.30) up front; low broad station decks
  (~0.18) behind; pillars + wall (h 3) as the vertical frame.
- **One focal point:** the storm, set forward and centered under the widest panel.
- Deliberate negative space between bays (x gaps at 10–12, 16–17, 28.5–31) keeps aisles walkable.

## Prop gaps flagged
- **`force_pad` (sub-1 m disc) — micro-pedestal gap.** It is a 1×1 m floor launch pad; even a slim
  1×1 plinth's foot reads slightly oversized under it. Used the slim 1×1 as instructed, but a future
  **micro-pedestal** prop (≤0.6 m footprint, ~0.4 m tall — a true coaster/puck base) would seat it
  honestly. Same future prop would help the other genuinely flat 1×1 toys across the project.
- **XL laser benches omitted on purpose.** `vector_addition_xl_laser` / `vector_subtraction_xl_laser`
  are **room_scale** (8×4×8) walk-in exhibits that `delegate_to` VectorAddition/VectorSubtraction and
  have **no own `scene`** in the registry. The brief requires every piece token to be registry-known
  *with a scene*, and an 8×8 room cannot sit on a wall bay without wrecking the composition. They are
  better experienced as their own rooms (the map already places them at z 4) — so they are left out of
  the curated wall rather than faked onto a plinth. No prop gap; a scope decision.

## What to try next
- If a **micro-pedestal** prop lands, swap force_pad onto it and drop its plinth top_height.
- Capture the wall (`capture_multi_angle.gd --mode=map`) and confirm the storm reads as the single
  focal point from the front iso and that the alcove depth reads on orbit; nudge mortar/reflection z if
  the backing wall crowds them.
- Consider a 5th panel as a literal "journey map" strip (Foundations→Operations→Motion→Forces→Arena)
  to fully answer the intent.md Gap — held back here to avoid text-crowding the four tier headers.
