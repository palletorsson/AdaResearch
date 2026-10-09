# Randomness: artifacts and writing

Audit: 17 September 2026. Recommendations only; this audit does not change placements, roles or book text. Sources inspected: current map-authored route, map layers, museum plan, artifact roles, nine final.md files, implementation scripts, and the live encyclopedia catalogues. Historical catalogue pictures were inspected; candidate scenes were not newly runtime-tested or headset-tested.

## Where we are

The artifacts are ahead of the writing. All nine active halls have final.md. There are 50 map artifact placements, including support/decorative objects and repeated instances, plus the architectural weathering wall. An editorial count gives 45 substantive placements representing 41 distinct artifact kinds. The old seven-hall/63-placement review is superseded.

Authority: `commons/data/map_authored.json`, checked against `ada_run/em_plan.json`. The legacy sequence file also contains inactive maps and is not the current walking order.

| Current order | Writing assessment | Next concrete improvement |
| --- | --- | --- |
| Random_Definition | Small revision | Give the historical number page, crank and TRNG/PRNG comparison distinct contributions. Seed replay and textile comparison are already concrete. |
| Random_Entropy | Small revision | Ledger, displacement enclosure, ruin and actual wall are written. Selectively connect jar/hardware decay/butterflies without conflating their different processes. |
| Random_Remove | Small revision | Repair the departure: 10 PRINT now follows, not Walk. |
| Randomness_10_PRINT_Algorithm | Rewrite needed | Write terminal → room structure → Molnar comparison; assign their actual teaching roles. Existing text mainly describes an older maze and promises a die in the next hall. |
| Random_Walk | Small revision | Integrate random_draw_dot before the departure to Gaussian; repair the opening's previous-room reference; select a meaningful leash/paper/cloud contrast. |
| Random_Gaussian | Small revision | Make the Galton board, paint splatter and comparator do distinct work alongside the sampler. |
| Random_Mushrooms | Substantially aligned | Population, arrivals and couture are already integrated. Bubble dish can remain a quieter support. |
| Randomness_Examples_of_Randomness | Substantially aligned | All four restored works participate in the prose. A short real source excerpt could strengthen the code layer. |
| Random_Game | Substantially aligned | Current crossings, removal, doors, projectiles and waiting/profile pairing are written. Preserve the transition to Noise. |

“Aligned” is an editorial assessment, not a new runtime test. No fixed limit on primary works is needed: Examples already gives four works separate contributions to one question.

### Specific drift to repair

- `Randomness_10_PRINT_Algorithm/artifacts.md` and `artifact_roles.json` omit the newer terminal, composition and linked structure as substantive participants.
- `Random_Walk/artifacts.md` omits `random_draw_dot`, while final.md places its passage after the hall's departure.
- Remove → 10 PRINT → Walk needs three consistent transitions.
- The ant-maze timer rotates visible walls without rebuilding its navigation grid. Do not write that the ant responds to the newly rotated geometry. Source: `algorithms/randomness/generative/tenprintantmaze/ten_print_maze.gd`, `_on_wall_timer_timeout`, versus initial navigation construction.

## The six requested candidates

None of these six exact registered kinds occurs in the 163 active map files named by current chapter arrays. They do occur in old/test maps; those placements are not active duplicates.

| Candidate | Proposed use | Preparation and limits |
| --- | --- | --- |
| `dice_throw` | First compact addition: Gaussian, before accumulated distributions. The visitor throws a physical simulated die and compares a few results with a longer tally. | Use `warrant:tally`. Repair local/world placement errors in reset and reward spawning; then test in its actual hall. Outcomes are read from die orientation, not sampled as uniform integers. The simulation's fairness is a question. |
| `random_color_book_page_collection` | Definition, beside the number page: what changes when a number becomes colour? | This is the registered ID. Use a pinned `page_seed` and `disclosure:origin`. It generates RGB through PRNG draws; it does not display historical RAND values as colours. Three static pages occupy about 12.4 × 6 m by default, so scale and readability need staging. No visitor reroll is implemented. |
| `sculpt_one` | Examples: give random choice a volumetric, material body. Compare authored procedures or material treatments at the same seed. | DNA supports `hand:composition/pour/drape/stipple/spatter`, `substance:mixed/glossy/fabric/granular`, and `sculpt_seed`. The current work rotates; it has no visitor material dial or sculpting control. Some shaping uses Simplex noise, so isolate the PRNG comparison or explicitly reserve that layer for Noise. Check its lights/environment against the hall. Footprint about 4.9 × 4.4 m. |
| `crystal_random_walk_demo` | Walk, as an optional ending: a constrained walk becomes a branching object. | Needs private RNG, reliable replay, bounded total instances and compact world-space controls. Current interface is desktop CanvasLayer with global mouse capture and global seeding. This is branching form generation, not just a clean lattice walk. |
| `plane_random` | A deliberate walkable comparison near the transition to Noise; potentially restore a dedicated terrain encounter. | Independent random increments accumulate in individual vertices. This is not coherent noise. Current 20 × 20 m terrain needs seed/reset/pause, bounded displacement and tested collision before a glass-box installation. Do not shrink only the mesh: horizontal collision scaling needs checking. |
| `env_one` | Reserve a dedicated spatial assembly encounter. Randomness chooses modules within an authored kit. | Actual catalogue bounds about 58 × 30 × 59 m, far beyond a side exhibit. Needs controllable generation extent, private RNG, readable controls, traversal/collision and environment integration. Current map config does not parse module_count/space_size. |

Implementation evidence: `algorithms/randomness/dice_throw/dice_throw.gd`; `randomnumbergeneration/scenes/random_color_book_page_collection.gd`; `randomnumbergeneration/scripts/random_color_book_page_1955.gd`; `SculptOne.gd`; `randomwalk/scripts/crystal_random_walk.gd`; `randomwalk/scripts/crystal_demo_controller.gd`; `PlaneRandom/plane_random.gd`; `envOne.gd`.

## Other DNA that earns its place

1. **Mixing jar pair — strongest additional critical comparison.** In Entropy, compare `mixing_jar#found_state:mixed#reduction:bodies` and `mixing_jar#found_state:shelled#reduction:bodies`, then their `reduction:cells` accounts. Both have the same weighted binary Shannon measurement, 1 bit, because the six vertical bins cannot see radial separation. The shell remains organized although this measurement cannot distinguish it from mixing. Existing `entropy_jar` supplies the connection; keep its work. Avoid the form/gyroid variant here. Source: `commons/artifacts/mixing_jar/mixing_jar.gd`, `_bin_plan`, `_radial_plan`, `_measure`.

2. **Rough rock triplet — a clear bridge from primitives to random bodies.** Compare `roughrock#rock_seed:7#roughness:0`, seed 7/roughness 0.15, then seed 2/roughness 0.15. The underlying points are already irregular at zero; independent offsets add variation without requiring Perlin. Definition or Mushrooms fits. The bare rock already appears in Primitives_Ignorance: explicitly make this a return with a new operation. Source: `commons/primitives/roughrock/roughrock.gd`.

3. **Alphabet grammar — same draws, different allowed marks.** The diagonals, orthogonals and blocks alphabets all read the same 144 seeded values. Suitable as a compact 10 PRINT comparison, but that room already needs its existing works integrated before another cabinet is added. `alphabet_grammar#alphabet:diagonals#reading:field`, plus orthogonals/blocks. Source: `commons/artifacts/alphabet_grammar/alphabet_grammar.gd`.

4. **Endpoint-constrained profile — variation between obligations.** Compare `profile#algorithm:brownian` with `profile#algorithm:random_walk` in Walk. The advertised catalogue token BROWNIAN_BRIDGE is not accepted by current code; `brownian` is. The cartridge subtracts a straight line and normalizes uniform increments; describe it as an endpoint-constrained random trace, not an exact Brownian-bridge sampler. Sources: `commons/substrates/profile/profile_substrate.gd` and `cartridges/cartridge_brownian_bridge.gd`.

5. **Bricoleur golem — a later body/game candidate.** Same `part_seed`, compare `salvage:mixed` with `salvage:crates` and `assembly:figure`. Chance chooses parts inside six fixed body slots: the repertoire already limits what bodies can occur. This is currently a chasing/rebuilding hazard and needs a considered encounter or exhibit mode. Source: `commons/hazards/bricoleur_golem/bricoleur_golem.gd`.

The Shannon Workbench's anecdote/census variants also offer a good sample-size comparison, but extending the existing meter may be clearer than adding another instrument. It already appears in SpeculativeComputation_Paraconsistent_Engineering. Perlin, CA, evolutionary and swarm pieces in the broad catalogue should retain their later sequence roles.

## What the catalogue comparison tells us

- [Randomness concepts](http://127.0.0.1:3003/randomness-concepts): 199 cards in 21 groups. These are candidates grouped by principle, not 199 ready museum works. The groups extend into Noise and later topics; placement annotations may be historical.
- [Randomness DNA](http://127.0.0.1:3003/randomness-dna): 41 visual variants across 10 kinds. Particularly useful for planning comparative treatments of existing works. A variant does not imply a visitor-accessible mode switch or runtime readiness.
- [Other DNA](http://127.0.0.1:3003/dna): strongest new comparisons above were checked against implementation. Catalogue wording sometimes overstates controls or supplies an unsupported token.

## Recommended next pass

1. Rewrite 10 PRINT using its existing terminal, structure and Molnar works; align roles/inventory and repair its neighbouring transitions.
2. Restore and validate the die in Gaussian; write from actual throws and accumulated observations.
3. Integrate drawing dot and a selected supporting comparison into Walk.
4. Add the mixing-jar contrast; connect it to the existing entropy measurement without equating every form of change with one entropy quantity.
5. Stage the colour-page comparison and a sculpture procedure/material comparison where they add something the current works do not.
6. Prepare crystal and terrain as separate implementation tasks; give env_one its own space proposal.

The red thread can stay concrete: **what may chance change; what was fixed before the draw; what accumulates; what the measurement loses; and what the resulting world permits a body to do.** Each addition should make one of those questions newly observable. Then the book can follow it.
