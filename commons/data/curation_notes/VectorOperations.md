# VectorOperations — Curated Wall Rationale

*Sequence: forces · "Operation is relation." Three operations, three bays, each a small→large→applied micro-ladder grounded in physics.*

## The argument

The map turns arrows into operators. Its own critical text (after Whitehead): a vector
alone is a drawing; the **operations are the relations that give it sense** — dot = the
relation of *agreement*, cross = the relation of *displacement/perpendicularity*, projection
= the relation of *accountability* (how a weight is distributed across a constrained body).
The map stages this as three islands. The wall keeps that structure literally: **three bays
along +X, one per operation**, so the reading axis *is* the lesson's order
(dot → cross → projection-into-physics). Each bay climbs its own concept-map ladder rather
than shelving a flat row, so the player walks the small→large→applied progression three times
and feels the rhyme between the operations.

## Reading order (left → right)

1. **DOT · AGREEMENT** (x 0–11). Entry vocabulary on the far left — `VectorBasics` (high,
   narrow) and `basis_vectors_rig` (low, back) carry the prior map's "a vector is magnitude ×
   direction" that the artifacts.md says must anchor the scene. Then the operation climbs:
   `VectorDotProduct` (small specimen, raised high), `VectorWorkbench` (medium — "all
   operations in one frame," the synthesis bench), and the **focal centerpiece**
   `dot_product_projector` on a broad 4×4 stage set into its own depth. `dot_aligner`
   (applied — "aim·foe = mercy", the QFEP/catalyst payoff) sits forward at eye height.
2. **CROSS · PERPENDICULAR** (x 12–22). `VectorCrossProduct` small/high; `cross_product_demo`
   large on a 4×4 stage (the parallelogram you walk around); `torque_crank` applied
   (r × F you can feel) in the foreground.
3. **PROJECTION · ACCOUNTABILITY** (x 23–32). The bay that *grounds* the abstractions, as the
   summary demands: `normal_force_demo` (the ball on the slope) small/high, the medium
   `VectorProjectionReflection`, the applied `projection_shadow` ((a·n̂)n̂ as a literal
   shadow) forward, resolving into the large `vector_projection_demo` field on a 3×3 stage.

## Focal point

`dot_product_projector` (Bay 1 large, 4×4 stage at x≈9, z≈2.4, set deepest-forward of the
three stages and given the widest clear bay). Reasons: the map **opens** on the dot product
(spawn faces island 1); the critical text foregrounds it ("alignment is a chosen relation,
not a natural fact"); and projection is the *same tool* that returns in Bay 3 to decompose
gravity — so making the projector the visual anchor sets up the wall's own callback. The two
other stages are deliberately lower-key (4×4 and 3×3) so one focal point reads.

## Why each prop (size IS the argument)

- **Slim 1×1 high-narrow plinths** (`cap_inset:0.3`, `top_height` 1.30–1.42) for the small
  per-operation specimens (`VectorDotProduct`, `VectorCrossProduct`, `normal_force_demo`) and
  the two entry anchors — "what you raise high and narrow, you call precious." These are the
  ~2-cell interactive arrows; a tall podium presents one idea at reach height.
- **2×2 plinths** (`top_height` 0.9) for the genuinely 4-cell mediums (`basis_vectors_rig`,
  `VectorProjectionReflection`); a **3×2** for `VectorWorkbench` (measured 3 cells).
- **4×4 / 3×3 `station_stage`** (`step_height:0.18`, low) for the 9-cell walk-up larges
  (`dot_product_projector`, `cross_product_demo`, `vector_projection_demo`) — "what you set
  low and broad, you call a world." Stages get a `name_plate`; the player steps up to them.
- **2×1 plinths** (`top_height` 1.0–1.05) for the applied operations-toys (`dot_aligner`,
  `torque_crank`, `projection_shadow`) — they're ~2-cell embodied consoles, set forward as
  foreground accents so the applied tier reads as "the operation doing a real job."

## Labels (2D-in-3D, no floating text)

Every plinth's `caption_text` = the artifact's display name (plinth renders it as a framed,
surface-pinned plate). Each stage carries the name on its `name_plate`. Three **`station_panel`**
wall headers (2D-in-3D, mounted at z≈0.06, y≈2.55) caption each bay with the map's own
truth-beats: "A·B = |A||B| cosθ / ALIGNMENT IS A NUMBER", "A×B RISES OUT / RIGHT-HAND RULE",
"A = proj + reject / GRAVITY ON A SLOPE". The editor hides each artifact's Label3D, so these
plates are the only text.

## The 3D composition (not a flat row)

Depth `z` spans **0.6 → 3.4 m** and height staggers by tier, so orbiting the free-cam rewards
you with real foreground/background, not a shelf:
- **Foreground** (z≈0.6–1.0): the applied toys + the synthesis bench, at eye/hand height.
- **Mid** (z≈1.3): the medium decomposition pieces.
- **Background** (z≈3.0–3.4): the small specimens raised **high+narrow**, and the low entry
  rig — a back wall of tall thin podiums.
- Each **large stage sits at its own depth** (z≈2.4) in the right half of its bay, broad and
  low, with a clear footprint and deliberate negative space around it.
It still reads strictly left→right from the iso front (dot → cross → projection), but each bay
is a little alcove with a thing set forward and specimens set behind.

## Prop gaps flagged

- **`normal_force_demo` is sub-1 m in plan** (measured AABB 0.35 × 1.18 × 0.35 — a tall thin
  stalk). Even the slim 1×1 plinth's 1 m foot is wider than the artifact. Used the slim 1×1
  per the brief, but this wants a **future micro-pedestal** (~0.5 m foot, tall) for genuinely
  pole-like artifacts; the same gap will recur for any thin vertical demo.
- **No applied-tier pedestal variant**: the three applied toys are presented on the same 2×1
  plinth as small specimens. A distinct "console" base (lower, wider, with a control-lip
  read) would let the *applied* tier announce itself by prop shape, not just position.

## What to try next

- **Capture** the wall (`capture_multi_angle.gd --mode=...`) and check the focal read — if the
  three stages compete, drop `cross_product_demo`/`vector_projection_demo` step_height or pull
  them slightly deeper so `dot_product_projector` clearly wins.
- Consider promoting the two **walk-inside XL** exhibits (`vector_dot_product_xl`,
  `vector_cross_product_xl`) once they expose a direct scene — they are the concept-map's true
  `large` tier and would let a player *stand inside* the operation rather than view it on a
  stage. They were skipped here only because they are delegate artifacts with no direct
  `scene` field (the brief requires registry-known tokens that have a scene).
- The map's own listed **gap** (a vector-reflection demo tying the cross-product normal to a
  mirror plane) would slot cleanly as a 4th piece in Bay 3, completing projection↔reflection.

---

### Baseline beaten

The current `spine_walls.json` entry is a **flat z = 0.8 line** of plinths/stages marching
across +X, with `proximity_spawner` (gameplay scaffolding, not a teaching artifact) given its
own pedestal and **applied = 0**. This curation: clusters by operation, uses the full depth
(0.6–3.4 m) and height range, sizes every base to the artifact's real footprint, captions
each with a 2D-in-3D plate, adds the missing **applied tier** (the three embodied
operations-toys), and drops the spawner. Counts: small 4 / medium 3 / large 3 / applied 3.
