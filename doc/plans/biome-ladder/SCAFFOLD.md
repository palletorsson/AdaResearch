# Building out of the existing biome ladder

13 October 2026. Source-backed expansion plan for the current 25-sequence spine.
Six arena stages exist, through Change. B20/B21 runtime evidence is in CHANGE.md; this publisher audits the plan structure only.
The later rows below are scaffolds, not newly playable maps or revised book lessons.

## What the older work gives us

1. **Cumulative vocabulary.** `commons/biome_layers/biome_grammar.gd` reads the canonical spine and `map_authored.json`; `commons/data/biome_vocabulary.json` supplies made-of / does / knows. The old Biome_Ladder_Primitives, Transformation, Color and Randomness halls display these additions through `biome_vitrine.gd`. They are display encounters, not the new combat route.
2. **One seed, several states of a world.** Generation 17 of `commons/artifacts/biome_object/biome_object.gd` has stage and phase gates, a sampled ground, water, rocks, vegetation and resident placement. It can reveal layers gradually. Its `full` state is the mature habitat, not the proper default for every early arena. The old phase knob mixes the words arriving at a stage; it does not automatically make every curriculum operation into gameplay.
3. **Actual continuity of objects.** `biome_inheritance.gd` and `rising_banners.gd` retain panel IDs, bodies and their record while translating, rotating, scaling and colouring them. The later habitat reads their footprints to keep vegetation clear. That is a stronger reuse seam than replacing the whole scene after each sequence. This bridge currently expects its own panel encounter, not arbitrary arena cover; an adapter is still needed.
4. **Walkable surfaces.** `TopologySpace.gd` builds geometry and collision from heights. SineSpace, RandomSpace and NoiseSpace already implement the three floor ideas Palle requested. `biome_ground_substrate.gd` adds a paint texture over a sampled field. They need arena-sized sampling, retained surface addresses and safe placements; a scene instance alone is not the integration.
5. **A shared play shell.** The new ladder already owns the XR/desktop player, catalyst, hit/death/reset paths, cover, tile records, six stage choices and museum handoffs. Keep that shell and adapt these older components into it.

## Where the sources need care

- **Three sources describe different things.** Canonical spine order names the curriculum. BiomeGrammar names cumulative vocabulary. soft_stages and biome_contributions still contain older numeric orders and some different gates. An old number is not a current stage index. Tiling and Form-finding lack soft_stages entries; Shaders lacks a biome_vocabulary sequence entry. Preserve other consumers while introducing an explicit translation or migration.
- **Vocabulary is not implementation.** The mature BiomeObject consumes a subset of the grammar words. Merely setting its stage to Change, Waves or Shaders does not construct those arena behaviours. `connect` and `absent`, for example, are recorded without a dedicated world layer in that object.
- **Some old layer names overstate behaviour.** force_field draws arrows; swarm_creatures follows predetermined orbits; adaptive_behavior pulses halos; tunable_field builds static dial indicators; critical_overlay draws a tinted dome. ca_surface computes real CA generations at build time, then displays a static field. These are useful visual parts, but cannot certify force integration, neighbour-driven swarming, learning, live tuning, measured bias or ongoing CA respectively. Reuse the actual corresponding algorithm where the stage requires it.
- **The earlier Tiling obstruction is fixed in B20.** The new probe reproduces it, then reaches all 14 controls with the fix. B19 exposes the nine-head array; B20 signals matching tiles together. Independent review of the updated full route and physical headset acceptance remain open. See CHANGE.md.
- **Hall boundaries need explicit decisions.** Authored lists include some Biome_Ladder display rooms after the teaching halls. The current playable route deliberately uses Trans_Pit and Color_Walls, not the final item of those authored lists. Noise's sequence file ends at Lab_Path while its authored list ends at Noise_Perlin_Simplex; that discrepancy needs resolving before its arena handoff is built. Do not generate new exits blindly from `map_authored[-1]`. Check actual sequence routes, current runtime boundaries and intended placement together.

## The scaffold to implement

Use **one record for each stage**, keyed by sequence name, with inherited capabilities, one featured operation, source adapters, surface policy, counterpart response, museum entry/return and acceptance evidence. SCAFFOLD.json is a review record for this purpose; the runtime does not read it yet. Do not make a second authoritative copy of spine order.

Keep the same catalyst, landmark IDs and floor addresses. Add an arena-owned state record for seed, tile hit count, colour, motif, field values and entity IDs. Separate the record from its rendering so a flat tile address still refers to the same place on a sine or noise surface. Existing run state currently resets on stage exit: continuity of available abilities is implemented, but transporting the player's exact floor edits into another stage is a new decision and implementation task. Proposed default: carry edits on NEXT STAGE; RESET restores the current stage's explicit baseline; standalone selection begins with its documented fixture. This default is not applied by this report.

Give the surface adapter world-to-address and height sampling, one render/collision revision, and the impact receiver. Reuse a single terrain builder per stage; avoid layering the old full accrual stack under the new floor. Retained cover needs both ground placement and verified collision: mature plants or stones are not automatically cover because they look solid. The white outlined primitive floor and its fixed refuge remain the starting contract.

Capabilities accumulate; workload need not. Keep earlier actions available but cap active heads, branches, terrain updates and particles, and activate expensive modules only where needed. This preserves a readable new operation and a playable frame budget. Later stages can turn a counterpart into a source, guide or companion; progression need not mean an endlessly stronger enemy.

## First implementation group

**A0 — repair and clarify the five-stage route.** Make all 13 controls reachable after transformed floor hits; keep projectile contact accurate. Expose the Arrays row, put the stage rule where it can be read, and signal all motif copies together. Rerun Claude's route test and the existing hit/cover/tiling checks after the relevant changes.

**B0 — connect the existing systems through a small adapter.** Reuse BiomeGrammar as the cumulative vocabulary source, and current spine keys as order. Preserve existing route behavior first. Add a surface/receiver interface at the current flat-floor seam, with stable addresses. Keep old consumers intact and document any gate translation. This makes later additions smaller instead of accumulating more `stage >= n` branches.

**B1 — Change, then Forces.** Start with the floor-steers proposal, corrected to prescribed velocity: `position += direction(position) * speed * delta`. Its integral is a trajectory; it has no retained inertial velocity yet. Forces then introduces `velocity += acceleration * delta`, mass and impulse. Claude's proposed velocity-gains-a-push version belongs at that second step. Both versions must keep arrows and motion tied to the same declared sampler. The existing noisy hall sampler is supplied machinery at Change; it is not an early Noise terrain unlock.

**B2 — Form-finding, then the terrain trio.** Add one explicit optimisation problem, then adapt SineSpace → seeded static RandomSpace → correlated NoiseSpace. Compare the last two using fixed footprint, controlled range and recorded neighbour-difference measurements. Preserve earlier paint, transform and tiling operations. Start with static terrain; moving collision under the player's feet is a separate feature.

This gives us a bounded next group ending at Noise, with later work organised into C (Shaders–Procedural Generation), D (Soft Bodies–Swarm) and E (Graphs–Post-foundations). A scaffold for all 25 sequences is useful now; marking all 25 playable would not be true.

## Per-stage acceptance

For every implemented addition, check: the new subject makes an observable difference; earlier selected actions still work; shots, cover and feet agree with collision; the seed/reset policy is reproducible; NEXT STAGE and MUSEUM go to the intended place; an actual standing-height capture shows the relation. Add an appropriate numerical or behavioural assertion for the new rule. Record hardware/backend and frame cost; desktop checks do not certify Quest comfort.

The audit accompanying this document validates order, source links and planning completeness only. It does not execute these proposed interactions. Claude's latest route findings and the previous B16 runtime evidence remain separate records.

## Sequence cards

Edit `doc/plans/biome-ladder/SCAFFOLD.json`, then run `python -X utf8 tools/publish_biome_scaffold.py`. The generated Markdown and page follow that file. Share `http://localhost:3003/biome-plan/scaffold.html` and SCAFFOLD.json with Claude; claim a small task and its files before editing. No forum message was sent in this pass.


### 01. Primitives — Playable prototype

**Form shelters a body.**


**Current change list:**
- Check in VR that a hit skull falls and cover blocks its shots.


- **World:** White ground, thin black outlines, six tall shelters and a clear route. Static heads stand on poles.

- **Catalyst:** The carried sphere and hand form fire small balls. A ladder skull falls after one hit.

- **Counterpart:** Slow straight shots; the player can step behind a solid form.

- **Reuse:** Keep the current cover and hit path. Earlier biome_primitives records offer stable identities for a later bridge into the habitat.

- **Work remaining:** Retest the B16 skull fix in the headset; retain one-hit ladder defeat and three-hit player health.

- **Acceptance:** A real shot defeats a visible skull in READY, PLAY and REST; the skull physically falls. Cover blocks an incoming shot; the open lane does not.

- **Sources:** `commons/hazards/biome_ladder/ladder_encounter.gd`; `commons/hazards/biome_ladder/ladder_skull.gd`; `commons/artifacts/biome_primitives/encounter_model.gd`


### 02. Transformation — Playable prototype

**The same form moves, turns and scales.**


**Current change list:**
- Make moving, rotating and scaling cover easier to read. Keep the entrance refuge still.


- **World:** Keep the fixed entrance refuge; other cover translates, rotates or grows from the ground. Pickups remain reachable.

- **Catalyst:** A tile hit multiplies scale by 0.8 and turns it 22.5 degrees around Y.

- **Counterpart:** Heads move and turn; their slow balls grow within a fixed bound.

- **Reuse:** Current motion records and collision-following bodies; rising_banners shows how the very same panels can retain identity through transforms.

- **Work remaining:** Make each operation readable in play with a short label or motion cue, while leaving the refuge fixed.

- **Acceptance:** Sample moving cover over a full cycle: refuge, collision and route remain usable; tile impacts retain their measured scale and turn.

- **Sources:** `commons/hazards/biome_ladder/ladder_encounter.gd`; `commons/hazards/biome_ladder/ladder_ball.gd`; `commons/artifacts/biome_inheritance/rising_banners.gd`


### 03. Arrays — Playable prototype

**A slot remains when its occupant falls.**


**Current change list:**
- Reveal all nine numbered places from the entrance. Leave a visible empty place when a skull falls.
- Make a standing 3 × 3 array of skulls with stable row and column addresses. Fire by row or column.
- Make balls zigzag through an ordered list of positions. Keep smooth oscillation for Waves.


- **World:** Black-and-white addressed floor; three indexed heads, with inherited transformations and cover.

- **Catalyst:** Choose one occupant; preserve the other slots and all earlier tile responses.

- **Counterpart:** A small ordered row; a defeated head leaves a legible vacancy.

- **Reuse:** The current row and tile address arrays. Keep indices independent of world position and live body references.

- **Work remaining:** Expose the row from arrival: Claude's capture review found the cylinders hide it and the labels are too far away.

- **Acceptance:** Removing the middle occupant leaves the first and third addresses unchanged; all three slots are legible from the entrance.

- **Sources:** `commons/hazards/biome_ladder/ladder_encounter.gd`; `commons/maps/Array/tutorial.md`


### 04. Colour — Playable prototype

**An impact leaves a colour.**


**Current change list:**
- Carry floor colours into later terrain, together with tile scaling and rotation.
- Burst intense colour from a hit skull and leave colour on nearby surfaces. Keep the skull silhouette readable.


- **World:** Colour enters the forms and disco grid; the skulls remain black and white.

- **Catalyst:** Hits still shrink and turn a tile, now also colouring that same tile.

- **Counterpart:** Coloured balls and trails; a hostile ground impact colours its local receiver.

- **Reuse:** Current per-tile marks and individual materials, plus the existing biome paint texture for later terrain.

- **Work remaining:** Carry the colour record by surface address when flat tiles later become a height field.

- **Acceptance:** Only the actual receiver is coloured. REST retains the mark; RESET restores the declared baseline.

- **Sources:** `commons/hazards/biome_ladder/ladder_encounter.gd`; `commons/biome_layers/biome_ground_substrate.gd`


### 05. Tiling — Playable prototype

**One impact changes a repeated address.**


**Current change list:**
- Keep the console reachable after tiles turn and shrink.
- Flash all matching pattern tiles together when one is hit.


- **World:** A 2 by 2 motif repeats across the 6 by 12 floor. The same shelters and route remain.

- **Catalyst:** A hit repeats scale, turn and colour on 18 matching tiles. Any copy can edit that motif address.

- **Counterpart:** Its ground marks stay local, distinguishing a local event from the player's repeated rule.

- **Reuse:** Current modulo address mapping and per-address hit counts; inherited banner patterns are an optional later surface receiver.

- **Work remaining:** Fix the reported post-hit console obstruction, then flash all responding copies briefly so repetition reads from standing height.

- **Acceptance:** One shot changes exactly 18 copies; four motif addresses remain independent. All 13 controls stay reachable after the shot.

- **Sources:** `commons/hazards/biome_ladder/ladder_encounter.gd`; `commons/artifacts/biome_inheritance/banner_pattern.gdshader`


### 06. Change — Playable prototype

**A local rate accumulates into a path.**


**Current change list:**
- Let a shot change the local direction field. The same arrows guide moving balls.
- Let a projectile sample the player’s position once, signal its turn, then continue straight toward that sampled position.


- **World:** The inherited tiles carry arrows; their rotations supply the field sampled by the centre-column balls.

- **Catalyst:** The existing shot turns, shrinks and colours the matching tiles, changing their arrows. The player projectile retains its earlier flight.

- **Counterpart:** Centre-column shots follow the local field for 1.4 seconds, sample one target, pause with a 0.9-second signal, then commit to a straight line. Outer columns retain the Arrays zigzag.

- **Reuse:** The Flow_Field hall's shared-sampler and trail pattern; current tile turns and hit records. This adapts Claude's floor-steers proposal to the hall's prescribed-velocity subject.

- **Work remaining:** Physical headset review of field readability and the one-turn cue. Independent route review. Forces comes next; exact personal floor edits still reset on stage changes.

- **Acceptance:** Implemented checks cover shared arrow/sampler transforms, real input, prescribed speed, one interval versus two halves, one target sample, warning, committed collision and resets. See CHANGE.md; no headset acceptance claimed.

- **Sources:** `commons/artifacts/flow_field_painter/flow_field_painter.gd`; `commons/artifacts/flow_field_painter/shared_field_lesson.gd`; `commons/maps/sequences/change.json`; `commons/hazards/biome_ladder/direction_field.gd`; `commons/hazards/biome_ladder/change_ball.gd`


### 07. Forces — Proposal · not built

**A push changes carried velocity.**


**Current change list:**
- Let shots push movable cover. Mass changes how strongly it responds.
- Boost balls away from skulls with a short acceleration, then let them coast.
- Add mortar shots: a launch impulse followed by gravity makes an arc. Signal the landing area.


- **World:** Add one movable barrier or receiver beside fixed refuge. Mass and momentum now affect how it responds.

- **Catalyst:** A shot imparts an impulse; the body continues after contact and can be pushed back.

- **Counterpart:** Its projectiles can push that same receiver, using the same physical rule.

- **Reuse:** The existing sphere force lineage and impulse study; shared projectile collision. The legacy force_field layer only draws arrows and is not a force solver.

- **Work remaining:** Choose one receiver with explicit mass and bounded travel; adapt the existing rigid-body interaction without replacing the player's locomotion.

- **Acceptance:** Equal impulses on two declared masses produce different velocity changes; the refuge remains fixed and usable.

- **Sources:** `doc/book/studies/forces-point-lineage/03_mass.gd`; `doc/book/studies/forces-point-lineage/10_impulse.gd`; `commons/biome_layers/force_field.gd`


### 08. Form-finding — Proposal · not built

**An update searches for a lower cost.**


**Current change list:**
- Let a cover arrangement settle through small steps toward a visible goal.
- Allow up to three visible course corrections. Each evaluates candidate directions for approaching the player while avoiding cover.


- **World:** A cover arrangement adjusts toward an explicit objective, with a visible stopping condition.

- **Catalyst:** Move an anchor or start point; observe a different settled arrangement.

- **Counterpart:** It has to navigate the resulting arrangement; do not give it a second unrelated new ability here.

- **Reuse:** descent_landscape_lab has real cost, finite differences and stop reasons. Its display is not a walkable or physical terrain; use its update logic, not an assumed collider.

- **Work remaining:** Map one small optimisation variable to a barrier pose, preserve a safe path, and distinguish optimisation steps from elapsed physical time.

- **Acceptance:** For a declared stable step setting the measured cost decreases; SMALL SLOPE, STEP LIMIT and leaving the allowed domain remain distinguishable.

- **Sources:** `commons/artifacts/descent_landscape_lab/descent_landscape_lab.gd`; `commons/maps/FormFinding_Descent/tutorial.md`


### 09. Waves — Agreed direction · not built

**Periodicity becomes walkable relief.**


**Current change list:**
- Make a shallow sine-wave floor that can be walked on. Keep earlier shot effects.
- Send an array of balls in a wave volley. Different phases shift each ball’s oscillation.


- **World:** The existing floor becomes a shallow sine surface; landmarks and earlier surface addresses remain identifiable.

- **Catalyst:** Earlier transform, paint and motif effects remain available on the shaped surface. A later optional control can change amplitude or phase.

- **Counterpart:** Crests interrupt sight lines; optionally phase its movement against the same period after the floor is readable.

- **Reuse:** SineSpace builds a height mesh and matching trimesh collision through TopologySpace. Use its actual equation and sampler.

- **Work remaining:** Adapt the surface to the 12 by 24 arena, shallow enough for locomotion; keep it static initially and fit cover, spawn and controls to sampled height.

- **Acceptance:** Ray hits match visible crests and troughs; the route is traversable; motif addresses and colour marks survive the surface change.

- **Sources:** `commons/context/walkgrids/SineSpace.gd`; `commons/context/walkgrids/TopologySpace.gd`; `commons/biome_layers/biome_ground_substrate.gd`


### 10. Randomness — Agreed direction · not built

**A seed chooses independent heights.**


**Current change list:**
- Add uneven, randomly raised ground. Keep the same seed when restarting.
- Vary each shot’s launch angle independently within a fixed spread. Keep speed and timing fixed at first.


- **World:** The floor becomes irregular and harder to walk, within a measured slope and height budget.

- **Catalyst:** Keep earlier actions while learning a new route through a reproducible uneven floor.

- **Counterpart:** A proposed bounded seeded variation in shot timing can follow; first isolate the floor so difficulty does not change in two unexplained ways.

- **Reuse:** RandomSpace already has a seed and distribution laws. Disable animation and retain the same draw record throughout the attempt.

- **Work remaining:** Build a fixed sampled height field, with a traversable corridor and cover clearances. Reset reuses the seed; reroll must be an explicit different action.

- **Acceptance:** Same seed and law reproduce the heights; the field does not resample while walking. The route and all controls remain reachable.

- **Sources:** `commons/context/walkgrids/RandomSpace.gd`; `commons/context/walkgrids/random_space.tscn`


### 11. Noise — Agreed direction · not built

**Neighbouring heights become correlated.**


**Current change list:**
- Smooth the abrupt ground into connected hills using noise. Keep the same overall height range.
- Use the same volley and spread, but correlate successive launch angles with noise so the aim drifts smoothly.


- **World:** Compare smoother coherent terrain with the preceding independent random floor using the same footprint and a controlled height range.

- **Catalyst:** Earlier marks and motif addresses remain. A later field brush can be added once the terrain comparison is clear.

- **Counterpart:** Use the landform as cover. A coherent wandering path is an optional next addition, not needed to establish the floor difference.

- **Reuse:** NoiseSpace and the generation-17 biome's sampled ground and ecological placement. Reuse the landscape's placement logic progressively, not its full population at once.

- **Work remaining:** Configure noise frequency and octaves for demonstrably lower neighbouring height differences; equal height range alone does not guarantee smoothness.

- **Acceptance:** With recorded settings, neighbouring differences are lower than the random comparison; renderer, collision and object feet use the same field.

- **Sources:** `commons/context/walkgrids/NoiseSpace.gd`; `commons/artifacts/biome_object/biome_object.gd`; `commons/hazards/catalyst_counterpart/terrain_arena.gd`


### 12. Shaders — Proposal · not built

**One surface rule runs at every sample.**


**Current change list:**
- Let impacts create surface ripples and patterns on familiar forms.
- Give familiar balls strange animated surfaces, glow and patterns. Keep their trajectory unchanged so the shader effect is clear.


- **World:** Earlier colour and pattern fields become continuous surface responses, with one readable travelling mark or ripple.

- **Catalyst:** A hit supplies position, colour and time to the material; it does not secretly change the collider.

- **Counterpart:** Its impact is another input to the same material rule.

- **Reuse:** Existing shaping and pattern shaders, banner materials and biome paint texture. Shaders is currently missing from biome_vocabulary.json.

- **Work remaining:** Add a deliberate capability entry and a bounded hit-data adapter to one existing shader. Keep material effects distinct from physical terrain.

- **Acceptance:** Known hit inputs produce the intended pixel response while terrain ray hits remain unchanged. No shader-specific feature appears before this stage.

- **Sources:** `algorithms/shaders/book_of_shaders/shader_01_shaping.gd`; `algorithms/shaders/book_of_shaders/shader_05_patterns.gd`; `commons/biome_layers/biome_ground.gdshader`


### 13. Cellular automata — Proposal · not built

**A painted cell becomes a changing neighbourhood.**


**Current change list:**
- Let a shot seed cells in the floor. Neighbour rules spread the pattern over time.
- Let impacts seed floor cells. Expand the pattern in discrete steps using a visible neighbour rule.


- **World:** The addressed floor can advance a local rule in discrete generations; keep a permanent traversable base underneath.

- **Catalyst:** Seed or erase cells, then observe their next generation rather than immediately replacing an entire pattern.

- **Counterpart:** Its hits can seed the same rule, making local interventions share consequences.

- **Reuse:** Grid2D Game of Life cartridge and the batched ca_surface renderer. The old ca_surface runs several steps during construction only; it is not yet a live arena simulation.

- **Work remaining:** Separate cell state from draw buffers and use one bounded update clock, with pause, step and reset.

- **Acceptance:** A known oscillator alternates correctly without in-place update bias; a shot edits one seed cell; earlier movement and surface actions remain usable.

- **Sources:** `commons/substrates/grid2d/cartridges/cartridge_game_of_life.gd`; `commons/biome_layers/ca_surface.gd`


### 14. Fractals — Proposal · not built

**A form repeats at another scale.**


**Current change list:**
- Build cover that repeats at smaller scales. Limit how many levels can grow.


- **World:** Use bounded recursive structures as recognisable descendants of earlier cover.

- **Catalyst:** Select one branch or depth to unfold; preserve a parent-child record.

- **Counterpart:** An optional finite split creates smaller descendants; never unbounded head multiplication.

- **Reuse:** fractal_bloom actually builds recursive branching geometry. It needs a collider and interaction budget before it can provide shelter.

- **Work remaining:** Reuse the recursive builder with depth and instance caps; make selected branches collidable and others visual.

- **Acceptance:** Expected child counts and parent IDs hold at each depth; maximum instances are enforced and the exit remains clear.

- **Sources:** `commons/biome_layers/fractal_bloom.gd`; `commons/context/walkgrids/FractalSpace.gd`


### 15. L-systems — Proposal · not built

**A rewritten instruction grows a branch.**


**Current change list:**
- Grow branching structures from a rule. Let shots seed or prune them.


- **World:** Earlier line segments become branching structures placed within the existing habitat and clearances.

- **Catalyst:** Seed a short grammar or prune a branch; the next bounded rewrite changes the structure.

- **Counterpart:** Its route or shelter can grow through the same grammar; a new skin alone does not demonstrate rewriting.

- **Reuse:** Existing L-system trees, spawn service and the mature biome's tree placement. Retain earlier sculpture and cover candidates through biome_inheritance.

- **Work remaining:** Expose one production and its interpreted branch record; attach geometry and collision incrementally within a budget.

- **Acceptance:** The produced instruction and branch count match the rule; a retained panel is not replaced when vegetation arrives.

- **Sources:** `commons/biome_layers/lsystem_trees.gd`; `commons/biome_layers/spawn_service.gd`; `commons/artifacts/biome_inheritance/biome_inheritance.gd`


### 16. Procedural generation — Proposal · not built

**Candidate arrangements meet explicit constraints.**


**Current change list:**
- Generate different arrangements from a seed while keeping a walkable route.


- **World:** Seeded cover and habitat parts form a route under declared adjacency, clearance and occupancy rules.

- **Catalyst:** Commit a local choice or regenerate a bounded region while keeping its unaffected neighbours.

- **Counterpart:** It occupies the generated route, subject to the same placement constraints.

- **Reuse:** The mature biome already retains seed, cells and ecological relationships; inherited_form_clearance checks the space around retained forms.

- **Work remaining:** Add explicit route constraints and a rejection record; ecological proximity alone does not guarantee playable navigation.

- **Acceptance:** A fixed seed reproduces the composition. Rejected candidates state the failed constraint; start, refuge and exit remain connected.

- **Sources:** `commons/artifacts/biome_object/biome_object.gd`; `commons/biome_layers/inherited_form_clearance.gd`; `commons/biome_layers/dna_creatures.gd`


### 17. Soft bodies — Proposal · not built

**An impact changes a body's internal shape.**


**Current change list:**
- Let cover bend under impact and recover its shape.


- **World:** One yielding barrier returns from earlier rigid cover, while a fixed refuge remains.

- **Catalyst:** Push or pull the specimen; distinguish elastic recovery from a lasting edit.

- **Counterpart:** Its balls deform the same receiver, with contact following the real simulation.

- **Reuse:** The existing yielding-cube lesson and spring lattice are candidates. The legacy softbody_flora population is not proof of deformable collision.

- **Work remaining:** Adapt one tested body, pin its boundary and measure contact cost before enabling multiple deformable objects.

- **Acceptance:** A real impact changes vertices and subsequent contact; recovery and reset are measured; rigid cover remains available.

- **Sources:** `doc/book/studies/soft-bodies-through-the-hands/SoftBodies_Soft_Body_Deformation/yielding_cube.gd`; `algorithms/softbodies/spring_lattice/spring_lattice.gd`; `commons/biome_layers/softbody_flora.gd`


### 18. Isosurfaces — Proposal · not built

**A field edit changes a surface boundary.**


**Current change list:**
- Let shots add or remove field material. Update the visible surface and its collision.


- **World:** An earlier solid or terrain patch is reconstructed from a scalar field at a declared threshold.

- **Catalyst:** Add or remove field locally through the existing sculpture brush idiom.

- **Counterpart:** Later it may edit the same limited patch; first verify the player's operation and escape route.

- **Reuse:** The ISO sculpture workshop already binds to the museum's mc_sculpt_vr artifact and retains a field history. Its scene binding needs an arena adapter.

- **Work remaining:** Reuse field history and meshing through a declared receiver; synchronize collider updates and retain immutable route boundaries.

- **Acceptance:** Repeated brush edits produce the recorded field, mesh and collision revision; the player never stands on a visual-only replacement.

- **Sources:** `commons/artifacts/timing_machines/iso_sculpt_workshop.gd`; `commons/artifacts/timing_machines/iso_terrain_workshop.gd`


### 19. Boolean surfaces — Proposal · not built

**Two solids define union, intersection or difference.**


**Current change list:**
- Use the sphere to cut, join or intersect solid obstacles.


- **World:** A bounded obstacle can acquire a tunnel, a joined volume or an overlap from explicit operands.

- **Catalyst:** Place a sphere operand and choose the operation; preserve both inputs so the change can be read or undone.

- **Counterpart:** It uses the resulting opening; attack-driven subtraction is a later option, not needed for the first comparison.

- **Reuse:** The current Boolean_Verbs hall compares the same two operands. Reuse that contract rather than labelling an alpha fade as subtraction.

- **Work remaining:** Select the existing hall's solid builder after inspecting its receiver; bound geometry cost and refresh collision.

- **Acceptance:** Difference opens a real passage; disjoint intersection is empty; the same operand record can reproduce or restore the result.

- **Sources:** `commons/maps/Boolean_Verbs/tutorial.md`; `commons/maps/Boolean_Verbs/map_data.json`


### 20. Swarm intelligence — Proposal · not built

**Neighbours change one another's motion.**


**Current change list:**
- Let skulls coordinate through local neighbour rules. Use the catalyst to disturb the group.


- **World:** A small group moves through the retained terrain and cover using local rules.

- **Catalyst:** Disturb the group or leave a local attractor, then observe its response.

- **Counterpart:** Heads now negotiate neighbours rather than merely occupying indexed slots or prescribed orbits.

- **Reuse:** Use the actual boid implementation as a candidate. The old swarm_creatures layer only animates phase-offset orbits.

- **Work remaining:** Adapt separation, alignment and cohesion to a capped head group; share avoidance and neighbour-query budget.

- **Acceptance:** Changing one neighbour changes a focal head's trajectory. Disabling neighbour coupling removes that effect under the same initial state.

- **Sources:** `algorithms/emergentsystems/boidflocking/Boid.gd`; `commons/biome_layers/swarm_creatures.gd`


### 21. Graph theory — Proposal · not built

**An edge changes what can reach what.**


**Current change list:**
- Let changing a connection open or close a route between objects.


- **World:** Earlier landmarks become nodes in an explicit traversable or signal network.

- **Catalyst:** Connect or disconnect a declared edge; observe the changed route or reachable set.

- **Counterpart:** It follows the same graph; a connection can provide a detour rather than simply increase attack power.

- **Reuse:** The actual pathfinding artifact is a candidate. graph_connections draws proximity edges only; it does not implement traversal or alter the arena.

- **Work remaining:** Give edges real receiver semantics, stable node IDs and a route query. Current spine places Graph Theory before Machine Learning.

- **Acceptance:** Removing one bridge edge changes the computed reachable set; drawn edges match the graph actually used by movement.

- **Sources:** `algorithms/graphtheory/pathfinding3d/pathfinding3d.gd`; `commons/biome_layers/graph_connections.gd`


### 22. Machine learning — Proposal · not built

**Measured experience changes a parameter or policy.**


**Current change list:**
- Let a skull learn a response from examples. Compare it with an unchanged skull.


- **World:** Keep the same arena for a controlled comparison before and after learning or selection.

- **Catalyst:** Provide examples or alter an explicit objective; replay the same test conditions.

- **Counterpart:** A recorded policy changes one response, with its training evidence inspectable. More aggression is not the definition of learning.

- **Reuse:** The nature system's EvolutionSystem and current ML lessons are candidates. adaptive_behavior's pulsing halo is not a learning implementation.

- **Work remaining:** Choose one actual learning/selection model, specify data and objective, then expose its changed parameter beside an untrained baseline.

- **Acceptance:** A saved update changes held-out behaviour under fixed conditions; resetting learning restores the baseline. A glow alone cannot pass.

- **Sources:** `algorithms/nature_system/systems/evolution_system.gd`; `commons/maps/ML_Evolution/tutorial.md`; `commons/biome_layers/adaptive_behavior.gd`


### 23. Foundations crisis — Proposal · not built

**A claim carries the conditions of its test.**


**Current change list:**
- Expose a limit of an earlier rule. Let the player inspect what the rule leaves out.


- **World:** Return to an earlier apparently reliable arena rule and expose its domain, budget or counterexample.

- **Catalyst:** Inspect and challenge one claim through a finite, reproducible encounter.

- **Counterpart:** It need not gain another weapon; an unresolved or limited prediction can become the encounter.

- **Reuse:** Crisis_Synthesis already carries recorded trials, model identifiers, source hashes and checker results. The old paradox layer is rotating geometry, not a proof of undecidability.

- **Work remaining:** Select one bounded rule and preserve the evidence record; distinguish failed search from disproven claim and unknown from false.

- **Acceptance:** The display never upgrades a bounded search outcome into a universal claim; replay retains model and source identity.

- **Sources:** `commons/maps/Crisis_Synthesis/tutorial.md`; `commons/biome_layers/paradox_zones.gd`


### 24. QFEP laboratory — Proposal · not built

**An explicit control reaches an actual receiver.**


**Current change list:**
- Connect the catalyst to a real adjustable system. Show how its response changes.


- **World:** Expose a few measured parameters of the accumulated world without resetting its moving bodies.

- **Catalyst:** Use the sphere as a control source; read both requested and received values.

- **Counterpart:** Share a parameter that changes a concrete behaviour, keeping its effect observable rather than merely increasing difficulty.

- **Reuse:** QFEP Synthesis already maps controls to a SoftBody3D specimen and distinguishes settings from interpretation. tunable_field contains static indicators only.

- **Work remaining:** Reuse one explicit source-to-receiver mapping, then add telemetry for the actual object. Do not claim the dials measure a universal QFEP quantity.

- **Acceptance:** The receiver reports the changed coefficient and retains the same body/state; stopping a modulation does not falsely imply stopping all motion.

- **Sources:** `doc/book/studies/qfep-lineage/synthesis_study.gd`; `commons/maps/QFEP_Synthesis/tutorial.md`; `commons/biome_layers/tunable_field.gd`


### 25. After the foundations — Proposal · not built

**Recompose the world and inspect what the rule excludes.**


**Current change list:**
- Combine earlier abilities into a living biome. Let a former opponent become a source or companion.


- **World:** A small authored combination of earlier systems, with an editable route and an account of its choices.

- **Catalyst:** Build, connect, protect or transform using capacities already acquired; combat can be optional.

- **Counterpart:** A former opponent can become a moving force, collaborator or source in the composition.

- **Reuse:** The mature biome's seed and community records, inherited form clearances, and current critical lessons. critical_overlay's tinted dome is not evidence of measured bias.

- **Work remaining:** Choose one inspectable composition and one exclusion question; retain the source record and alternative instead of switching on every system.

- **Acceptance:** A changed rule yields a traceable changed arrangement; earlier object identities and earned capacities remain available; exit and replay stay usable.

- **Sources:** `commons/artifacts/biome_object/biome_object.gd`; `commons/artifacts/biome_inheritance/biome_inheritance.gd`; `commons/biome_layers/critical_overlay.gd`; `commons/maps/CriticalAlgorithms_Algorithmic_Bias_Visualization/tutorial.md`
