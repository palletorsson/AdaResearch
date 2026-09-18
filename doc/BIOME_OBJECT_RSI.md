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

The critic's path after generation 3: **4** the canopy casts a layer the ground reads (shade
paint, flowers at the drip line, one species); **5** scree — the ridge comes down to the water,
the web's arrow reversed; **6** the basin shows depth and the creatures face what they live by;
**7** the plate's cut edge becomes a section, once there are strata to cut.

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
