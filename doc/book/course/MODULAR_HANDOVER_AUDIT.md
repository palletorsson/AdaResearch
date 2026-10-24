# The handover of 24 October, audited against the repository

*Answer to `ADA_RESEARCH_CLAUDE_HANDOVER_2026-10-24.md` § 11 ("what Claude should do next"): exact
paths and confirmed capabilities, the mapping of existing machinery to the proposed model, the
vertical slice as built and tested, the compression experiment as run, and the next smallest
increment. Written 2026-10-24 in the session that built the modular kernel; nothing here is
committed yet.*

## 1. What exists, by path — confirmed, not guessed

| handover entity | what the repository has | path | status |
|---|---|---|---|
| grammar text | the 25 sequences in the author's notation, prefab symbols validated | `tools/modular_spine_text.py` → `doc/book/course/MODULAR_SPINE_TEXT.md` | runs; 568 prefabs named, 0 unknown |
| primitive / operation | 7 primitives (point, mesh, collider, body, grabbable, label, light, + prefab), operators compose, associate, transform, times, array, assemblage, engine, sort, connect | `commons/modular/builder.gd` (Godot), `ada_encyclopedia/src/lib/modular-terms.ts` (three.js) | both builders, same JSON, probe 56/56 |
| term / symbol | 56 terms with id, label, expr, from, build; chapters | `commons/modular/terms.json` (edited only through the studio/program pages, `POST /api/modular-terms`, atomic, refuses self-containment) | the source of truth |
| prefab reference | 1565 registry tokens with scene path, thumbnail, footprint, sequences, maps | `commons/data/void_spawnlists.json` (`tools/build_void_spawnlists.py`), registry `commons/artifacts/registry/*.json` | read by `{"p":"prefab"}` in both builders |
| assembly recipe | the build JSON itself: parts, relative transforms (`at`, `rot`, `scale`), counts (`n`), ties (`connect`), construction order (the Builder numbers every part) | in each term's `build` | recipe-preserving by construction |
| artifact instance | every term is a registry token `mod_<id>` on `composite.tscn`, spawnable from the wrist menu and placeable in rooms.json / a map; live through the bridge | `commons/artifacts/registry/modular.json` (`tools/build_modular_registry.py`), `commons/bridge/*`, `tools/vr_link.py` | desktop live: tested (mod_tape spawned, `applied in_place`); Quest: the APK with the kernel is NOT exported yet |
| experiment / observation | per-term probes write JSON reports | `commons/testing/probe_modular.gd` (`ada_run/modular_probe.json`), `probe_modular_leak.gd`, `probe_tilt_gate.gd` (`ada_run/tilt_gate_trace.json`) | run headless, deterministic |
| visual memory export | the atlas + canonical AST + scorer | `tools/visual_memory_atlas.py` → `ada_run/visual_memory/{atlas.png, canonical.json, score.json}` | see § 4 |
| 2D editor / magnet wall | the studio (one term, played as a gate), the program page (drag pseudo code), the knowledge tree, the plan pages | `/modular-studio`, `/modular-program`, `/knowledge-tree`, `/modular-plan`, `/modular-plan/3d` | all read the same terms.json / plan JSON |
| thumbnail generator | the game photographs every token; synced to the encyclopedia | `capture_multi_angle.gd` (windowed only — headless saves nothing), `tools/sync_artifact_captures.py` | 56 mod_ captures |
| leaks / edges | what a rule refuses, kept on a bus | `commons/globals/leak_data.gd`; the scaffold spills from `composite.gd`; edges per kernel piece in the plan | measured |
| desktop ↔ VR update path | the live update chain | `doc/LIVE_UPDATE_BRIDGE.md` §§ 1–9 | desktop + Quest for rooms.json edits (floor 3 confirmed on the headset); the modular kernel is desktop-only until the next APK |

**What the handover proposes that does not exist:** a lexer/parser for typed text (the program page
edits the AST directly and *prints* the notation; it does not parse typed sentences back), a type
checker, `attach` with physical joint parameters (a `connect` tie is the relation drawn; the
physics joint behind it is not instantiated), instance IDs that survive a round trip to Godot
(instances are numbered by construction order per build, not persisted), the magnet wall as a
page of its own.

## 2. The model, mapped

- **`=` creates an icon that lives in a sentence** — done. On the program page the sentence is
  rendered with chips: a term's chip is the game's capture of `mod_<id>` (`/artifact-gallery/captures/mod_<id>/front.png`),
  a prefab's chip its registry thumbnail; when Save names a new term, the page snaps the viewport
  as `symbol-<id>.png` so the icon exists before the game photographs it. The id is the identity,
  the picture is the display, as § 2 demands.
- **Drag-programmable pseudo code** — done as a hybrid: blocks are dragged or clicked into a tree;
  the notation is printed from the tree; the JSON is editable in place. Typing a sentence and
  having it parsed is the missing half.
- **A net of prefabs** — the registry's 1565 tokens are in the palette with pictures; a prefab leaf
  builds in both renderers (scene in Godot, footprint box with capture in three.js).
- **Expand / deconstruct / sort / reassemble** — done, as three buttons on the selected block:
  *expand* replaces a name with its recipe and remembers `_from`; *deconstruct* lists every
  instance of every leaf (counts through `times`/`array`, scale through transforms) and lays them
  with `sort by type`, keeping `_lineage {assembly, count, recipe}`; *reassemble* folds them back
  to the name, or to the kept recipe. `sort` is one operator in both builders (size, height,
  width, name, type). The handover's distinction holds: expand shows the recipe, deconstruct
  separates instances.
- **Physical logic** — `tilt_gate` is `step(plank tilted + ball, physics)`; `probe_tilt_gate.gd`
  runs 180 physics ticks and records the ball's x every 15, for the authored tilt and its
  mirror. Result below.
- **Strings** — `connect` ties two parts of a thing by index with a rope, rod or spring, drawn
  between their centres, in both builders; `tied_pallet` uses it. The physics joint is not yet
  behind it.

## 3. The slice, tested

| step | evidence |
|---|---|
| `[cube] * 9 + [plank] * 3 + [plank] * 5 + [plank] * 3 = eu_pallet` | term in terms.json; built by Godot (`mod_eu_pallet/front.png`) and three.js |
| expand | the program page replaces `eu_pallet` with its recipe; status "expanded eu_pallet into its recipe" |
| instantiate | `mod_eu_pallet` registered, photographed, in the wrist menu; the bridge spawn lane applies in place on desktop |
| deconstruct → sort by type | 20 instances (9 cubes, 11 planks of three scales) in a row by type; Godot capture `mod_pallet_sorted/front.png`; lineage kept in the JSON |
| reassemble | the kept recipe restores the pallet expression (checked in the page) |
| reuse the symbol | `tied_pallet = connect(eu_pallet …)` is a term built from the pallet; its chip shows the pallet's picture |
| the physical `if` | `TILT_GATE ok=true authored=right (dx 0.150) mirror=left (dx -0.174) rigid=true/true` — a change to the geometry changes the truth condition |
| builders agree | `check_compile.gd` clean, `probe_modular.gd` 56/56, `tsc` clean on the modular files |

## 4. The compression experiment (slice D)

`python tools/visual_memory_atlas.py` draws 16 symbols — picture, name, chapter, definition in
the notation, "from:" line, arrows to parents, and the legend of operators — into one PNG
(mode B, self-contained), and writes the canonical AST beside it. A fresh model session was
given the image path only, forbidden every other file, and asked for a JSON of name, definition,
parents, root operator and counts per tile. `--score decoded.json` compares.

**Results (2026-10-24, three blind runs, image only, a fresh model session each time):**

| run | atlas | names | parents exact | root operator | counts |
|---|---|---|---|---|---|
| 1 | tiles of six lines, definitions cut with "…" | 16/16 | 16/16 | 16/16 | **14/16** |
| 2 | taller tiles, eleven lines | 16/16 | 16/16 | 16/16 | 16/16 |
| 3 | pictures only, names and definitions hidden | see below | | | |

Run 1's two misses were `eu_pallet` and `tied_pallet`, whose definitions did not fit the tile:
the reader marked both *uncertain* and reported the visible counts ([3, 3, 3]) against the
canonical [3, 5]. That is the handover's own warning measured — an icon does not contain what
was not drawn; the atlas had an edge of the window kind (six lines) and the leak was the fifth
array. Giving the tile room (run 2) closed it. The reader of run 2 still flagged arrows crossing
text, so arrows are now drawn under the tiles, and the notation folds a run of identical parts
into `(part) * n`, which is also what the deconstructed pallet *is*.

Run 3 asked what the thumbnails carry without words. From the pictures alone the reader named
the plain things (sphere, cube, wooden cube, triangle, striped rod, two points joined, scattered
points) at confidence 0.8–0.95 and read their parts correctly; it could not tell the pallet from
the tied pallet (the rope is a hair at thumbnail size), read the sorted pallet as "a thin ruler
with tick marks" (0.45), saw the skateboard's wheels as three balls (there are four; one is
hidden), and found tile 3 (grab_sphere) empty — its capture is blank, a capture fault the atlas
had been hiding behind the printed name. So: the thumbnails carry identity for simple things and
the names carry it for assemblies; a capture that shows nothing is caught only when the name is
hidden. The comparison with a JSON of the same byte size has not been run.

## 5. Prioritised next increments

1. ~~**Parse typed sentences**~~ — done the same day: `parseSentence` in `modular-terms.ts` reads the
   executable subset (`+`, `* n`, `array(a, n[, 3d])`, `association(a, s)`, `transform(a, at … rot … scale …)`,
   `step/by(a, k)`, `sort(a, by k)`, `connect(a, i-j kind, …)`, `assemblage(a, b, …)`, `[prefab]`, names,
   `= name`) into the same JSON the blocks make, with the error's position marked in the sentence; the
   program page has a sentence box ("parse ⏎"). Prose is never parsed. Round trip checked on seven
   sentences, including the tilt gate and a tied compose; `plonk` and `**` are refused at the character.
2. **The joint behind the tie** — `connect` with a physics kind instantiates a Jolt joint when
   the step engine runs (PinJoint for rope, Generic6DOF locked for rod, spring via the verlet
   that `measure`'s plan already wants in both renderers).
3. **Instance identity across the bridge** — give each built part a stable id (term id + path)
   so a deconstructed pallet's pieces can be moved in VR and reassembled from the live scene,
   not only from the recipe.
4. **`measure` in code** — the plan's sixth piece exists as `sort`; the reading as a label beside
   the thing (`length`, `entropy_meter`) is the next operator, in both builders.
5. **The APK** — export with the kernel so the slice is seen on the headset, which the handover
   rightly says must be evidenced, not assumed.
6. **The magnet wall** — a page that arranges the 25 chapters' symbols with tutorial and final
   overlays, reading the same terms.json and the plan JSON.

## 6. Files changed this session (uncommitted)

Ada: `commons/modular/{builder.gd, composite.gd, mod_mesh.gd, mod_surface.gd, mod_behaviour.gd, terms.json, shaders/ink_stroke.gdshader}`,
`commons/artifacts/registry/modular.json` (generated), `commons/testing/{probe_modular_leak.gd, probe_tilt_gate.gd}`,
`tools/{modular_spine_plan.py, modular_coverage.py, modular_spine_text.py, visual_memory_atlas.py}`,
`doc/book/course/{MODULAR_SPINE_PLAN.md, MODULAR_COVERAGE.md, MODULAR_SPINE_TEXT.md, MODULAR_HANDOVER_AUDIT.md}`,
`doc/sieve_passes/2026-10-23T17-40-00_modular-spine-plan.md`, `doc/LIVE_UPDATE_BRIDGE.md`, `commons/data/modular_spine_plan.json`.
Encyclopedia: `src/lib/{modular-terms.ts, knowledge-tree.ts}`, `src/app/{modular-studio, modular-program, modular-plan, modular-plan/3d, knowledge-tree}/page.tsx`,
`src/app/api/modular-plan/route.ts`, `public/textures/marking-tape.png`, stills under `public/book-images/live-update/`.
