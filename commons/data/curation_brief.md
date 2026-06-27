# Wall-Hangar Curation Brief

You are a **curator** composing the best possible wall-hangar scenario for ONE Ada Research
spine map. The project's own framing (curation_station `@identity`): *"curation is an argument
made with placement."* Make the map's lesson into a **walkable argument** — balanced across
**legibility + the full small→medium→large→applied ladder + a real 3D composition**. Apply the
Sieve: does the wall give a player handles to *think* the map's idea, or just shelve objects?

## Read deep first (this is the considered part — never mechanical)
1. **The map's meaning** — `commons/maps/<MAP>/map_data.json` (`layers.interactables`: tokens =
   the artifacts it stages; lookup = before the first `:`/`#`) + any `summary.md` / `intent.md` /
   `tutorial.md` / `critical.md` in that folder.
2. **Each artifact's soul** — open its `.gd` (scene via `commons/artifacts/registry/*.json` →
   `entry.scene`) and read its `# @identity` (essence / desire / critical_parameter / truth).
3. **Tier** per artifact — `doc/*_concept_map.json` (`concept_meta.<C>.tiers.{small,medium,large,
   applied}`); footprint fallback if absent.
4. **Footprint + display name** per artifact — registry `measurements.grid_cells` [w,h] →
   `spatial_needs.footprint_cells` → `size_group`; and `entry.name` (the label).
5. **Prop vocabulary** — `commons/data/dna_props.json`; skim `station_plinth.gd` / `station_stage.gd`
   / `station_panel.gd` / `station_pillar.gd` `@identity` so props are chosen for MEANING, not size.
6. **Kin** — `commons/data/artifact_neighbors.json[<lookup>]` (you MAY pull a few in if they
   strengthen the argument). **Baseline** to beat — this map's current `spine_walls.json` entry.

## The editor's spatial model
Orthographic FRONT elevation, **+X = the reading axis** (left→right), 1 m grid. Two gravities:
WALL pieces (panels/signs) mount on the wall face `z≈0.06`, `wall:true`, `y` = height; FLOOR pieces
sit at `z` = depth out from the wall, `wall:false`, and stack. Sized props carry a `config` dict;
the editor applies it + **re-seats artifacts to their real measured height** on load, and **hides
each artifact's floating label** (so the only text is the station plates). A free-3D camera lets the
player orbit, so depth reads.

## REQUIREMENTS (the quality bar)
1. **Prop fits the footprint — never a default 1 m base for a tiny thing.** Size each base to the
   artifact's real footprint:
   - footprint ≤1 cell → `station_plinth` `{"width_cells":1,"depth_cells":1,"top_height":1.0-1.4,
     "cap_inset":0.3}` — a SLIM, high-narrow podium (per the plinth's own "size IS the argument").
   - footprint 2-4 → `station_plinth` `{"width_cells":w,"depth_cells":h,"top_height":0.8-1.0}`.
   - footprint 5-9 → `station_stage` `{"width_cells":w,"depth_cells":h,"step_height":0.18}`, low.
   - footprint >9 → `station_stage` capped ~4×4.
   If an artifact is clearly **sub-1 m** and even a slim 1×1 plinth's foot looks oversized, still use
   the slim 1×1 but **FLAG it in the rationale** as a prop gap (a future micro-pedestal). Big things
   go low+broad; precious small things go high+narrow.
2. **Every artifact gets a 2D-in-3D PLATE label.** Set the prop's `caption_text` (plinth) to the
   artifact's display name — the plinth renders it as a framed, surface-pinned plate. Use
   `station_panel` (wall, 2D-in-3D) for tier-group headers carrying the map's own truth-beats. No
   floating text — the editor hides artifact Label3D; your plates are the labels.
3. **Use the 3D SPACE — do NOT line everything up on one flat z.** Stagger DEPTH (vary `z` ~0.2–2.6)
   and HEIGHT, cluster by tier with foreground/background, give the focal centerpiece its own depth.
   It must still read left→right from the front (iso), but reward orbiting (free-cam) with a genuine
   3D composition — bays, alcoves, a thing set forward, a backing wall set behind. One clear focal
   point. Walkable spacing. Deliberate negative space is allowed.

## Output
- `commons/data/curated_walls/<MAP>.json` — exactly `{ "sequence":..., "counts":{"small":..,
  "medium":..,"large":..,"applied":..}, "pieces":[ {"token","x","y","z","wall","config"?}, … ] }`.
  Tokens must be registry-known (have a scene). `config` only on sized props. (Create the dir.)
- `commons/data/curation_notes/<MAP>.md` — the argument, reading order, focal point, why each prop,
  prop gaps flagged, what to try next.
Verify your JSON is valid. Do NOT edit any other file.
