# Transformation — Curriculum Audit

**Sequence ID:** `transformation`
**Spine order:** 3 (follows primitives, vectors; unlocks fractals, proceduralgeneration)
**Maps:** 8 (Trans_Introduction, Trans_Translation, Trans_AxisDecomposition, Trans_Rotation, Trans_RotationSpectacle, Trans_Scale, Trans_Pit, Chamber_Transformation)
**Source:** `commons/maps/sequences/transformation.json`
**Truth:** *"Identity preserved under transformation. What stays the same when everything changes?"*
**Formula:** `T(v) = M × v`, where M is a 4×4 matrix encoding translate, rotate, scale.
**Evolutions written:** 0 (blurb/intent exist for all 7 non-chamber maps plus Chamber_Transformation)

## 1. Core Concept

Affine transformation in 3D space — the grammar by which shape moves through the world without losing itself. The sequence teaches three elementary operations (translate, rotate, scale), the 4×4 matrix that encodes them, the fact that composition is non-commutative, and the deeper lesson that every transformation is defined by what it *cannot* touch. Transformation is where geometry stops being a noun and becomes a verb. What remains constant — orientation, angle, proportion, topology — is the fingerprint of the transform. This is also the first sequence where the body is the object of transformation, not just the observer: the player gets pushed, swept, pressured, shrunk, scaled.

## 2. The Red Thread

1. **Three Strategies for Closing a Gap** (Trans_Introduction)
   - Three cubes demonstrate translate / rotate / scale as three ways to bridge the same void
   - Captures: transformation as choice, invariance as fingerprint (each op preserves what the others discard)
   - Leaks: no single-axis decomposition, no matrix representation, no composition

2. **Translation as Displacement** (Trans_Translation)
   - Position changes, orientation and scale do not. `P' = P + t`
   - Captures: pure displacement, navigational infrastructure, translation as additive group action
   - Leaks: no axis-decomposition, no inverse translation, no group-theoretic framing

3. **Axis Decomposition** (Trans_AxisDecomposition)
   - Translation factored into independent X, Y, Z components
   - Captures: orthogonality, coordinate system as the skeleton of displacement, Descartes made literal
   - Leaks: still only translation — rotation and scale don't decompose so cleanly along axes

4. **Rotation and Non-Commutativity** (Trans_Rotation)
   - `R1·R2 ≠ R2·R1`. Order matters. Space has directional grain.
   - Captures: anisotropy, first encounter with non-abelian algebra, orientation as state
   - Leaks: no explicit matrix; no quaternion hint; no gimbal-lock preview

5. **Rotation as Spectacle / Layered Rotation** (Trans_RotationSpectacle)
   - Continuous, layered angular velocities at architectural scale. `ω_i = ω_0 · m^i`.
   - Captures: rotation as temporal experience, compound rotation, rotation as spatial carving (boolean tunnel)
   - Leaks: layers look cosmological but no explanation of orbital mechanics, no connection to waves

6. **Scale as Relational Change** (Trans_Scale)
   - `v' = S · v`. Proportion survives. Size is comparative.
   - Captures: uniform scaling, reference geometry, the learner as agent of transformation (`scale_me`)
   - Leaks: non-uniform scale barely addressed; shear is absent; no negative scale / reflection

7. **Transformation as Violence** (Trans_Pit)
   - Push (translate) / sweep (rotate) / pressure (scale) — the three ops applied to the player's body
   - Captures: embodied meaning of each op, death as feedback signal, transformation of inhabited space
   - Leaks: no composition of the three into one puzzle; no representation layer

8. **Synthesis — The Catalyst Chamber** (Chamber_Transformation)
   - Shrink ray folds a miura_crawler flat without killing it
   - Captures: transformation as non-destructive change; player-creature boundary dissolves; first creature encounter
   - Leaks: rest of the sequence's matrix machinery is invisible here; the chamber is more phenomenological than algebraic

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | Trans_Introduction | Three strategies | invariants_demo + balance_puzzle + matrix_4x4_viewer + homogeneous_coordinates + rotation_gimbal + transform_composition | Rich — probably too rich; see gap analysis |
| 2 | Trans_Translation | Translation | y_translation_cube + z_translation_cube + player_trace + pickup_gate | Clean |
| 3 | Trans_AxisDecomposition | Axis independence | x_translation_cube + z_translation_cube + translation_cube_demo + toruscylinder | Redundant with map 2 |
| 4 | Trans_Rotation | Rotation, non-commutativity | rotate_grid_cubes + spin | Missing evolution |
| 5 | Trans_RotationSpectacle | Layered rotation | carousel_cake + boolean_tunnel + righttriangle | Missing evolution |
| 6 | Trans_Scale | Scale | scale_me + prism_block + chair_assembly_puzzle + clipboard (vr_scale_controls) | Missing evolution |
| 7 | Trans_Pit | Transformation as violence | pusher_block + sweeper_block + grower_block | Not listed in sequence content string but in `maps[]` |
| 8 | Chamber_Transformation | Synthesis | becoming_catalyst (transformation mode) + miura_crawler spawner + catalyst_target | Missing evolution |

**Note:** `Trans_Pit` appears in `maps[]` but is absent from both `content[]` and `artifact_groups[]` in `transformation.json`. `Chamber_Transformation` appears in `maps[]` but has no `artifact_groups` entry. Both are live maps with real content — they need to be lifted into the sequence manifest.

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Three-strategy compare | invariants_demo | algorithms/transforms/invariants/invariants_demo.gd | ✓ @identity rich; "what survives defines the transform" |
| Matrix representation | matrix_4x4_viewer | algorithms/transforms/matrix_viewer/matrix_4x4_viewer.gd | ✓ @identity rich; slide T/R/S → 16 numbers |
| Homogeneous coords | homogeneous_coordinates | commons/artifacts/homogeneous_coordinates/homogeneous_coordinates.gd | ✓ exists; **no @identity block found** |
| Gimbal | rotation_gimbal | commons/artifacts/rotation_gimbal/rotation_gimbal.gd | ✓ exists; **no @identity block found** |
| Composition | transform_composition | commons/artifacts/transform_composition/transform_composition.gd | ✓ exists; **no @identity block found** |
| Balance puzzle | balance_puzzle | (procgen registry) | ✓ exists in registry |
| Constant reference | dark_sphere | (substrate/primitives) | ✓ appears on every map — the visual invariant anchor |
| Axis translation | axis_translation_cube (shared script for x/y/z) | commons/artifacts/axis_translation_cube/axis_translation_cube.gd | ✓ @identity rich; VR speed slider, trail ghosts |
| Axis demo | translation_cube_demo | commons/primitives/translation/translation_cube_demo.gd | ✓ |
| Non-rectilinear reference | toruscylinder | algorithms/transformation/toruscylinder/toruscylinder.gd | ✓ |
| Constrained door (axis) | constrained_door | commons/primitives/translation/constrained_door.gd | ✓ exists, **unused** by any sequence map |
| Axis slider | axis_slider | commons/primitives/translation/axis_slider.gd | ✓ exists, **unused** |
| Translation demo umbrella | translation_demo | commons/primitives/translation/translation_demo.gd | ✓ exists, **unused** |
| Non-commutative rotation | rotate_grid_cubes | — artifact script not located under a single file; registry entry at `randomness.json:6921` | ⚠ plan doc exists (`doc/plans/artifacts/rotate_grid_cubes.md`) — may be a planned/incomplete artifact |
| Discrete→continuous rotation | spin | algorithms/transformation/spin/spin.gd | ✓ @identity: "translation then rotation ≠ rotation then translation" |
| Layered rotation | carousel_cake | algorithms/transformation/carousel_cake/carousel_cake.gd | ✓ @identity; geometric progression of angular velocities |
| Rotation-carved geometry | boolean_tunnel | algorithms/transformation/booleanTunnel/booleanTunnel.gd | ✓ @identity; accumulated rotation carves tunnel |
| Geometric reference | righttriangle | (primitives) | ✓ callback to primitives sequence |
| Uniform scale (body) | scale_me | algorithms/primitives/scaleme/scale_me.gd | ✓ @identity; world-scale pickup; "scale is relational" |
| Reference geometry | prism_block | (primitives) | ✓ callback |
| Scale constraint puzzle | chair_assembly_puzzle | (furniture composer) | ✓ unusual — furniture asset used as scale-matching puzzle |
| VR scale controls | clipboard (vr_scale_controls) | (interactables) | ✓ parametric slider for scale |
| Pusher (translate→death) | pusher_block | commons/hazards/transformation_blocks/pusher_block.gd | ✓ @identity; "translation is the simplest transformation and the most dangerous" |
| Sweeper (rotate→death) | sweeper_block | commons/hazards/transformation_blocks/sweeper_block.gd | ✓ exists; Trans_Pit intent calls it `revolving_wall` — name mismatch |
| Grower (scale→death) | grower_block | commons/hazards/transformation_blocks/grower_block.gd | ✓ exists |
| Catalyst chamber anchor | becoming_catalyst (transformation mode) | commons/hazards/becoming_catalyst/ | ✓ |
| Creature spawner | proximity_spawner (miura_crawler) | (nature_system) | ✓ first folding creature encounter |

### Artifacts That Exist But Are NOT Placed

- `constrained_door.gd`, `axis_slider.gd`, `translation_demo.gd` — sitting in `commons/primitives/translation/` unused
- `rotation_gimbal`, `homogeneous_coordinates`, `transform_composition` — all three are *only* in Trans_Introduction. They carry the matrix/algebra layer and never reappear in maps 2-8 where their ideas actually get used.

## 5. Gap Analysis

### Ordering Issues (the big one)

**Trans_AxisDecomposition is redundant with Trans_Translation.** Both maps are about translation. Trans_Translation already uses axis-constrained transport cubes (`y_translation_cube`, `z_translation_cube`). Trans_AxisDecomposition adds `x_translation_cube` and `translation_cube_demo` but the conceptual difference is thin — the first map teaches "translation as infrastructure," the second teaches "translation is decomposable into axes." In practice the player walks through two translation maps before seeing a rotation. This breaks pacing.

Three possible fixes (ordered by disruption):

1. **Merge** Trans_Translation + Trans_AxisDecomposition into one map. Use the axis-decomposition content as the "teaching" phase of the combined map. Drop Trans_AxisDecomposition from the sequence.
2. **Repurpose** Trans_AxisDecomposition to cover decomposition for *all three* transformations (translate axes, rotation axes, scale axes). That earns its place.
3. **Keep** but insert a strong explicit bridge: Trans_Translation = "what translation does," Trans_AxisDecomposition = "what translation is made of."

### Matrix Representation Is Front-Loaded and Then Vanishes

Trans_Introduction places all the matrix-algebra artifacts — `matrix_4x4_viewer`, `homogeneous_coordinates`, `rotation_gimbal`, `transform_composition`, `invariants_demo` — in the *first* map before the player has seen any single transformation in isolation. The downstream maps (2–7) teach the three operations viscerally and then the matrix layer never returns. The learner meets the 4×4 matrix at the moment they have least context to read it.

Proposed fix: move `matrix_4x4_viewer` into Trans_Scale (the synthesis map) as a "here is what you just learned, expressed numerically" moment. Leave `invariants_demo` in Trans_Introduction as the concept-setter. Consider a dedicated Trans_Composition map (stub exists at `commons/maps/Trans_Composition/map_data.json`) to host `transform_composition` and `homogeneous_coordinates` as the algebraic finale.

### Missing Concepts

- **Non-commutativity, explicit**: Trans_Rotation's own intent file flags this gap — *"side-by-side comparison showing the same two rotations applied in both orders would make non-commutativity undeniable rather than discovered."* A `rotation_order_compare` artifact would close this.
- **Shear and reflection**: `invariants_demo` includes SHEAR as a button but no map teaches it. Shear is the operation that preserves nothing — the pedagogical foil to translation/rotation/scale. Reflection (negative scale) similarly absent.
- **Inverse transformation**: Nothing in the sequence shows that every transformation has an inverse. Key to the group-theoretic framing the truth statement gestures at.
- **Identity transformation**: The `I` matrix is mentioned in `matrix_4x4_viewer` identity but has no artifact of its own. Conceptually important — "the transformation that does nothing" grounds everything else.

### Missing Maps

- **Trans_Composition** — the folder `commons/maps/Trans_Composition/` exists with a `map_data.json` but the sequence JSON does not include it in `maps[]`. The map would be the natural home for `transform_composition` and the order-matters lesson. Decide: promote this map into the sequence, or delete the orphan folder.
- **Trans_Rotation_2_** — also an orphan folder (note the trailing underscore — looks like draft/debug).

### Orphan Artifacts (Exist But Unplaced)

- `constrained_door.gd`, `axis_slider.gd`, `translation_demo.gd` in `commons/primitives/translation/`
- `rotate_grid_cubes` appears in map_data but has only a plan doc — verify whether the artifact is actually implemented or still planned

### Name / Reference Mismatches

- Trans_Pit intent.md refers to `revolving_wall`, but the actual artifact placed via sequence grammar is `sweeper_block`. Pick one name.
- `transformation.json` `content[]` lists only 6 maps while `maps[]` lists 8. `Trans_Pit` and `Chamber_Transformation` are missing from the content descriptions. The `artifact_groups[]` array is missing entries for those two maps entirely.
- Chamber_Transformation uses `becoming_catalyst#start_mode:transformation` — confirm this mode exists in the catalyst bracelet's mode enum.

### Documentation Status

All 7 non-chamber maps have blurb.md and intent.md. Chamber_Transformation has blurb.md + intent.md. **No map has an evolution** (technical.md / critical.md / summary.md). This sequence is at pipeline stage 2 (Documentation) — ready for stage 3–7 work. Primitives by contrast has 3 evolutions; transformation has 0.

## 6. Forward Leaks

Concepts this sequence raises but cannot fully hold:

- **Group theory** → Graph theory / Algebra sequence. Non-commutativity, inverses, the identity element all scream "group" but the word is never used.
- **Lie groups / continuous rotation** → Wavefunctions (rotation as angular frequency), Forces (angular momentum)
- **Quaternions / gimbal lock** → would need its own chamber; `rotation_gimbal` hints at it
- **Non-affine transforms (projective, conformal)** → later geometry sequence; the perspective-lines artifact from primitives is the dangling thread
- **Fractal self-similarity under scale** → Fractals sequence (explicit unlock target)
- **Procedural transformation as grammar** → Procedural Generation sequence (explicit unlock target)
- **Conservation under transformation → Noether-style invariants** → Forces / QFEP
- **Folding as transformation** → Folding Creature System (miura_crawler in the chamber is the first hint — fold is the transformation that is neither translate, rotate, nor scale)
- **Color transformation** → Color sequence (Trans_Scale's intent explicitly says it "leads outward to the Color sequence, where transformations move from geometric to perceptual")
- **Time-parameterized transformation** → Wavefunctions, Animation
- **Transformation of the observer** → QFEP (the chamber hints: "the catalyst transforms the player-creature boundary")

## 7. Proposed Ordering

Two options. The first is conservative (keeps all existing maps); the second is bolder.

### Conservative — reshuffle only

```
1. Trans_Introduction       — three strategies; keep invariants_demo, drop matrix machinery
2. Trans_Translation        — translation as infrastructure (absorb axis decomposition)
3. Trans_Rotation           — non-commutativity (add rotation_order_compare artifact)
4. Trans_RotationSpectacle  — layered rotation, rotation as spatial carving
5. Trans_Scale              — scale + matrix_4x4_viewer moved here as synthesis
6. Trans_Composition*       — promote orphan folder; home for transform_composition, homogeneous_coordinates
7. Trans_Pit                — embodied transformation / challenge map
8. Chamber_Transformation   — synthesis, creature encounter, catalyst
```

Changes: drop Trans_AxisDecomposition (merge into Trans_Translation), promote Trans_Composition, reorder matrix_4x4_viewer to map 5, add a non-commutativity compare artifact to map 3.

### Bolder — teach one transform completely before the next

```
1. Trans_Introduction
2. Trans_Translation        (includes axis decomposition as teaching phase)
3. Trans_Rotation           (discrete grid + continuous spin + side-by-side non-commutativity)
4. Trans_Scale              (uniform + non-uniform + negative)
5. Trans_Composition        (the 4×4 matrix as the object that holds all three)
6. Trans_Pit                (body as object of the three ops)
7. Chamber_Transformation   (fold as the transform that is none of the above)
```

Changes: absorb Trans_AxisDecomposition and Trans_RotationSpectacle into the core triplet maps rather than as separate stops. Promote Trans_Composition. RotationSpectacle content (carousel_cake, boolean_tunnel) becomes the exploration phase of Trans_Rotation.

## Summary

Transformation is a solid middle-of-the-road sequence. The concept flow is clean from translation → rotation → scale → composition, and the Chamber successfully pays off the truth statement. Six of seven non-chamber maps have blurb + intent. Artifacts are plentiful (20+) and many carry @identity blocks (`invariants_demo`, `matrix_4x4_viewer`, `axis_translation_cube`, `spin`, `carousel_cake`, `booleanTunnel`, `scale_me`, `pusher_block`). The main structural problems are:

1. **Two translation maps in a row** (Trans_Translation + Trans_AxisDecomposition) break pacing without adding distinct concepts. Merge or repurpose.
2. **Matrix machinery is dumped in the intro** where the player has no context; it should be the synthesis, not the preamble. `matrix_4x4_viewer`, `homogeneous_coordinates`, `transform_composition` appear once and never return.
3. **Trans_Composition map exists as an orphan** — promote or delete.
4. **Non-commutativity needs an explicit compare artifact** (the Trans_Rotation intent says so itself).
5. **`Trans_Pit` and `Chamber_Transformation` are missing from `transformation.json` `content[]` and `artifact_groups[]`** even though both maps are live.
6. **Zero evolutions written.** The sequence is at pipeline stage 2; all subsequent work (stages 3–7) is untouched.

The Chamber is well-sited: folding (miura_crawler) is precisely the transformation that lives outside the affine T/R/S triad the sequence just taught. It's the productive outside.
