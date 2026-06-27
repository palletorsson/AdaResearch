# Curation — Vectors_Act1_WhatAVectorIs

> *"Curation is an argument made with placement."* (curation_station @identity)

## The argument the wall makes

The map's whole lesson is one sentence, spoken in its closing truth-beat:

> **"Four facts, one arrow: a where, a which-way, a how-far — and a how-far refused, leaving pure direction."**

So the wall's claim is: **a vector is not four separate things — it is one object (an arrow) examined from four sides, and the object is most fully itself in the WHICH-WAY fact, where the same arrow slid anywhere stays the same vector.** That fact gets the centerpiece; the others orbit it as its *where*, its *how-far*, and its *how-far refused*.

The wall keeps the four-fact spine as the **reading order along +X** (left → right *is* the processional walk the map describes), and turns it into a real **small → medium → large → applied ladder** by deepening the *heart* of the act — the WHICH-WAY fact. The deepening is not invented: the candidate kin were *built as a ladder* and say so in their own `@identity` blocks — `vector_bench` is "the bench-scale opening of the Vector ladder," `free_vector` is "the intimate companion to VectorBasics," `route_vector` is "the applied face of Vector basics," `coordinate_locator` is "the applied face of the Coordinate system." All share the act's central truth verbatim: *"a vector is a journey with no starting address."* The wall assembles a ladder the artifacts were already asking to stand in.

## How this beats the baseline (spine_walls.json)

The baseline already found the right *argument* — the same four-bay ladder, the same centerpiece. But it fails two of the brief's three hard requirements, and this entry fixes both while keeping the reasoning:

1. **It was flat.** Every one of the baseline's 28 floor pieces sat at `z = 0.8` — a single plane, no 3D. This entry **staggers depth across 10 distinct z values (0.4 → 2.2)** and varies height per tier, so orbiting the free-cam rewards you with a real composition: applied beats pulled to the *foreground*, the walk-in frame *recessed*, the focal thesis stepped *forward*.
2. **The plinths were mute.** No baseline plinth carried a `caption_text`; the only text was 5 wall panels. This entry gives **every artifact its own 2D-in-3D plate** — 9 plinth `caption_text` plates + the stage `name_plate`, each set to the artifact's display name (the editor hides the floating Label3D, so these plates *are* the labels).
3. It also corrects two **footprint mismatches**: `VectorBasics` measures 2 cells (aabb 1.22 × 0.82) — baseline put it on a 1×1; here it gets a 2×1. `length_lantern` is footprint `[1,2,1]` — baseline flattened it to 1×1; here it gets the slim 1×2 high-narrow podium its magnitude ruler wants.

## Reading order (left → right = the walk) and the 3D composition

| x | z (depth) | Bay | Fact | Tier | Artifact | Prop (footprint → choice) |
|---|-----|-----|------|------|----------|-----------|
| 2.0 | wall | — | **entry spine label** | — | *station_panel* | names WHERE·WHICH-WAY·HOW-FAR·REFUSED — fills the `intent.md` gap (no on-floor sign at entry) |
| 0.0 | 0.5 fg | 1 | WHERE | small | `coordinate_axes_xy` | 2 cells (flat, 1.56×0.06) → **2×1 low podium**, pulled forward |
| 4.5 | 1.7 **back** | 1 | WHERE | **large** | `CoordinateSystem3M` | 9 cells, aabb 4.76 wide → **4×4 walk-on `station_stage`**, recessed so you *step into* the frame from the front |
| 8.0 | 0.45 fg | 1 | WHERE | applied | `coordinate_locator` | 6 cells → 2×1 podium, foreground |
| 10.0 | 0.4 | — | bay divider | — | *station_pillar* | turns the open floor into a built bay corner |
| 12.0 | 0.6 fg | 2 | WHICH-WAY | small | `VectorBasics` | 2 cells (measured) → **2×1 podium** |
| 14.5 | 1.25 mid | 2 | WHICH-WAY | medium | `vector_bench` | 4 cells → 2×1, set to mid-depth |
| **17.0** | **2.2 forward** | 2 | **WHICH-WAY** | **large — FOCAL** | **`free_vector`** | 9 cells → **3×3 plinth raised to 1.0 m**, stepped *toward* the viewer with its own depth lane — the arrow *and its ghost copies* |
| 21.0 | 0.5 fg | 2 | WHICH-WAY | applied | `route_vector` | 6 cells → 2×1, foreground (the A→B trip) |
| 23.0 | 0.4 | — | bay divider | — | *station_pillar* | |
| 25.0 | 0.9 | 3 | HOW-FAR | small | `length_lantern` | footprint `[1,2,1]` → **slim 1×2 podium raised to 1.25 m** — precious, lifted so the vertical magnitude ruler reads at eye height |
| 27.0 | 0.4 | — | bay divider | — | *station_pillar* | |
| 29.0 | 0.7 | 4 | HOW-FAR REFUSED | small | `vector_normalize_demo` | 1 cell (sub-1 m, aabb 0.9) → **slim 1×1 raised 1.2 m**, signage-style plate |
| 31.5 | 1.4 back | 4 | HOW-FAR REFUSED | applied | `vector_drone` | 4 cells, aabb 1.52 → **2×2 low plinth**, set back (direction-only math that *hunts*) |

**Pillars** (x = 10, 23, 27, near the wall at z≈0.4) cut the four facts into four legible bays. **Panels** carry the map's *own* subtitle truth-beats: the entry spine-name, "Space is a promise three numbers keep," "A journey with no starting address" (crowning the centerpiece at y=2.45), "A diagonal you can see," and "Keep which-way, refuse how-far." The map already wrote these lines (its `subtitles`); the wall pins them to the surface so a learner who misses the audio still gets the anchor.

## The focal point

**`free_vector` at x=17, on a 3×3 plinth raised to 1.0 m, stepped *forward* to z=2.2, crowned by the "journey with no starting address" panel.** It sits at the centre of the run, at the climax of the only complete four-rung ladder, and it is the one artifact that *demonstrates* the act's thesis rather than restating it — the ghost copies make "same arrow, slid anywhere, same vector" a thing you see. Its forward depth (the deepest z on the wall) and its raised height give it sole command of the foreground; everything left builds the vocabulary (where), everything right spends the object (how-far, refused). High-and-narrow because the plinth's soul says *"what you raise high and narrow, you call precious."*

## Why these props (meaning, not just size)

- **`station_stage` 4×4 for CoordinateSystem3M** — the *only* walk-on deck. The frame is the one artifact whose desire is to be *entered* ("feel orientation by standing inside"); a stage is "low enough to step onto," and recessing it makes the step inward literal. Its `name_plate` carries the label.
- **`station_plinth`, sized per meaning** — *"size IS part of the argument — what you raise high and narrow, you call precious; what you set low and broad, you call a world."* So the centerpiece, lantern, and normalize go high-and-narrow (precious); the drone goes low-and-broad (a working machine); the small openers and applied beats get modest 2×1 podiums. Each plinth's `caption_text` is the artifact's display name — the required 2D-in-3D plate.
- **`station_pillar` as dividers** — *"one upright, repeated, makes a room out of an open floor."* Three pillars turn one long shelf into four bays, a procession of four rooms.
- **`station_panel` as labels** — *"a place that presents must also explain… in plain pinned words."* The map already wrote the words; the panels surface them.

## Sieve pass

- **Q1 — thickens the water?** Yes. Over the flat baseline this adds (a) a real 3D composition you can orbit — depth tells you tier (applied = near, frame = recessed, thesis = forward); (b) a name plate on every object so the lesson is legible without audio; (c) a true ladder at four magnifications. New handles to *think* "what a vector is."
- **Q2 — what is foreclosed?** The wall now strongly *asserts* the four-fact reading and the centre; a learner who wanted to discover their own grouping is gently overruled by bays, depth and plates. Acceptable for an Act I opener whose job is to install vocabulary — but a real foreclosure, not a free lunch.
- **Q3 — the dark spot?** The ghost-copy demo of `free_vector` and the drone's hunt are *embodied*, not captioned — the wall trusts the artifacts to carry meaning the plates don't spell out. Generative habitat, not a sterilising seal.

## Prop gaps flagged

1. **Sub-1 m micro-pedestal gap.** `vector_normalize_demo` (aabb 0.90 m) and to a lesser degree `length_lantern` are genuinely *sub-1 m* objects. Even the slim 1×1 plinth's foot reads slightly oversized under them — used here as the brief instructs, but a future **micro-pedestal prop** (≤0.6 m footprint, a tall thin column-cap) would let these precious small things stand without an oversized base. Same gap will recur on every "two-arrows-at-eye-height" demo.
2. **No floor-line / processional-stripe prop.** The `intent.md` gap ("a faint floor line connecting the four stations would make the processional order legible from the start") is still open — the editor has no floor-stripe piece. Wants either a `station_*` floor-line prop or a utilities-layer marker in `map_data.json`.

## What to try next

1. **Capture the composed wall** (`capture_multi_angle.gd --mode=map --target=Vectors_Act1_WhatAVectorIs`) and confirm `free_vector`'s ghost copies (raised to 1.0 m on a forward 3×3) don't collide with the y=2.45 panel above it; if they reach up, drop that panel to 2.2 m.
2. **An exit back-reference panel** at the far +X end ("you now have the object; next, what vectors do to each other") to tie the teleporter to Act II, as `intent.md` requests.
3. If play-testing shows the WHICH-WAY ladder (4 rungs in ~9 m) reads as crowded beside the single-rung HOW-FAR bay, **widen the focal lane** by pushing `route_vector` to x=21.5 and the bay-2 pillar to x=23.5.
