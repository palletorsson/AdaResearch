# Sieve pass — facade_assembly architectural primitives (pass-4 build queue)

> **⚠ SUPERSEDED 2026-05-14T11:30:00.** This sieve proposed authoring ~25 architectural primitive artifacts (column orders, bay rhythms, cornices, etc.) for the facade_assembly branch. Subsequent discovery revealed that `commons/facade_parts/` already contains a 42-part procedural Italian architecture system with 26 v2-plan preset JSONs covering every facade in the branch. The `facade_builder` artifact dispatches to the existing FacadeComposer via `plan_path`; no new primitives need to be built. See the corrected blog at `/blog/2026-05-14-five-facades-one-virtual` and the system at `commons/facade_parts/README.md`. The sieve below is preserved as a record of what would have been built if the existing system had not been discovered. **Do not action.**

_Recorded 2026-05-14T11:00:00_

**Target:** the architectural-primitive build queue that the facade_assembly branch is now waiting on. After pass-1 (Principle + Chamber), pass-2 (Classical, NYC_Tenement), pass-3 (Baroque, Venetian_Gothic, Rustication), and pass-4 (Critique) — all eight maps now have bodies (spatial frame + intent.md + blurb.md). What's still missing is the *architectural primitive artifacts* each map references in its intent's Gap field. This sieve audits the primitives queue before authoring begins.

## 1. The claim

That a small set of architectural primitive artifacts — column orders, bay markers, rhythm rows, fenestration types, rustication surfaces, framing cornices, refusal motifs — can populate all eight maps' Gap fields without the queue exploding. Concretely: each map's intent.md lists 4-8 primitives in its Gap section; many primitives recur across maps (Doric column appears in Classical *and* Baroque; cornice appears in Classical, Baroque, Rustication; rustication surface variants appear in Classical *and* Rustication). A well-designed primitives set should be *combinatorial* — fewer than (8 maps × 5 primitives = 40) total artifacts; more like 18-22 primitives reused across maps.

## 2. The trace — what each map's Gap field lists

Reading each pass-1/2/3/4 intent.md for its Gap section:

| map | listed primitives | n |
|---|---|---|
| `Facade_Assembly_Principle` | column_order_doric, bay_rhythm_marker, hierarchy_stack, fenestration_row, rustication_surface, cornice_base_pair | 6 |
| `Facade_Classical` | column_order_doric, bay_rhythm_marker, fenestration_row, rustication_smooth, cornice_horizontal | 5 |
| `Facade_Baroque` | column_paired_corinthian, broken_pediment, projecting_pavilion, rustication_smooth_interrupted | 4 |
| `Facade_Venetian_Gothic` | pointed_arch_arcade, quatrefoil_tracery_row, foliated_capital, crenellated_band | 4 |
| `Facade_Rustication` | diamond_bossing_grid, smooth_ashlar_band, framed_window_in_rustication, projecting_cornice_horizontal | 4 |
| `Facade_NYC_Tenement` | bay_module_tenement, fire_escape_grid, window_lintel_simple, brick_surface | 4 |
| `Facade_Critique` | superstudio_slab, memphis_glyph_stack, totem_layer_variants ×6, asymmetric_lighting_rig | ~8 |
| `Chamber_Facade` | facade_synthesis_workbench | 1 |

**Total listed primitives across all eight maps: 36 token-instances.** After de-duplication and clustering, the real artifact count is much smaller.

## 3. Clustering by reusability

Looking at the 36 listed tokens, the *actual* artifact set partitions into seven groups:

### A. Column-order family (4 artifacts)
- `column_order_doric` — used in Principle, Classical
- `column_order_ionic` — implicit in Classical's column family but not specifically listed; build for completeness
- `column_order_corinthian` — used in Baroque (paired form)
- `column_paired_corinthian` — composite of two corinthian columns side-by-side; instantiates by composing

### B. Bay rhythm family (3 artifacts)
- `bay_rhythm_regular` — used in Principle, Classical
- `bay_rhythm_syncopated` — Baroque (with `projecting_pavilion`)
- `bay_module_tenement` — NYC Tenement (modularized form)

### C. Hierarchy / vertical structure (2 artifacts)
- `hierarchy_stack` — three-zone vertical (base / piano nobile / attic); used in Principle, Classical
- `projecting_pavilion` — Baroque (the central projecting bay structure)

### D. Fenestration (3 artifacts)
- `fenestration_row_regular` — Classical, Principle
- `pointed_arch_arcade` — Venetian Gothic (substitutes for the regular fenestration row)
- `window_lintel_simple` — NYC Tenement (utilitarian variant)

### E. Surface / rustication (4 artifacts)
- `rustication_smooth_ashlar` — Classical, Baroque (default surface)
- `diamond_bossing_grid` — Rustication (Naples-style projecting pyramids)
- `brick_surface` — NYC Tenement (modular brick face)
- `crenellated_band` — Venetian Gothic (top-edge motif)

### F. Framing / cornice (3 artifacts)
- `cornice_horizontal` — Classical, Baroque, Rustication
- `cornice_base_pair` — Principle (paired marker)
- `broken_pediment` — Baroque (the dramatic interruption)

### G. Refusal / critique (3 artifacts)
- `superstudio_slab` — Critique (the matte-black infinite slab)
- `memphis_glyph_stack` — Critique (the vertical stack of six unrelated glyphs)
- `facade_synthesis_workbench` — Chamber_Facade (the player's composition workbench)

### H. Decorative detail (2 artifacts)
- `quatrefoil_tracery_row` — Venetian Gothic
- `foliated_capital` — Venetian Gothic (a sub-component of pointed_arch_arcade; or could be standalone)

### I. Structural appendage (1 artifact)
- `fire_escape_grid` — NYC Tenement (the structural fire-escape on the front)

**Total deduplicated artifacts: about 25.** Less than the 36-token-instance count; more than the 18-22 I optimistically estimated upfront. Closer to the high end.

## 4. Question 1 — does this thicken?

What does building 25 architectural primitive artifacts do for the project's cognitive water?

- **Each artifact is itself a small ontological commitment** — *what is a Doric column, structurally? what does diamond bossing look like as a 3D primitive?* The act of authoring forces precision on questions that have been hand-waved at the prose level.
- **The primitives become reusable across the spine** — a Doric column built for Facade_Classical can appear in any later map that wants Doric vocabulary. The architecture branch isn't a closed system; the primitives feed into chamber compositions, into player-built facades, into the catalyst bracelet's eventual `compose` affordance.
- **The pass closes the actualization loop** — currently each map walks but doesn't speak. After primitives, each map *speaks*. The principle/expression frame becomes spatially fully actualized.
- **The audit's score-79 plateau breaks** — all six built maps currently score 79 because they have text but no artifacts. Primitives will let them break through to 90+.

Net Q1: **strong thickening** along four axes.

## 5. Question 2 — what is foreclosed?

- **Authoring 25 primitives is a lot of work.** ~30-60 minutes per primitive (modeling, code, scene, registry, capture). 12-25 hours of work to complete the queue. *Risk:* either the queue is partial (and the audit's plateau persists for some maps), or other work backs up while this proceeds. *Mitigation:* tier the primitives. Build the highest-impact 8-10 first (the ones that appear in multiple maps); leave the rare ones for later.
- **Architectural primitives are *fixed* once built — they crystallize what we now think a Doric column is.** Future redesign might want a Doric column that's parametric (a `column_dna` thread). *Risk:* building static primitives forecloses parametric variation. *Mitigation:* design each primitive's GDScript to accept an `apply_grid_config()` dictionary — same pattern as other Ada artifacts — so the static instance carries enough configurability to be re-purposed later by a parametric thread. *(This is itself a Deleuzian discipline: build the actual as one position in an explicit virtual.)*
- **A 25-artifact queue could distort the project's other priorities.** The Pattern_pt* parallel cleanup (10 wallpaper-pattern maps under mosaicanalysis) still needs scaffolding. The `research_threads` registry remains unbuilt. The catalyst bracelet's re-virtualization blog is unwritten. *Risk:* the facade_assembly perfection-rush eats other arcs. *Mitigation:* commit to ~half the primitives (the 8 highest-impact), then explicitly stop and re-evaluate priorities.

Net Q2: **two real risks, both mitigable.** Critical mitigation: build the artifact in *Deleuzian* mode, accepting `apply_grid_config()` parameters so static primitive can be parametrized later. Tier the build aggressively.

## 6. Question 3 — what lives in the dark spot?

- **What is a column, ontologically?** Building `column_order_doric` as a GDScript artifact requires committing to *what a column is* — a 3D mesh? A composition of base + shaft + capital? A CSG composite per its substrate-grounding? *Generative habitat:* the choice of how to construct a column is itself a research finding. Different decompositions teach different things. The first one we build will set a precedent.
- **What about cultural variation?** A Doric column outside Greece is already a translation. The Renaissance reinvented Doric. The map's vocabulary is necessarily *one* tradition's reading. *Risk if forecloseed:* the primitives encode a Eurocentric architectural canon and present it as universal. *Generative habitat:* documenting this explicitly in each primitive's `@identity` would be honest.
- **The catalyst bracelet's `compose` affordance.** Each architectural primitive is, secretly, a thing the player will eventually hold and fire from the bracelet at synthesis. The primitives aren't just decorative; they're *affordances-in-waiting*. Building them with that future in mind matters. *Generative habitat:* design the primitive's GDScript with the bracelet's future eyes.
- **What does the architecture branch teach the rest of the spine?** Building these primitives produces a *vocabulary of composition operators at architectural scale* that other sequences could reuse. Computational geometry could use the column-as-CSG-composite as an example of `csg_compose`. L-systems could use the rhythmic bay as a substrate for grammar generation. *Generative habitat:* the primitives become *seeds* for other research threads.

Net Q3: **four generative habitats, no sterilising concern.** The dark spots open ways the primitives could matter beyond their own sequence.

## 7. Recommendations

### 7a. Tier the build

**Tier 1 (highest reusability — build first, ~8 artifacts):**
- `column_order_doric` — appears in 2 maps + bracelet affordance precedent
- `bay_rhythm_regular` — appears in 2 maps + becomes substrate for syncopated/modularized variants
- `cornice_horizontal` — appears in 3 maps + framing operator
- `rustication_smooth_ashlar` — appears in 2 maps + default surface
- `hierarchy_stack` — appears in 2 maps + the vertical-structure operator
- `fenestration_row_regular` — appears in 2 maps + default opening
- `facade_synthesis_workbench` — Chamber_Facade's synthesis artifact (closes the sequence)
- `superstudio_slab` — Critique's first refusal (closes the synthesis arc)

After tier 1: Classical, Principle, and Chamber map all jump to score 90+. Critique partial. ~5 hours of work.

**Tier 2 (sequence-specific — build per-map as time permits, ~10 artifacts):**
- `column_paired_corinthian` — Baroque
- `broken_pediment` — Baroque
- `projecting_pavilion` — Baroque
- `pointed_arch_arcade` — Venetian Gothic
- `quatrefoil_tracery_row` — Venetian Gothic
- `diamond_bossing_grid` — Rustication
- `bay_module_tenement` — NYC Tenement
- `fire_escape_grid` — NYC Tenement
- `memphis_glyph_stack` — Critique
- `bay_rhythm_syncopated` — Baroque (derivable from regular + offset)

After tier 2: all maps fully populated.

**Tier 3 (decorative refinement — defer indefinitely, ~7 artifacts):**
- `column_order_ionic`, `column_order_corinthian` (without pairing) — only if a future map needs them
- `crenellated_band` — Venetian Gothic top edge; could be sub-mesh inside another primitive
- `foliated_capital` — could be sub-component of `pointed_arch_arcade`
- `cornice_base_pair` — could be derived from `cornice_horizontal` + a base variant
- `framed_window_in_rustication` — composition not new primitive
- `rustication_smooth_interrupted` — Baroque-specific composition
- 6 `totem_layer_*` glyph variants — Memphis stack; could be a single `memphis_glyph_stack` artifact parametrized

Tier 3 might never need to be built; the tier-1 + tier-2 set (~18 artifacts) is the practical maximum the branch needs.

### 7b. Design each primitive to accept `apply_grid_config()` parameters

Every artifact's GDScript should accept a config dictionary that allows static-primitive-as-position-in-virtual-field. Example for `column_order_doric`:

```gdscript
func apply_grid_config(config_data: Dictionary) -> void:
    if config_data.has("column_height"):
        # adjust column height
    if config_data.has("base_diameter"):
        # adjust proportions
    if config_data.has("fluting_count"):
        # set fluting
```

This way the primitive is *one actualization* but parametrizable into *adjacent actualizations* — exactly the Deleuzian discipline: build the actual as one position in an explicit virtual, not as a closed canonical instance.

### 7c. Document each primitive's `@identity` with its haecceity

The `@identity` doc-comment is, in the Deleuzian frame, the haecceity statement — what makes *this* primitive *this* and not the adjacent one. Author each carefully:

```gdscript
# column_order_doric — the simplest of the canonical column orders.
# @identity: A Doric column. Heavy proportions (height ~7× base diameter),
#   no base (sits directly on the stylobate), echinus + square abacus capital.
#   Greek tradition translated to Italian/Renaissance proportions.
#   First column the player meets in facade_assembly; the column-order primitive.
```

The haecceity statement does the actualization work the principle map's prose started.

### 7d. Capture each primitive immediately

Use `capture_tscn_shot.gd` on each artifact .tscn as soon as it's built. The capture lands in the registry as the primitive's visual presentation; the encyclopedia's artifact pages can show it; the journalist visits can quote it.

## 8. Reorder candidates (none structural; these are build-order moves)

| change | from | to | impact |
|---|---|---|---|
| **architectural primitives queue** | undefined | tier 1: 8 artifacts (Doric, regular rhythm, horizontal cornice, smooth ashlar, hierarchy stack, regular fenestration, synthesis workbench, Superstudio slab) | medium — tier 1 unlocks scoring jump on 5+ maps |
| **GDScript convention** | static primitive | parametric via `apply_grid_config()` | low — same pattern Ada already uses |
| **`@identity` requirement** | optional | required (haecceity-honest) | low — convention not infrastructure |

## 9. Verdict

The architectural primitives queue is **build-ready under a tiered approach.** ~25 total artifacts; tier-1 of 8 unlocks the highest-impact gains; tier-2 of 10 completes the sequence's actualization; tier-3 of 7 is deferrable. Each primitive built with `apply_grid_config()` and honest `@identity` keeps the Deleuzian discipline intact. Static actualization but explicitly parametrizable — *one position in an open virtual field* rather than a closed canonical thing.

Estimated work for tier 1: ~5-6 hours. Tier 1 + 2 together: ~12-15 hours. Probably worth its own session, or two sessions, separate from authoring more expression maps in other branches.

Load-bearing rule out:

> **Static artifacts authored under Deleuzian discipline carry their own parametric virtual.** The primitive is one actualization; the GDScript's `apply_grid_config()` honors that the primitive *could have been otherwise* and stays open for re-actualization by future threads (`column_dna`, the catalyst bracelet's `compose` affordance, parametric grammar engines). Building the actual without claiming exhaustion of the virtual is what the morning's sieve required, applied to the artifact layer.

The next session should pick tier 1 and ship the eight tier-1 primitives. After those land, all six built maps will jump from score 79 to 90+, Chamber gets its workbench, Critique gets its first refusal, and the facade_assembly branch becomes structurally first-pass-complete. The architectural-primitives session is its own arc; this sieve is the prep that lets it begin without the build collapsing into ad-hoc decisions.
