# SPIKE 07b — prop defaults on a module's walls: the CONSUMER and the COST

*Branch `palm-scanner-door-entry`, HEAD `e9202f1384920443cd1fffbf7cd91250dd45e599`.
Everything below is measured against HEAD unless a line says otherwise. No Godot
was run. No repo file was edited.*

## VERSION STATEMENT (Law 1)

| file | state |
|---|---|
| `commons/scenes/em/em_props.gd` | TRACKED, **clean vs HEAD** — described as at HEAD |
| `commons/scenes/em/em_budget.gd` | TRACKED, clean vs HEAD |
| `commons/scenes/endless_museum.gd` | TRACKED, clean vs HEAD |
| `doc/spatial/HANDOVER.md`, `doc/reports/{white_cube,museum_modularity}.md` | TRACKED, clean vs HEAD |
| `commons/data/template_patterns.json` | TRACKED, clean vs HEAD |
| **`commons/data/museum_module_kit.json`** | **UNTRACKED — not in HEAD** |
| **`tools/em_white_cube_measure.py`** | **UNTRACKED — not in HEAD** |
| **`tools/em_wall_merge_measure.py`** | **UNTRACKED — not in HEAD** |
| **`tools/em_module_measure.py`** | **UNTRACKED — not in HEAD** |
| **`ada_run/museum_aaa_pass/museum_wall_aaa_static_profile.json`** | **UNTRACKED — not in HEAD** |

The consumers are committed. **The kit, its certified profile, and all three
instruments that produced 11.7 / 7.29× / 91.4% are not.** A fresh clone gets the
§6 ruling and none of its evidence, and gets no kit to be ruled about.

---

## QUESTION

Could the modular system hold PROP DEFAULTS at declared places along its walls,
applied when the endless museum is assembled? Specifically: what would read such a
declaration, what does that reader do today, and what would the declaration cost
the frame?

## PROBE

`em_props.gd` (1368 lines) read in full; `em_budget.for_segment`;
`endless_museum._dress_props` / `_build_segment` / `_deal_segment`;
`museum_module_kit.json` in full; the 30 museum-tagged tiles run through the
existing Python mirror; a static draw-node census of the 19 PLACEABLE props.

## BASELINE — what I was handed, and what each claim turned out to be

| brief claim | source | verdict |
|---|---|---|
| `props_per_10m` "never supplied by anything" | HANDOVER §8:277 | **FALSE at HEAD.** Supplied by `em_budget.gd:450`. |
| kit = 11.7 draw nodes / linear m | HANDOVER §6:191 | number verified; **the 11.7× ratio is not** — mixed denominators |
| museum = 1.0 nodes / linear m | HANDOVER §6:191 | verified on wall-CELL metres; **1.346** on the run metres the kit uses |
| `--em-wall-runs` 7.29×, pixel-identical | HANDOVER §7:228 | **verified** — 6826 → 936, re-run today |
| 91.4% of band area bare | HANDOVER §5:148 | **verified to 4 s.f.** — 91.41% |
| a prop scheme on that kit "inherits the weight" | brief | **FALSE.** `prop_zones` are coordinates; they carry no geometry. |

## PREDICTIONS, WRITTEN BEFORE THE MEASUREMENTS

1. `props_per_10m` still has no supplier. → **WRONG.** It has had one since the
   white-cube pass, and that pass is in HEAD.
2. Supplying it will *increase* prop density (it is called a density knob).
   → **WRONG, inverted.** It cuts prop count corpus-wide from 301 to ~50.
3. The 19 placeable props will cost roughly 5–8 draw nodes each, i.e. props will
   be a rounding error against 6826 wall boxes. → **WRONG, 2–3× low.** Mean 17.6,
   and the props of one segment outweigh that segment's entire wall.
4. A prop_zones default scheme would overload the frame. → **WRONG in mechanism.**
   It would be silently truncated by `em_props.gd:465` long before it overloaded
   anything. The failure is under-delivery, not weight.

Four predictions, four disagreements. Per §8, that is the whole value of the pass.

---

## FINDINGS

### F1 — `props_per_10m` HAS a supplier, and the handover contradicts itself

**EXPECTED:** grep finds one reader and no writer, per HANDOVER §8:277-278.

**ACTUAL:** one reader, one writer, both in HEAD.

- read: `commons/scenes/em/em_props.gd:449`
  `var rate: float = float(allowance.get("props_per_10m", wf_rate * PROP_SHARE))`
- written: `commons/scenes/em/em_budget.gd:450`
  `out["props_per_10m"] = WHITE_CUBE_PROPS_PER_ROOM * 10.0 / wall_run`
  guarded by `if white_cube:` at `:441` and `if wall_run > 0.0:` at `:449`.
- constant: `em_budget.gd:311` `WHITE_CUBE_PROPS_PER_ROOM := 2.0`
- reaches em_props: `endless_museum.gd:2384` `allowance = (b as Dictionary).duplicate()`
  where `b = deal["budget"]`, set at `endless_museum.gd:1465`.
- turned on by: `endless_museum.gd:333` `--em-white-cube`, or `:603` a pattern's
  `"white_cube": true`.

**CAUSE:** HANDOVER §8 is a *quotation of the white-cube report's own before-state*
(`doc/reports/white_cube.md:68`, past tense: "had read … and **nothing had ever
supplied it**"). It was copied into the handover as present tense. §7 item 5 of the
same document already implies the opposite — "which buildings declare `white_cube`
(currently 0 of 182, so the paint works and reaches nobody)". The paint working is
the supply existing.

**Verified:** 182 pattern keys, 30 museum-tagged, **0 declare `white_cube`, 0
declare `wall_runs`**. So the supplier exists and is unreachable from data; only
the CLI flag reaches it.

### F2 — the knob is gated behind a *different* knob, and is dead for 8 of 30 museums

**EXPECTED:** `props_per_10m` sets the prop rate.

**ACTUAL:** `rate` is read at `:449` and **used at exactly one line**, `:458`,
inside the third arm of a branch on a different variable (`em_props.gd:452-459`):

```gdscript
if wf_rate < RATE_SILENT:            # 0.6   -> cap = 0     rate NEVER READ
elif wf_rate < RATE_STATUTORY_ONLY:  # 1.5   -> cap = 1     rate NEVER READ
else: cap = int(round(run_m * 0.1 * rate))                # rate read here only
```

Measured over the 30 museum tiles: **22 buildings reach the third arm; 6 are in the
statutory band (chichu 0.8, katsura 0.8, mesdag 0.8, thoronet 0.6, libeskind 1.0,
neue 1.0); 2 are silent (sando 0.5, teshima 0.3).** For those 8, supplying
`props_per_10m` does nothing at all.

**CAUSE:** deliberate — `em_budget.gd:403-407` states it: `wall_features_per_10m`
is returned unchanged so a Teshima still gets nothing. The consequence is that the
knob is *partial*, which nothing says.

### F3 — supplying it DELETES the fire extinguisher and the E-stop from every museum

**EXPECTED:** a rate knob thins props evenly.

**ACTUAL:** at `cap = 2`, `em_props.gd:474-476`'s quota table
(`Q`, `:209-218`) resolves to:

| family | round(2 × share) | clamped | |
|---|---|---|---|
| statutory | round(0.50) = 1 | **1** | R1 exit sign over the portal takes it |
| feature | round(0.50) = 1 | **1** | one wall-run feature |
| gate/ceiling/run/edge/backing/pocket | round(0.26…0.38) = 0 | **0** | nothing |

Rule order (`:484-497`) gives the single statutory place to `_rule_exit_portal`
(R1). `_rule_door_furniture` (R2) — the extinguisher/E-stop pair, the one placement
in the file with a written safety justification (`:858-874`) — **never fires**.
Same for the far exit sign (R3).

So `props_per_10m = 2.0/room` is not "fewer props"; it is "an exit sign and a
clock, and no fire equipment anywhere in the building set." That is a decision
about a museum, not a density dial, and no line of the white-cube paperwork says
it.

### F4 — the Python mirror models a white-cube prop path the GDScript does not have

**EXPECTED:** `tools/em_white_cube_measure.py` mirrors `em_props.dress`, as
`white_cube.md:22-24` asserts ("checked against the live engine four separate
times … agreed exactly every time").

**ACTUAL:** two divergences, both only active under `white_cube=True`:

1. `em_white_cube_measure.py:349`
   `wf = min(wf, WC_WALL_FEATURES_PER_10M) if wf > 0 else wf` — the mirror
   **overwrites** `wall_features_per_10m` with ≤ 0.55.
   `em_budget.gd:425` returns `wf_rate` **unchanged**; only `hang_rate` (`:409`)
   is swapped, and only into `wf_max` (`:410`).
2. `em_white_cube_measure.py:368,370` `if wf_rate < RATE_SILENT **and not
   white_cube**` / `if wf_rate < RATE_STATUTORY_ONLY **and not white_cube**` —
   the mirror **bypasses** the silent and statutory bands. `em_props.gd:452-456`
   has no `white_cube` parameter at all; it cannot bypass them.

Divergence 2 exists to undo divergence 1 (0.55 < 0.6 would put every building in
the silent band). The two cancel for the 22 full-rate buildings and **do not cancel
for the other 8**:

| | mirror | engine (derived from source) |
|---|---|---|
| props under `--em-white-cube`, 30 museums | **59** | **50** |
| sando (wf 0.5) | 2 | **0** |
| teshima (wf 0.3) | 1 | **0** |
| chichu / katsura / mesdag / thoronet / libeskind / neue | 2 each | **1 each** |

**CAUSE:** the mirror was written to reproduce the *intent* of the gate; the
engine implements it in two files that each see half of it. `em_props` never
learns the gate is on.

**CONSEQUENCE, and it is the honest headline:** `props_per_10m` has been supplied
for one pass and **has never once been measured in the engine**. Every published
white-cube prop number is a mirror number, and the mirror is wrong about the eight
quietest buildings — the ones the band logic exists to protect.

### F5 — the 11.7× ratio mixes two denominators; the true factor is 8.7×

**EXPECTED:** 11.7 nodes/m and 1.0 nodes/m are the same measurement of two things.

**ACTUAL:** they are two measurements.

- kit: `museum_wall_aaa_static_profile.json` → `render_draw_nodes 1496`,
  `corpus.length_m 128`, `corpus.runs 8`, spec `endcap:1|service:2|feature:4|
  window:3|vitrine:3|solid:2|endcap:1` = 16 cells × 8 = **128 m of dressed RUN,
  one face.** 1496 / 128 = **11.69**. ✓
- museum: 6826 wall **CELLS** → 6826 boxes → 6826 / 6826 = **1.00**. ✓
- but the museum's dressed run is **5071 m**, not 6826 m (a wall cell with no
  floor in front of it — outer skin, back-to-back walls — is a metre of wall and
  zero metres of run).

On one denominator (dressed run, which is what a wall panel and a prop both mount on):

| | draw nodes / m of dressed run |
|---|---|
| certified kit | **11.69** |
| museum walls today (6826 / 5071) | **1.346** |
| museum walls merged (936 / 5071) | **0.185** |

**11.69 / 1.346 = 8.68×, not 11.7×. 11.69 / 0.185 = 63×, not 85×.**

The §6 ruling's *direction* survives intact and is not disturbed. Its arithmetic
does not. This is `doc/spatial/HANDOVER.md` §8's own "two places holding one
number", found a seventh time, in the very ruling that governs this design
question.

Also unremarked anywhere: `"vr_90hz_certified": false` in the kit's own profile.
The word "certified" in the ruling means eleven static gates, not a frame budget.

### F6 — the props em_props already stamps outweigh the wall they hang on

**EXPECTED:** props are cheap next to 228 wall boxes per segment.

**ACTUAL:** a cap-16 segment's props cost **277 draw nodes** against **202** wall
boxes. See COST MODEL. Nobody has ever counted them: `endless_museum.gd:2441`
prints a prop *count*, never a node cost, and `em_props.gd:186-190` states the
ceiling in *instances* ("16 × 3 = 48 live prop instances") as if a prop were one
node. A prop is 17.6 nodes.

### F7 — `prop_zones` already exists in the kit, and is a coordinate list, not geometry

`museum_module_kit.json` → `modules.uffizi_bay_v1.prop_zones`:

```json
[{"wall":"north","x_m":[-3.75,-2.25]}, {"wall":"north","x_m":[2.25,3.75]},
 {"wall":"south","x_m":[-3.75,-2.25]}, {"wall":"south","x_m":[2.25,3.75]}]
```

Four zones, 1.5 m each, on an 8×4×8 module. Plus `wall_kit.kinds.service`
(*"peripheral prop/services zone"*, widths 1–4) and `feature_field.keep_clear:true`.
`certification.gates` includes `prop_zones_peripheral`.

**This is exactly the declaration Palle is asking about, and it is already written.**
It weighs nothing: reading four dicts costs zero draw nodes. The 11.7 belongs to
`parts.wall_cell` (16 × `[1, 4, 0.15]`) and `museum_wall_piece.gd`, which a prop
scheme need not instantiate. **The brief's "a prop scheme that rides in on that kit
inherits the weight" is false**, and it is the one claim that would have killed the
idea.

### F8 — em_props' R8 is already a worse guess at what `service` declares

`_rule_wall_run_features` (`em_props.gd:1119-1155`) picks `run[0]` or `run[-1]`
alternating on `i % 2` — "the run's END faces, where services cluster in a real
building". The kit says the same thing *by authorship*:
`uffizi_north = service:2|feature:4|solid:2`. The service band is at ONE end, not
alternating ends; R8 would put a clock on the `solid:2` end half the time, and
`feature_field.keep_clear` is invisible to it.

So a declaration does not add a system. It **replaces a heuristic with the author's
answer** — §8's "prefer turning a knob to adding a system", one level up.

### F9 — the two objects are NOT the same objects

The kit's vocabulary (`solid feature window vitrine service portal endcap`) is
**wall pieces**: architecture, 1–4 cells wide, `museum_wall_piece` /
`museum_wall_run`. em_props' vocabulary is **19 registry artifacts** with their own
scenes, `@export`s and DNA. Zero overlap. `PLACEABLE` (`em_props.gd:388-392`)
contains no kit token; the kit contains no artifact lookup name. They meet only at
`kinds.service` ("peripheral prop/services zone"), which is a *place for* an
em_props prop and not a prop.

Consequence: **`prop_zones` can be adopted without adopting one line of the wall
kit.** That is the whole design.

### F10 — `--em-wall-runs` is free for em_props, so the flip is uncontested here

`_dress_props(seg, tile, w, h, zbase, deal)` (`endless_museum.gd:2373`, called at
`:1279`) is handed the **tile**. `em_props._geometry` (`:550`) rebuilds walls,
floors, faces and runs from that tile. The merge gate touches only `_wall_at`
(`:983`) and `_stamp_wall_runs` (`:1005`) — box emission. The two never meet.
Corroborated by the engine's own before/after log (`museum_modularity.md:311-322`):
dressed faces 170/205, licence 50/52, showings 50/52, **props 16 → 16**, identical.

If the flip lands, prop cost per metre of wall *object* rises 7.29× by arithmetic —
props unchanged, wall objects down 7.29× — which is exactly why the prop node
count stops being a rounding error and starts being the budget.

---

## EVIDENCE

Re-derivations run today, all Python, no Godot:

```
tools/em_wall_merge_measure.py           6826 -> 936 boxes, 7.29x   [VERIFIED]
                                         uffizi-spine-enfilade 202 -> 22 (9.18x)
mirror over 30 museum tiles              5071 m dressed run          [VERIFIED]
                                         301 props, 10.03/room, 0.0594 props/m
                                         band 13133.9 m2, covered 1128.4,
                                         bare 12005.5 = 91.41%       [VERIFIED]
museum_wall_aaa_static_profile.json      1496 / 128 = 11.69 nodes/m  [VERIFIED]
template_patterns.json                   182 keys, 30 museums,
                                         white_cube:true = 0, wall_runs:true = 0
registry lookup                          19/19 PLACEABLE resolve (lab.json 17,
                                         packaging.json 2)
sprinkler / smoke detector / speaker     0 artifacts in 108 registry files
```

**Draw-node census, 19 PLACEABLE props.** Method: static walk of each script's
`_ready`/`_build` call graph, counting `MeshInstance3D|Label3D|OmniLight3D|
SpotLight3D|MultiMeshInstance3D|Sprite3D .new()`, resolving `for … in range()`
bounds from `@export`/`const` defaults **and from em_props' own config overrides**
(`slat_count 8`, `bar_count_x/z 8`, `breaker_count 12`), and following
node-returning helper factories (`_box()` etc.) to 4 levels.

| token | nodes | | token | nodes |
|---|---|---|---|---|
| fire_hose_box | 38 | | wall_clock | 18 |
| fire_extinguisher | 35 | | gas_canister | 16 |
| electrical_panel | 31 | | ceiling_vent | 14 |
| hangar_wall_panel | 28 | | palm_scanner | 14 |
| hangar_barrier_fence | 25 | | iv_stand | 12 |
| cable_tray | 22 | | exit_sign | 10 |
| floor_grate | 21 | | clamp_stand | 9 |
| lab_stool | 19 | | whiteboard / large_window | 6 / 6 |
| | | | emergency_button / info_screen | 5 / 5 |

**Total 334, mean 17.6.** These are **LOWER BOUNDS**: the walk cannot see nodes
built inside preloaded sub-scenes (`TextScreen`, `HangarKit`) or behind
non-literal loop bounds. A first pass that ignored helper factories returned
`hangar_wall_panel = 1` and `hangar_barrier_fence = 1`; both route every mesh
through a `_box()` helper (`hangar_barrier_fence.gd:205-213`). **A static census
that does not follow factories under-counts by 25×**, which is why the number is
declared a floor and not a figure.

---

## COST MODEL

All arithmetic on ONE denominator: **metres of dressed wall run** (5071 m corpus,
170 m for `uffizi-spine-enfilade`). Prop node cost 17.3/prop for the cap-16 basket,
17.6 corpus mean.

### The cap-16 basket, derived from `Q` and the rule order

`cap=16` → quota `statutory 4, feature 4, gate 2, ceiling 2, run 1, edge 1,
backing 1, pocket 3` = 18 requested, `cap` binds at 16:

```
statutory 4  exit_sign 10 x2 + emergency_button 5 + fire_extinguisher 35 =  60
feature   4  wall_clock 18 + info_screen 5 + whiteboard 6 + large_window 6 = 35
gate      2  electrical_panel 31 + palm_scanner 14                        =  45
ceiling   2  ceiling_vent 14 x2                                           =  28
run       1  cable_tray 22                                                =  22
edge      1  floor_grate 21                                               =  21
backing   1  hangar_wall_panel 28                                         =  28
pocket    1  fire_hose_box 38                                             =  38
                                                              16 props   = 277
```

### One segment (uffizi-spine-enfilade: 170 m run, 202 wall cells)

| | draw nodes | nodes / m of run |
|---|---|---|
| wall geometry today | 202 | 1.188 |
| wall geometry merged (`--em-wall-runs`) | 22 | 0.129 |
| **props today (16)** | **277** | **1.629** |

**The service furniture of one segment already outweighs that segment's entire
wall by 1.37×, and outweighs its merged wall by 12.6×.**

### Corpus, 30 museums

```
props today   301 x 17.3 =  5 207 nodes  ->  5207 / 5071 = 1.027 nodes/m
walls today                6 826 nodes  ->  6826 / 5071 = 1.346 nodes/m
walls merged                 936 nodes  ->   936 / 5071 = 0.185 nodes/m
certified kit walls                     ->  1496 /  128 = 11.69 nodes/m
```

Props are **76% of the entire wall geometry of every museum in the corpus**, and
**5.6× the merged wall**.

### Scheme A — `props_per_10m` as it is supplied today (2.0 per room)

Engine-derived (F4), not mirror: 22 buildings × 2 + 6 × 1 + 2 × 0 = **50 props**.
At cap 2 the basket is `exit_sign 10 + wall_clock 18 = 28` nodes/segment.

```
50 props x ~17 = 850 nodes  ->  0.168 nodes/m     6.1x LIGHTER than today
```

**The supplied knob is a 6× weight reduction, not an increase.** Its cost is F3:
no fire equipment.

### Scheme B — the kit's own `prop_zones` density, applied as a default

`uffizi_bay_v1` is 8×8 cells with 4 zones. Its dressed run is north 8 m + south 8 m
= 16 m (east/west are `gallery_spine_3m` sockets). **4 / 16 = 0.25 props per metre
of run** — 4.2× em_props' measured 0.0594.

```
corpus:   5071 m x 0.25 = 1 268 props x 17.6 = 22 317 nodes -> 4.40 nodes/m
segment:   170 m x 0.25 =    42 props x 17.3 =    727 nodes -> 4.28 nodes/m
live (3 segments, em_budget.SEGMENTS_LIVE)  =  2 181 nodes of props
```

Against a full building on the same denominator:

| configuration | nodes / m |
|---|---|
| certified kit walls, **no props at all** | 11.69 |
| Scheme B props + walls today | 4.40 + 1.346 = **5.75** |
| Scheme B props + merged walls | 4.40 + 0.185 = **4.59** |
| today (props + walls) | 1.027 + 1.346 = 2.37 |
| today's props + merged walls | 1.027 + 0.185 = 1.21 |

**Scheme B costs 2.4× the current building and is still 2.5× lighter than the
certified kit's walls with nothing on them.** The kit's weight lives in
`museum_wall_piece`, not in `prop_zones`.

### …except Scheme B cannot happen, and that is the real finding

`em_props.gd:460-465`:

```gdscript
var artworks: int = int(allowance.get("artworks", 0))   # = deal["placed"]
...
cap = mini(cap, artworks)          # props never outnumber the art
```

`endless_museum.gd:2386` supplies `artworks = deal["placed"]` — 16 for the Uffizi.
Scheme B asks for 42. `MAX_PROPS_PER_SEGMENT` (`:191`) is 16 on top of that.

**42 requested → 16 stamped. 62% of every declared prop_zone silently dropped, in
the arrival order of `Q`.** No warning is printed; `:2441` prints
`"%d of %d offered"`, and the zones that lost never became offers. This is the
same loss channel as HANDOVER §7 item 3 ("15 more vanish SILENTLY inside
`_stamp()`"), reached from the other end.

So the correct cost of a prop_zones default scheme *as the code stands* is
**zero extra nodes and 26 lost declarations per segment.** Under-delivery, not
weight.

### The reductio the brief asks for, stated so it can be discarded

"Props on the 91.4% of band area currently bare": bare band = 12005.5 m²;
`PROP_FACE_AREA` = 0.16 m²/prop.

```
12005.5 / 0.16 = 75 034 props x 17.6 = 1 320 598 draw nodes
              = 2 501 props per segment, 193x em_budget's whole artifact ceiling
```

**Filling the bare band is not a design target and must never be read as one.**
91.4% bare is a *finding that the wall is not crowded*
(`white_cube.md:38-40`), i.e. an argument for MORE white, not for more props. The
brief's framing of it as headroom inverts the report it comes from.

---

## (d) SPRINKLERS, SMOKE DETECTORS, SPEAKERS — a SEPARATE need

A per-module prop-default scheme **does not** answer HANDOVER §7 item 7. Three
independent reasons:

1. **`prop_zones` cannot express a ceiling fitting.** All four entries key on
   `"wall": "north" | "south"` with an `x_m` range. There is no ceiling zone, and
   none of the seven `wall_kit.kinds` is a ceiling kind.
2. **The objects do not exist.** Searched all 108 registry files: **zero**
   artifacts matching sprinkler / smoke / detector / speaker / alarm. The grid
   system's equivalents are *procedural fixtures inside*
   `commons/grid/GridCeilingComponent.gd:40-48, 281-324`
   (`fixture_sprinkler_count`, `fixture_sensor_count`, `fixture_speaker_count`) —
   meshes built by the ceiling, not registry artifacts. em_props can only stamp a
   registry token (`em_props.gd:1320`, `endless_museum.gd:2404-2412`).
3. **em_props' own ceiling channel is already full and already tiny.**
   `Q["ceiling"] = [0.13, 0, 2]` and the only ceiling token is `ceiling_vent`. At
   cap 16 that is 2 places; at cap 2 it is 0.

**In em_props' idiom the answer is:** three new registry artifacts (target ≤ 5
nodes each — `emergency_button` is 5, so it is reachable), a new `Q` family
`"overhead": [share, 0, n]`, and one rule keyed to the same coffer geometry R4
already uses (`BAY 3.0`, `SLOT_W 0.55`, `CEIL_SOFFIT 3.14`,
`em_props.gd:126-131`). Cost at 3/segment × 5 nodes = 15 nodes/segment, 0.09
nodes/m — genuinely negligible, unlike the props already there. **It shares
nothing with the prop_zones question and should not be bundled with it.**

---

## (e) WHAT WOULD BREAK

Ranked by how silently it fails.

**E1 — the wall is 1 m thick in em_props and 0.15 m thick in the kit.**
`endless_museum._wall_at:988` stamps `Vector3(1, 3.0, 1)` — the wall FILLS its
cell. `em_props._dressed_faces:626-627` therefore puts the mount plane at
`cell + 0.5 + dv*0.5`, the cell boundary. The kit's `parts.wall_cell.cell_m` is
`[1, 4, 0.15]`. A module-built wall would leave the mount plane **0.425 m in
front of the actual wall face**, and every one of the 19 props would float. Nothing
would error; `WALL_PROUD_MAX 0.16` would still pass, because it measures the prop,
not the wall.

**E2 — the wall is 3.0 m tall in em_props and 4 m in the kit.** Nine constants are
mirrored from the host and would all be wrong at once (`em_props.gd:115-133`):
`WALL_H 3.0`, `CORNICE_BOTTOM 2.72`, `CEIL_SOFFIT 3.14`, `SKY_Y 2.92`,
`RIB_UNDERSIDE 2.96`, `Y_EXIT_PORTAL 2.72`, `Y_CABLE_TRAY 2.86`. R1's written
justification (`:837-844`) — *"a 0.18 m sign centred at 2.72 sits inside that
overpanel … wall to 3.00"* — becomes false, and the sign lands mid-wall on a 4 m
plane.

**E3 — the vent pin, exactly as §6 warned.** R4 (`:948-974`) pins the vent's z to
`3k·BAY + (BAY − SLOT_W)/2` — the middle of a 2.45 m solid coffer panel on a 3.0 m
module — and nudges x off the ribs at `x = 0, 3, 6…`. The kit's module has
`ceiling_beam.pitch_m = 1` and 8 × `skylight_cell [7.8, 0.035, 0.9]`. **There is no
3.0 m coffer and no 2.45 m panel.** The vent would be pinned to a plane that no
longer has panels. R6's floor grates key off the same module (`z % 3 == 2`,
`:1046`) and R5's tray rib-avoidance uses `BAY` (`:1017-1019`). One ceiling change
invalidates three rules.

**E4 — a kit-declared `portal` is invisible to the door rule.** `_doors()`
(`:683-744`) finds an opening by scanning the **tile** for a 1–3 cell floor gap
walled at both ends. A `portal:3` wall piece is a declaration in
`museum_module_kit.json`; unless the tile also encodes floor there, R2's
extinguisher/E-stop pair — the one placement with a safety argument — never fires
at a module's own door.

**E5 — subdividing a wall changes what a RUN is.** `_runs_of` (`:641-676`) groups
faces by `"%s|%.1f|%.0f|%.0f"` (axis, plane, normal) and breaks on a gap > 1.01.
Wall-kit pieces of widths 1–4 in one plane still merge into one run — *provided the
pieces stay in the same plane*. A `vitrine` piece is by definition **recessed**
("recessed wall exhibit"), so it changes the plane, splits one run into two, and
`R8`'s `run.size() < 3` / `< 4` guards (`:1124, 1138, 1145`) start refusing.
`whiteboard` and `large_window` need `run.size() >= 4` and would go first.

**E6 — the declaration has no home in the pipeline.** `prop_zones` are declared
per **module** (`uffizi_bay_v1`) in an untracked kit file. em_props is handed a
**tile** from `template_patterns.json`. Nothing maps one to the other: no template
names a module, and `slot_capacity.json` covers slots, not zones. A default scheme
needs that binding invented, and inventing it in the kit file means inventing it
somewhere nothing reads.

**E7 — what does NOT break:** `--em-wall-runs`. F10. It is independent of em_props
by construction and the engine's own log proves it.

---

## PROPOSED FIX (not applied)

Additive, gated, and it puts the declaration where the reader already looks.

1. **Correct HANDOVER §8:277-278** to past tense and cross-link §7.5. One line.
   (`props_per_10m` is supplied by `em_budget.gd:450` under the white-cube gate.)
2. **Correct HANDOVER §6:191** to state the denominator: *"11.7 draw nodes per
   metre of dressed run against the museum's 1.346 on the same measure — 8.7×,
   not 11.7×."* The ruling stands; the arithmetic is repaired.
3. **Commit the kit and the three instruments**, or delete them. A tracked ruling
   about an untracked file is unfalsifiable from a clean clone.
4. **Fix the mirror**, `em_white_cube_measure.py:349,368,370`: drop the `wf`
   overwrite and the two `and not white_cube` bypasses, so it models what
   `em_props.gd:452-459` actually does. Expect corpus white-cube props 59 → 50.
5. **Declare prop zones on the TILE, not on the module.** A new optional key on a
   `template_patterns.json` pattern:

   ```json
   "prop_zones": [{"axis":"x","fixed_z":7,"from":2,"to":5,"family":"feature"}]
   ```

   Cells, not metres (F4/F5 of spike 01 — never re-import a metre field onto a
   1 m grid). Read in `em_props._geometry`, consumed by `_rule_wall_run_features`
   in place of its `run[0]/run[-1]` guess. **A tile with no `prop_zones` key takes
   the existing path unchanged.** Cost: zero draw nodes.
6. **Raise `artworks` out of the way, or accept truncation loudly.** If a zone
   scheme is to be honoured, `em_props.gd:465` must either be relaxed for
   declared zones or the drop must be reported: change `:2441`'s print to name
   the refused zones. **Do not relax it silently** — that line is the promise in
   the file's own header (`:90-91`).
7. **Sprinklers separately** (see (d)). Three artifacts, one `Q` family, one rule.

**What this deliberately does NOT do:** instantiate `museum_wall_piece`,
`museum_wall_run` or `museum_wall_kit_atlas`. The 11.69 nodes/m stays on the bench.

---

## NEGATIVE TEST — must FAIL today, PASS after

Two halves; both are required, because half 2 alone is satisfied by doing nothing.

**N1 — the declaration bites.**

```
Add to ONE pattern in commons/data/template_patterns.json (uffizi-spine-enfilade):
    "prop_zones": [{"axis":"x","fixed_z":7,"from":2,"to":5,"family":"feature"}]
Run EmProps.dress on that tile and assert:
    exactly one placement with family == "feature" AND
    2 <= placement.cell.x <= 5 AND placement.cell.y == 7
```

*Today:* `_geometry` (`em_props.gd:550`) never reads the key; R8 takes
`run[0]`/`run[-1]` by `i % 2`. The assertion **fails** — the feature lands at a
run end that the zone does not contain. Verified by inspection: no occurrence of
`prop_zones` anywhere in `commons/scenes/em/`.

**N2 — a building without the key is untouched.**

```
Serialise EmProps.dress(...) for all 30 museum tiles WITHOUT the new key,
before and after the change. Assert BYTE-IDENTICAL, including rule ids and
family order.
```

*Today:* trivially passes (nothing changed) — which is why N1 must accompany it.
*After:* must still pass, or the change is not additive.

**N3 — the truncation is visible (guards fix 6).**

```
Declare 40 prop_zones on one tile. Assert the run REPORTS 40 declared / 16
stamped / 24 refused, and that the refusal reason names `artworks`.
```

*Today:* fails — 24 zones would vanish with no record, exactly as
`endless_museum.gd:2441` prints "16 of 16 offered".

---

## OPEN

1. **Nobody has ever run `--em-white-cube` and counted props in the engine.** F4
   means every published white-cube prop number is a mirror number and the mirror
   is wrong for 8 of 30 buildings. One headless run with `--em-white-cube
   --em-first=teshima-droplet` settles it: the engine must print **0 props**; the
   mirror says 1. *(Not run — Law 2.)*
2. **F3 is a decision, not a bug.** Does Palle accept a museum with no fire
   extinguisher and no E-stop as the price of "one or two props"? If not,
   `Q["statutory"]`'s floor must rise to 2 before `props_per_10m` is ever
   defaulted on.
3. **The node census is a floor.** A real count needs one headless boot per prop
   (`get_tree().get_nodes_in_group` / recursive `MeshInstance3D` count). If the
   true mean is 25 rather than 17.6, F6's 1.37× becomes 2.0× and the props stop
   being a line item and become the frame budget.
4. Whether prop zones should be authored per tile (proposal 5) or per module with
   a tile→module binding (E6). Per tile is cheaper and reaches all 30 museums
   today; per module is what the kit already says and reaches one.
