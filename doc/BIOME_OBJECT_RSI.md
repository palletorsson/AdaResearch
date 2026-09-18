# The biome as one object, better and better — the RSI loop

> 2026-09-18. Palle: *"skip the glass cage and the whole museum for now, just make the biome
> and we can think about integration later. Look at the old biome and make it better and
> better. Use RSI to make the object and the integrated tiles."* And before that: *"the whole
> thing with a biome is that it must be connected, is a process, everything is related in
> layers."* This memo is the record of what was built, how the loop runs, and what each
> generation changed and why. The lineage itself is `ada_run/biome_rsi/lineage.jsonl`; the
> pictures are `/biome-rsi` in the encyclopedia.

## 1. The old biome, and what it lacked

The old biome is July's living layer: six kingdoms — flora, fungus, fauna, mineral, water,
meta — each with real generators (DNA-driven L-system trees, botanical flowers, space-colonised
mycelium, SDF grubs, a crystal cluster, a pool) behind one grammar,
`kingdom:algo:role[:mod=val…]`, dispatched per painted cell by
`commons/biome_layers/biome_paint_dispatcher.gd`. Its gallery (`/biome-gallery`) shot every
kingdom ALONE on a bare platform: a tree in a cell, a web in a cell, a grub in a cell. Nothing
was placed by anything; nothing touched anything; there was no ground that meant something.

## 2. The object

`commons/artifacts/biome_object/biome_object.gd` (scene, registry `biome_object.json`, probe
`commons/testing/probe_biome_object.gd`). One ground, and everything on it placed by ecology:

| layer | rule (generation 0) |
|---|---|
| substrate | a height field from simplex noise, normalised, a basin dug where the seed puts the water; height 0.5–2.2 m by `relief` |
| water | the cells inside the basin; the old biome's pool (disc, ripple ring, reeds) at the water level |
| moisture | `0.25·moisture + 0.75·(1 − distance to water / reach) − 0.45·height` (+ a little noise), per cell |
| mineral | the driest high cells, spaced, 1–4 clusters by relief |
| flora: trees | the mid-moist slope (`0.32 < m < 0.78`, mid height, > 1.4 cells from water), spaced two cells, 2–7 by `wildness` |
| fungus | the wet rim of the pool (0.9–2.3 cells out, `m > 0.45`), mycelium mats; and a mycelium PATH — one mat per cell along the line from the pool to every tree |
| flora: flowers | the wet meadow (`m > 0.42`, not high), tier by moisture, density by wildness, cap 24 |
| fauna | cells with two or more flower/fungus neighbours, spaced from other creatures, 1–4 by wildness |
| cover | the ring's small covers (grass, reed, fern, toadstool, bloom) by zone and moisture |

Every living body is the old biome's builder reached through the dispatcher —
`spawn_cell(deposit)` with the cell chosen by the rules above and `world_pos` in the patch's
GLOBAL frame (the dispatcher's builders place by global position, as a painted map cell would).
The DNA is five numbers: seed, size, moisture, relief, wildness. The build is deterministic
(`Array.shuffle()` draws from the global rng and had to go), under a second, and writes its
state — counts per kingdom, connections, cover, heights, build ms — for the driver.

## 3. The loop

`tools/biome_rsi.py` (`render | measure | compare | verdict | publish`):

1. **render** the same six DNAs every generation through the DNA sweep rig
   (`capture_config_sweep.gd`, one boot, the parameters read back after setting), so a tile
   in row N compares with the tile above it;
2. **measure** each tile: `integration-v1` = 0.4·layers/6 + 0.3·min(1, connections/6) +
   0.3·min(1, hues/10), and `legibility-v1` = 0.4·min(1, water px/0.06) +
   0.3·min(1, ground variance/0.18) + 0.3·min(1, green px/0.35), both NAMED, both floors;
   plus the fraction of pixels changed against the parent;
3. a **critic** (an agent) looks at the six tiles and the code and writes
   `gen_N/critique.md`: what it sees per tile, the weakest thing, three ranked proposals as
   code-level instructions, what it would not do;
4. a **builder** (an agent) implements the top proposal(s) in the one file, bumps
   `GENERATION`, appends to `CHANGELOG`, extends the probe, and must print `0 failed`;
5. I render, compare, LOOK, and give the **verdict** — kept or culled — written into the
   lineage with the reason; a culled generation's code returns to its parent;
6. **publish**: `/biome-rsi`, rows are generations, the DNA and measures under every tile.

The measure is not the verdict. Generation 2 measured flat and was kept because the eye saw
the gradient; the critic had predicted the number could not see a strand on bark.

## 4. The lineage

| gen | commit | the critic's weakest thing → the builder's change | integration / legibility | verdict |
|---|---|---|---|---|
| 0 | a402bcb6f | — the object | 0.870 / 0.473 | root |
| 1 | cb6f4cd88 | the water and the moisture placed everything and neither was visible (the pool 85–93 % underground) → a flat floor under the water, a wet shelf as shore, the disc lapping it, reeds on the shore; the moisture painted as wet/dry/silt brush layers | 0.965 / 0.724, water 2.5 → 7.9 % | kept |
| 2 | 666bb44c3 | positions but no gradient, so no direction and no process → succession: trees sorted by distance to water and sized by rank; the mycelium path sampled every 0.5 m on the line, the last mat forced to touch the bark, growth steps 25 → 10 along it; the ground carrying the whole gradient (no height gate, a shore, silt by depth); one thin ring | 0.965 / 0.713 | kept on sight against flat numbers |
| 3 | 4113be0ac | no vertical dimension: a map with pins → bodies scaled by rank and moisture (shore trees ×2.3–2.9, saplings ×1.3–1.6, capped by the measured canopy), understory under the canopies and along the mats, grass lerped green → straw by dryness, minerals off the shore, spires by height and dryness, per-kingdom spawn timing on record | 0.975 / 0.716, water 9.0 % | kept |
| 4 | 54ac14bf3 | every layer reads the ground, none reads the layer above → the ground painted after the bodies so a shade layer reads the measured canopy; flowers kept out from under a canopy and favoured at its drip line; one species (intensity ≤ 4). The flower count had to be taken from the meadow before the canopies claim their floor (the builder flagged the loss) | 0.980 / 0.715, 1.7 % of pixels changed | kept — the smallest step, the first relation between layers |
| 5 | d5e07122e | the minerals stood on the rim related to nothing → scree: a trail of 3–7 shards from every cluster down the slope toward the basin, a rock paint layer under clusters and trails, cover off the rock. The critic's gradient rule ran most trails off the plate; the builder extended the fallback (basin direction when the slope faces away) | 0.990 / 0.716, 2.9 % changed | kept; the loop paused here |
| 6 | 629d0ee7f | **Astra's pass** (a second session, critic and builder as one agent): the cover is independent samples that never show they share a condition → cover in moisture-sized tufts sharing a centre, type and colour; reed beds at the shore; flat litter under the inner canopy; the driest ground bare; every member checked against water, shelf, scree, the crystal exclusion and the plate; private seeded streams; cap 864 | 0.975 / 0.733, 3.5 % changed | kept by Astra on sight; seen and agreed, committed by this session |
| 7 | db73c6e6d | (the gen-4 critic's plan, amended by the gen-6 critic) the water a target, the webs the brightest thing → the pool's disc a six-ring fan with vertex colours, dark centre to lighter rim, darkened under every canopy, built after the bodies; no ring; each web's light by its growth step, dim at the finished rim and bright at the tip on the bark; matte crystals | 0.985 / 0.724 (darker water on purpose), 2.7 % changed | kept |
| 8 | 5a8145092 | Palle: grass and plant foliage as transparent images → the cover's grass, reeds, ferns, meadow plants and litter as alpha-cut cards on two crossed quads, one near-white tint per tuft for dryness and shade, images drawn by `tools/make_foliage_cards.py` and loaded by name at runtime; mushrooms keep their mesh | 0.995 / 0.777, 4.0 % changed | kept — the largest step in legibility since generation 1 |
| 9 | e62f0ceee | Palle: can the cards be made procedurally → `foliage_cards.gd` draws the five cards in the engine at build time from the seed and the moisture (a disc brush along Bézier strokes, sin-profiled leaves), 4–10 ms a card, cached per kind, seed and moisture band; the PNG set stays behind `#foliage:files` | 1.000 / 0.777, 1.9 % changed | kept — the same picture from no files; the cards are DNA now |
| 10 | 347cb3c37 (Astra) | the ground ends as a thin sheet -> four schematic soil/rock bands and a closed underside follow the terrain edge; local moisture thickens the dark layer, mineral ground tints the surface strip; foliage and placement unchanged | 0.990 / 0.759, 13.0% changed including automatic camera refitting | kept on sight; 337 checks pass, one mesh / 864 triangles |
| 11 | 60ccb2181 | (the gen-6 critic's plan) the key light, the one directional thing in the frame, was read by nothing → the sun as a constant of the object (read from the frozen rig), the painted shade, the understory and the pool's darkening moved to the displaced shadow centre, the drip-line bonus on the lit side, a slope-aspect term drying the sun-facing flank | 0.995 / 0.756, 15 % changed (layouts re-rolled) | kept |

The critic of generation 3 planned **4** (built) and **5** (built), then **6** the basin shows
depth and the creatures face what they live by, **7** the plate's cut edge as a section. The
critic of generation 4, asked whether that path still held, moved the weakest thing: **the
cover** — the largest layer (110–411 instances) on the largest surface (the ground is 80–87 %
of every subject) is placed by a per-blade coin flip, one quad, one height, one colour, so the
tiles read as a lit sand table with pins; and the webs outshine what they connect. Its path:
**6** tufts — the cover reads its neighbours (built by Astra); **7** water depth under the canopy
and the web's light by its growth (built); **8** the section. The critic of generation 6 (an
independent look at Astra's pass, which it kept for the same reasons) moved the weakest thing
again: every relation is RADIAL — moisture, succession, reeds, shade, drip line, scree are all
functions of distance to one point, so six worlds are six targets at six densities, and the one
directional thing in the frame, the key light, is read by nothing. Its path: **8** aspect — the
sun is a layer (the painted shade, ferns and mushrooms move to the displaced shadow centre, the
meadow's bonus on the lit side, then a slope-aspect term in the moisture); **9** the section —
the cut edge shows the strata; **9 or 10** inhabitants — a creature faces what it lives by, a
worn track behind it. All critiques are in `ada_run/biome_rsi/`.

Twelve generations in one day (two of them another session's), every one kept on sight, none culled: the culling rule has
not yet been exercised, which is a fact about the critics' proposals being small and
well-aimed, not about the rule.

The critic of generation 10 (agreeing with Astra's keep: the ground is a body now, but a
plinth rather than a cut — one layer cake on all six worlds, because the cut runs the perimeter
where every world is driest and most alike) moved the weakest thing to the COMPOSITION: a target,
the basin always in the middle 44 % of the plate, so nothing the process makes reaches the cut;
and the creatures, placed but never turned. Its path: **12** the cut keeps a record (rock rising
to two thirds of a dry cut, soil to the base of a wet one, rock to the skin under a crystal,
the silt on the face of a water cell, the skin darkened in shade); **13** the basin may reach
the edge (a third of seeds move the water to a side; the disc clamped as a D against the cut;
a water face on the section); **13 or 14** inhabitants and the web ages (a creature turned to
face the water or the nearest flower, a worn track behind it; finished cords brown like
rhizomorphs, the growing tip white). It would not add a second pool, nor ripple the water.

## 5. What was learned on the way

- The dispatcher's builders set GLOBAL positions; an object that hands them local coordinates
  scatters its organisms 30 m away in the probe and nowhere in a single scene.
- `Array.shuffle()` draws from Godot's global random; the same seed grew two different worlds.
- The ring's cover recipe has a "tree" type that is a 2.5 m tapered column; used as cover it
  filled every tile with green hexagonal pillars.
- A saturated measure measures nothing: integration-v1 hit 6/6 layers and ≥ 8 connections in
  every world at generation 0, so only its hue counter moved; legibility-v1 was added with
  thresholds set ABOVE generation 0.
- The camera frames a 12 m plate by its diagonal; at framing 1.0 the subject was 15 % of the
  tile. 0.52 gives 29 %.
- A builder that must run the probe to green and a critic that may not edit anything is a
  division of labour that held for four generations without a merge conflict, because one file
  is the object and each generation's change is a commit.

## 6. Open

Generations 4–7 as above. Then the integration Palle deferred: the object as a map artifact
(`biome_object:0#seed:..#moisture:..#relief:..#wildness:..`, a 12 × 12 clear rect) and in the
cage; the object's own `size` beyond 12 (the rules are in cells and metres and should scale);
the creatures as live CritterEntities rather than static SDF bodies; and a second critic voice
(a different model, or Palle) so the loop's taste is not one agent's.


## 7. Generation 6 — one Astra cycle, 18 September 2026

Palle requested one further cycle through the loop. Generation 6 is **kept** after inspection
of all six matched parent/candidate images: cover now gathers into moisture-sized tufts,
shore reed beds and flat litter beneath the inner measured canopy. Each displaced member
checks water, rock and its mesh footprint. The cover budget is capped at 864 instances.

The object and its probe changed; the six DNAs, cameras, shared cover meshes, measures and
driver stayed fixed. This pass used sequential critic/builder roles by Astra, not two
independent agents. See [the critique](../ada_run/biome_rsi/gen_5/critique.md) and
[the full review](../ada_run/biome_rsi/gen_6/review.md), including per-world observations,
source hashes, the initial failed sandbox render and the successful graphics retry.

230 checks passed with zero failures; six images rendered with zero rejected parameters.
All non-cover kingdom counts and connections were preserved. Integration-v1 fell from
0.990 to 0.975 because of fewer hue bins; legibility-v1 rose from 0.716 to 0.733. The verdict
keeps the clearer spatial grouping while recording the score loss. Extra cover is not free:
291–788 instances, with cover construction taking 17–29 ms in this rendered sweep. Headset
performance remains untested. The local `/biome-rsi` gallery carries the new row.

The next candidate is water/canopy appearance and the brightness of the connecting mycelium.
No generation 7 or museum integration was undertaken in this cycle. The 0–5 blog remains
the historical account of the earlier morning; the lineage records this continuation.

## 8. Generation 10 — the ground in section, 18 September 2026

Palle requested the next cycle after the foliage work. The current parent was
**generation 9**, with both file-backed and engine-drawn foliage already present.
Generation 10 is kept: the landscape now has cut soil/rock sides and a sealed base
beneath its unchanged terrain. The dark layer thickens with local moisture; the
surface strip responds to mineral ground. It is a schematic section, not a soil
or groundwater simulation.

Astra performed sequential critique, build and review. All six images were
inspected; all earlier non-timing counts and organism placements are preserved.
337 probe checks passed, including closed-mesh boundaries, footprint, positive
layer thickness, winding and determinism at sizes 4, 12 and 24. Cost: one mesh and
material, 864 triangles at size 12, 14–19 ms construction in the rendered sweep.

Integration-v1 falls from 1.000 to 0.990 and legibility-v1 from 0.777 to 0.759.
The larger subject makes the unchanged water a smaller fraction of the image.
The keep verdict is visual. The capture settings stayed fixed, but the rig's
automatic bounding-box fit responds to added depth: pixel change includes camera
reframing. The local gallery has the new row; headset performance remains untested.

See [the parent critique](../ada_run/biome_rsi/gen_9/critique.md),
[the review and limitations](../ada_run/biome_rsi/gen_10/review.md), and
[the evidence](../ada_run/biome_rsi/gen_10/iteration-report.json).
The first material draft is archived under `gen_10/attempt_1/`; the main lineage
contains only the final generation-10 row. No commit or museum placement was made.
The next candidate is the earlier directional-light/understory proposal.
