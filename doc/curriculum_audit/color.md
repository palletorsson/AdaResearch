# Color — Curriculum Audit

**Sequence ID:** `color`
**Name:** Color: Perception, Not Physics
**Spine layer:** properties
**QFEP term:** S (system state)
**Prerequisites:** primitives
**Unlocks:** proceduralgeneration, machinelearning
**Maps (active):** 8 (7 content maps + Chamber_Color)
**Maps (deferred):** 5 (Color_Context, Color_Grabbable, Color_Overlay, Color_Spectrum, Color_Sphere)
**Evolutions written:** 0

Source files:
- `commons/maps/sequences/color.json`
- `commons/maps/Color_*/` and `commons/maps/Chamber_Color/`
- `algorithms/color/` (21 sub-systems)
- `commons/artifacts/registry/color.json`

## 1. Core Concept

Color is perception, not physics. RGB is a lie we agree on — a three-number convention that stands in for a phenomenon the eye constructs from context, illumination, and neighboring fields. The sequence teaches color as a *system state* (the `S` term in QFEP): wavelength is the objective input, but the experience of color only exists when light, surface, and observer meet. Each map dismantles one assumption about color — that it belongs to an object, that it is a discrete name, that it is a wavelength, that it is a selectable RGB triple — and replaces it with a relational account. The arc moves from **selection** (picking color from a menu) through **systematization** (color as data), through **continuity** (color as spectrum), through **mixing** (color as process), through **application** (color as gesture), to **dissolution** (color as gradient) and finally **contingency** (color vanishes in darkness).

## 2. The Red Thread

1. **Selection** (Color_Nails)
   - Color as something you choose and apply to a surface — the first act of digital self-authorship
   - Captures: RGB navigation, color as property, color as personal decoration
   - Leaks: the gap between the RGB value chosen and the perceptual experience of that value

2. **Systematization** (Color_Grid_Pallet)
   - Color as addressable data — `(row, col) → (r, g, b)` mapped across a grid
   - Captures: color as information architecture, palette as vocabulary, quantization
   - Leaks: the smoothness we perceive is discretized; lighting context is ignored

3. **Spectrum / Continuity** (Color_Rainbow)
   - The visible spectrum stretched into architecture — Newton's prism as a corridor
   - Captures: hue as a continuous field, HSV cycling, color as duration
   - Leaks: spectrum is 1D; it cannot hold saturation, value, or perceived mixture

4. **Mixing / Process** (Color_Pillar)
   - Color as gathered, mixed, and analyzed — additive vs subtractive made tangible
   - Captures: primary combination, spectrum analysis, color as portable object
   - Leaks: mixing on paper and mixing in light obey different rules — the physics/perception gap

5. **Gesture / Application** (Color_Paint)
   - Color as action — paint thrown, splashed, accumulated; Albers' studies formalize perceptual relativity
   - Captures: color as verb, context-dependence (same swatch on different grounds looks different)
   - Leaks: the connection between paint-physics and Albers-perception is implicit, not demonstrated

6. **Gradient / Dissolution** (Color_Walls)
   - Continuous interpolation across surfaces — the unnamed territory between named hues
   - Captures: perceptual continuity, smooth HSV, the failure of categorical language
   - Leaks: why the brain *does* categorize — the neuroscience of color naming

7. **Contingency / Illumination** (Color_Flashlight)
   - Color as event, not property — remove light and it disappears; different spectra can produce identical percepts
   - Captures: metamerism, color constancy, illumination dependency, the S-term thesis
   - Leaks: what happens when illumination is the whole game — points forward to Wavefunctions

8. **Chamber** (Chamber_Color)
   - Color as communication — hue triggers creature response; the catalyst becomes chromatic
   - Captures: synthesis, color as relation-signal, creature-color pairing
   - Leaks: transitions to next sequences (proceduralgeneration, machinelearning)

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | Color_Nails | Selection / digital self-authorship | nail_color_controller | Docs complete, no evolution |
| 2 | Color_Grid_Pallet | Systematization / color as data | gridcolorizer | Docs complete, no evolution |
| 3 | Color_Rainbow | Spectrum / continuity | rainbow | Docs complete, no evolution |
| 4 | Color_Pillar | Mixing / process | visual_color_mixing + SpectrumVisualizer | Docs complete, no evolution |
| 5 | Color_Paint | Gesture / application | ball_painting_demo + albers_wall_gallery | Docs complete, no evolution |
| 6 | Color_Walls | Gradient / dissolution | rainbow_hallway + color_constellation_office | Docs complete, no evolution |
| 7 | Color_Flashlight | Contingency / illumination | flashlight_demo | Docs complete, no evolution |
| 8 | Chamber_Color | Chamber / synthesis | becoming_catalyst + kaleidocycle_enemy | Thin intent/blurb, no evolution |

The sequence order already matches the concept flow — selection → systematize → continuum → mix → gesture → dissolve → strip away → synthesize. This is one of the cleanest arcs in the spine.

## 4. Artifact Inventory

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Selection (RGB sliders on body) | nail_color_controller | `commons/interfaces/nail_color_controller.gd` | @identity ✓, needs palette picker |
| Selection (hand target) | hand_color_controller | `commons/interfaces/hand_color_controller.tscn` | ✓ |
| Selection (scanner) | grab_stick_scanner | `algorithms/color/color_scanner/grab_stick_scanner.tscn` | ✓ |
| Selection (palette balls) | colorballs | `algorithms/color/colorballs/colorballs.gd` | @identity ✓ |
| Spectral foreshadow | dark_side_prism | `algorithms/color/dark_side_prism.gd` | @identity ✓, needs Label3D + VR prism angle |
| Systematization | gridcolorizer | `algorithms/color/gridcolorizer/gridcolorizer.gd` | @identity ✓, needs VR pattern selector |
| Systematization (3D lift) | spectrum_forest | `algorithms/color/spectrumforest/spectrum_forest.gd` | @identity ✓ |
| Spectrum corridor | rainbow | (wavefunctions registry — path TBD) | Needs interactive angle, Label3D |
| Spectrum samples | mario_cube, pick_up_cube | `commons/artifacts/mario_cube/...`, `commons/scenes/mapobjects/pick_up_cube.tscn` | ✓ |
| Mixing (additive) | visual_color_mixing | `algorithms/color/color_mixing/visual_color_mixing.tscn` | ✓ (no @identity yet) |
| Mixing (spatial) | pillarcolorcollection | `algorithms/color/pillarcolorcollection/pillarcolorcollection.gd` | @identity ✓, needs VR palette selector + Label3D |
| Mixing (analytical) | SpectrumVisualizer | `algorithms/color/spectrum_visualizer/SpectrumVisualizer.gd` | @identity ✓, needs Label3D, VR scrub, wavelength labels |
| Palette library (grabbable) | color_sets_overview | `algorithms/color/grabcolor/color_sets_overview.gd` | @identity ✓ |
| Rainbow stick (portable color) | grab_rainbow_stick | (registry) | ✓ |
| Gesture (painting) | ball_painting_demo | `commons/context/drawingboard/ball_painting_demo_v2.tscn` | No @identity |
| Perceptual theory | albers_wall_gallery | `algorithms/primitives/homagetothesquare/albers_wall_gallery.gd` | @identity ✓, needs interactive palette tuning |
| Gradient / dissolution | rainbow_hallway | `algorithms/wavefunctions/rainbow_hallway/rainbow_hallway.gd` | No @identity |
| Color-as-space | color_constellation_office | `algorithms/color/color_mixing/color_constellation_office.gd` | @identity ✓, needs interactive wall rotation |
| Contingency / light | flashlight_demo | `algorithms/postprocessing/flashlight_demo/flashlight_demo.tscn` | No @identity |
| Control surface | dark_sphere | (all 7 maps) | ✓, acts as constant surface |
| Chamber catalyst | becoming_catalyst (chromatic mode) | `commons/hazards/becoming_catalyst/` | ✓ |
| Chamber creature | kaleidocycle_enemy | (nature/hazards) | ✓ |
| Latent: perception | SimultaneousContrast | `algorithms/color/simultaneous_contrast/SimultaneousContrast.gd` | No @identity — NOT PLACED IN ANY MAP |
| Latent: metamerism | MetamerismLab | `algorithms/color/metamerism_lab/MetamerismLab.gd` | No @identity — NOT PLACED IN ANY MAP |
| Latent: RGB mechanics | subpixel_display | `algorithms/color/subpixel_display/subpixel_display.gd` | @identity ✓ — NOT PLACED IN ANY MAP |
| Latent: interpolation space | gradient_interpolator | `algorithms/color/gradient_interpolator/gradient_interpolator.gd` | @identity ✓ — NOT PLACED IN ANY MAP |
| Latent: palette-as-wall | brick_wall_factory | `algorithms/color/brick_wall_factory/brick_wall_factory.gd` | @identity ✓, placed in Color_Nails only |
| Latent: color_scanner | color_scanner.tscn | `algorithms/color/color_scanner/` | Only grab_stick variant placed |
| Latent: color_mixing (base) | color_mixing.gd | `algorithms/color/color_mixing/color_mixing.gd` | No @identity |
| Latent: colorsheets | colorsheets.gd | `algorithms/color/colorsheets/` | No @identity, unplaced |
| Latent: colortrails | colortrails.gd | `algorithms/color/colortrails/` | No @identity, unplaced |
| Latent: colorspaces | colorcheckerfloor, colortruchetfloor | `algorithms/color/colorspaces/` | Unplaced |
| Latent: k_means_color | k_means_color.gd | `algorithms/color/k_means_color/` | Unplaced |
| Latent: color_display_disk | color_display_disk.gd | `algorithms/color/color_mixing/` | Unplaced |

**Richness of algorithms vs placement:** `algorithms/color/` contains 21+ subsystems, but only ~12 are placed in the 7 active maps. Three of the strongest perception-teaching artifacts (**SimultaneousContrast**, **MetamerismLab**, **subpixel_display**) are built but never encountered by the player.

## 5. Gap Analysis

### Missing Concept Coverage (High Priority)

- **Simultaneous contrast** as a first-class station. The Albers wall gallery gestures at it, but the dedicated `SimultaneousContrast.gd` artifact is built and unused. The sequence *truth* ("what you see depends on context") is underdemonstrated without it.
- **Metamerism** — the strongest proof of "color is not wavelength." `MetamerismLab.gd` exists. The Color_Flashlight intent even calls this out as a gap ("side-by-side showing the same object under different illuminants"). The lab should live in Color_Flashlight or a dedicated slot.
- **Subpixel / additive mechanism** — `subpixel_display.gd` has a strong @identity ("every pixel is three tiny lights pretending to be one color") but is unplaced. It is the missing bridge between *RGB-as-convention* and *RGB-as-hardware*.
- **Color-space path-dependence** — `gradient_interpolator.gd` teaches that RGB and HSV produce different paths between the same endpoints. Critical for the "RGB is a lie" thesis. Unplaced. Natural fit: Color_Walls or between Color_Pillar and Color_Paint.
- **Color constancy** — mentioned in learning objectives, but no artifact demonstrates it. An object's apparent color staying stable under changing illumination would complete the Flashlight story.

### Missing Map-Level Artifacts

- **Chamber_Color** has the thinnest documentation (no critical.md, no summary.md, no technical.md). The catalyst-creature loop is asserted but not anchored by an artifact that demonstrates the "each hue triggers a different response" claim.
- **Color_Flashlight** has only `flashlight_demo` + `dark_sphere`. It is the thesis map and the gate map — it deserves MetamerismLab, a second-illuminant station, and a constancy demo.
- **Color_Paint** has only three interactables (ball_painting_demo, albers_wall_gallery, dark_sphere). Its own intent.md flags the missing bridge between paint-physics and Albers-perception.

### Missing @identity Blocks

These artifacts lack the `@identity` header block that the project uses for garden listener / identity queries:
- `ball_painting_demo` — centerpiece of Color_Paint
- `rainbow_hallway` — centerpiece of Color_Walls
- `flashlight_demo` — centerpiece of Color_Flashlight
- `visual_color_mixing` — core of Color_Pillar mixing story
- `color_mixing.gd` (base)
- `SimultaneousContrast`, `MetamerismLab` — the two most theoretically loaded perception artifacts

Without @identity, these do not surface in `tools/query_identities.py truths` and cannot contribute to the sequence's truth chain.

### Ordering

Current order is correct. No reordering needed. The one structural oddity is that **Color_Grid_Pallet** (systematization) sits between two highly embodied maps (Nails → Rainbow); this is deliberate and works, but the transition from grid-as-data back to spectrum-as-walk would benefit from an intent hand-off line.

### Missing Transitions

- **Color_Nails → Color_Grid_Pallet:** personal color → systematic color. `dark_side_prism` foreshadows the spectrum arriving in map 3, but there's no artifact that bridges "color on me" to "color as data." `subpixel_display` could live here.
- **Color_Pillar → Color_Paint:** analytical mixing → gestural mixing. `gradient_interpolator` (path through color space) is a natural bridge.
- **Color_Walls → Color_Flashlight:** continuous field → contingent event. `SimultaneousContrast` is the hinge — it shows that even the continuous field is an interpretation.

### Redundancies / Consolidation

- `colorballs`, `grab_rainbow_stick`, `color_sticker`, `color_sets_overview` all do variations of "grabbable color sample." Useful for variety, but Color_Nails + Color_Pillar both lean on scattered-palette-objects. Consider differentiating by act (decorate in Nails, measure in Pillar).
- `Color_Context` (deferred) was a 30-artifact showcase. Correct to defer — it collapses the pedagogical arc into a sampler platter. Keep deferred.

## 6. Forward Leaks

Concepts this sequence raises but cannot fully hold:

- **Wavelength physics / EM spectrum** → Wavefunctions (sine waves, frequency, the physical basis `rainbow` and `rainbow_hallway` already borrow from)
- **Color constancy as neural inference** → Neuralnetworks, neuroscience sequences
- **Clustering in color space (k-means)** → `k_means_color.gd` exists but belongs in Machinelearning
- **Procedural palettes / color grammars** → Proceduralgeneration (named as next unlock)
- **Color shader math / HSV/HSL/LAB transforms** → Shaders / Postprocessing
- **Cultural / political meanings of color** — not addressed here; belongs to a later semiotic or critical-theory touchpoint (none currently planned in spine)
- **Color in motion (afterimages, flicker fusion)** — Oscillation / wavefunctions
- **Diffraction and structural color** — Wavefunctions
- **Color as signal in creatures** — Chamber_Color opens this door; full treatment in nature_system / ecology

## 7. Proposed Ordering

Current order is sound. Keep it:

```
1. Color_Nails         — selection, personal color, RGB navigation on a body
2. Color_Grid_Pallet   — systematization, color as addressable data
3. Color_Rainbow       — spectrum as architecture, continuity
4. Color_Pillar        — mixing, analysis, portable color
5. Color_Paint         — gesture, application, Albers theory
6. Color_Walls         — gradient, dissolution, named boundaries fail
7. Color_Flashlight    — contingency, illumination, S-term thesis (GATE)
8. Chamber_Color       — synthesis, catalyst, creature-color communication
```

### Recommended insertions (without changing map count)

Place the unused perception artifacts into existing maps:

- **Color_Nails:** add `subpixel_display` as a side station — the RGB sliders the player just used are "three tiny lights pretending to be one color."
- **Color_Pillar:** add `gradient_interpolator` — the same two colors, two different paths. Makes mixing *space-dependent*.
- **Color_Paint:** add `SimultaneousContrast` — promotes the Albers theme from "one gallery wall" to "explicit perception station." Closes the intent.md gap its author flagged.
- **Color_Flashlight:** add `MetamerismLab` and a color-constancy demo — the gate map deserves its strongest artifacts.
- **Chamber_Color:** add a science-screen artifact that plots creature response curves against hue input — makes the "each hue triggers a different response" claim legible.

### Recommended @identity backfill

Add `@identity` blocks to: `ball_painting_demo`, `rainbow_hallway`, `flashlight_demo`, `visual_color_mixing`, `color_mixing`, `SimultaneousContrast`, `MetamerismLab`. All are core teaching artifacts in the sequence; their absence from the garden listener is a tracked gap.

## Summary

Color is a narratively strong, well-documented sequence with a crisp conceptual arc (selection → systematize → continuum → mix → gesture → dissolve → strip away → synthesize) that already matches map order. The `algorithms/color/` directory is unusually rich — ~21 subsystems — but **roughly a third of the strongest perception artifacts (SimultaneousContrast, MetamerismLab, subpixel_display, gradient_interpolator) are built yet unplaced**, which weakens the thesis map (Color_Flashlight) and the theoretical bridge in Color_Paint. The three priority moves:

1. **Place the unused perception artifacts** into Color_Flashlight (metamerism + constancy) and Color_Paint (simultaneous contrast). This alone would lift the sequence from "good" to "canonical."
2. **Add missing @identity blocks** to the seven centerpiece artifacts that lack them, so the truth chain is queryable.
3. **Write evolutions** (0 currently). The sequence is ready for them — every intent.md already names the teaching concept clearly.

Chamber_Color is the weakest map by documentation depth and deserves a full blurb/intent/technical/critical pass along the lines of the other seven maps.
