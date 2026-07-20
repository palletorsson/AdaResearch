# The Transfer Ledger

> Palle (2026-07-20): "one important aspect is what improvements can be
> translated to other artifacts." This ledger is that aspect made operational.
> An improvement found on ONE artifact is only finished when it carries a
> **class-condition** — the test that names every other artifact it applies
> to — and has been propagated (or consciously scoped down). One entry per
> transferable improvement; status = OPEN / PROPAGATED / CLOSED.

| improvement | class-condition | reach | status |
|---|---|---|---|
| **Measured footprint → dressing room** | room `footprint` is a template default (1×1 or 6×6) AND registry has `measurements.grid_cells` | **695 rooms corrected** (cap 9, sync_footprints discipline) | PROPAGATED 2026-07-20 |
| **Measured footprint → registry** (`sync_footprints.py`) | `measurements.grid_cells` disagrees with `spatial_needs.footprint_cells` | registry-wide; 1 residual (weather_vector_field) applied | PROPAGATED (standing tool) |
| **One-scene-many-names wrapper** | any family of thin variants of one behavior (shape/mode/label differ, logic shared) — the grid stamps `artifact_lookup_name` meta before `_ready` | specimen (9) + affordance (6) families live; candidates: the 4 `*_array_demo`s, constraint fail/pass pairs | OPEN (pattern proven) |
| **PAD-plate labels (TextScreen mode 2)** | any artifact using a floating `Label3D` for its caption (the 2D-in-3D ruling) | LabelFramer class; specimen plinth uses it natively | OPEN (ruling standing) |
| **Leading-space token fix** | interactable cell where `cell != cell.lstrip()` with content | corpus swept CLEAN (10 cells, 3 maps) | CLOSED 2026-07-19 |
| **Type-taxonomy normalization** | `artifact_type`/`category` in a string-drift group | 128 entries, 13 groups → majority forms | CLOSED 2026-07-19 |
| **Family-voice conceit** | a mute artifact family sharing one substrate/idea (voice = shared conceit + per-member turn) | living_paper 28 + Gallery_ML 29 done; next: mesh (21), grab (14), step (14), profile (13), GlassRack (7), noc (7), Primitives design objects (~90) | OPEN (in progress) |
| **Integrated info kiosk** (readout + buttons in ONE housed terminal body — dark metal housing, recessed bezel screen, stencil header, ember accent stripe; no floating stat plates) | any artifact whose stats/readout text floats beside the body (BakedText/Label3D stacks positioned outside a housing) — Palle 2026-07-20: "the object interface and text has to be one very good looking interface-text body, like a sci info kiosk" | galton_board = first propagation, v2 ALL-IN-ONE cabinet (`_create_cabinet()`: the artifact IS the appliance — poster-window + service column with inset screen/keypad/vents/cap/plinth); class is large (every make_tag stats stack) | OPEN (pattern proven) |
| **Placement re-optimization** (`place.py --in-place --only-improve` + pathfinder gate) | any map whose placement predates the engines | spine complete: 269 maps, 138 improved, 0 rollbacks | PROPAGATED (re-runnable) |
| **Dressing room from template** | registered artifact with no `dressing_rooms/<lookup>.json` (viewer can't jump to it) | 15 bricolage rooms made; residual class ≈ registry minus 2,585 roomed | OPEN (generate on demand) |
| **Horizontal dialect of the kiosk ruling** (rail + inlay + flush pocket instead of back slab + standing window + overhead sign) | an artifact whose **interface plane is horizontal** — a table, deck, floor field, plinth top, board you look DOWN at. Palle 2026-07-20: *"if the interface is horizontal then the integration also need to be in that thinking, so this feature is not transferable from the vertical kiosk."* | dice_throw rebuilt (backboard deleted); class = every table/deck artifact in the corpus | OPEN (dialect proven) |

## Plane-relativity — the correction that made the ledger honest

The kiosk ruling was written as if it were plane-neutral, and it is not.
Bolting a standing backboard onto the dice table produced **two objects
pretending to be one** — the exact failure the ruling exists to prevent.

An improvement that changes *housing* is only transferable to artifacts
that share the **interface plane**. The parts translate; they do not carry:

| vertical (you face it) | horizontal (you look down at it) |
|---|---|
| back slab | broad working RAIL around the field |
| inset window / screen | readout sunk in the far rail, ~14° off the deck |
| sign band overhead | name INLAID FLAT, read by looking down |
| keypad on a wedge | keypad recessed FLUSH, face-up, pressed downward |
| maroon flank | maroon EDGE BANDING on the outer lip |
| vent slats on the back | vents in the APRON, seen from below |
| plinth / feet | apron + legs |

**Test before transferring any housing improvement:** does the artifact's
interface plane match the donor's? If not, the correct move is to write the
dialect, not to reuse the parts. A silhouette rule falls out of this: in the
horizontal dialect nothing may rise more than ~0.1 m above the deck — the
moment it does, it has become a vertical machine wearing a table.

Corollary won here: `RackTemplates.create_panel(title, rows, true)` —
`frameless` drops the white faceplate, so a milled pocket can BE the plate.
That is the horizontal answer to the standing "keypad plate is
RackTemplates-white" complaint, and it applies to any recessed control
cluster in either dialect.

## The discipline

1. When auto research (or an editor session) improves one artifact, write the
   class-condition down HERE before moving on — the improvement isn't done
   until its reach is named.
2. Propagation is measured, gated, and reversible: measured values only
   (never template→template), caps honored (footprint cap 9), pathfinder/
   capture gates where behavior could change, git as the undo.
3. The map-DNA genomes (`/map-dna`) are the class-query surface: every
   condition above is computable from manifest `config` fields, so future
   transfers start as one query over `public/map-dna/*/manifest.json`.
