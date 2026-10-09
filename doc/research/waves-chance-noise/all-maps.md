# Waves, Randomness and Noise: every map

Read [HANDOFF.md](HANDOFF.md) first. Each room's status distinguishes planned work from reviewed encounters.

Active means on the current museum route. Extensions receive full plans but are not added to that route by this document.

## Wavefunctions · returning, relating, composing

A body can return without occupying the same state. A trace makes that return inspectable; projection and phase let repetition organise space; excitation and composition make several returns act together.

A specified state or coordinate, a reference for progression, and a rule relating them. Distinguish a dynamically integrated pendulum from a prescribed sine, and a moving pattern from transport of matter.

Keep the current six-room museum route for the first implementation. Unit Circle and Propagation are strong candidates for later insertion between the trace and Sine Space, after their footprints are repaired. Bernini, Cage, Sky Stairs and TrigWalkingPath remain independently developed extension rooms. Recheck transitions against the route actually shipped.

### WaveFunctions_Intro

**Active hall 1 in wavefunctions. Batch: PILOT. Partial probe evidence; required pickup/release untested.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### When a body returns to the same place, what has changed?

Body/layer: A suspended body; the player's releasing hand.

Proposed primary encounter: `control_pendulum`.

#### Starting evidence

The grabbable bob integrates angular acceleration, velocity and angle in _physics_process. Existing regime/evidence configurations include free/damped/driven behaviour and trace/longhand views; exports are not proof of visitor controls. The room also contains many transformation cubes. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 13, 'depth': 22, 'max_height': 4}. Current final: 613 words.

Current primaries: control_pendulum. Book anchors: control_pendulum.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Give the bob an open, reachable installation with its complete swing clear of plinth, neighbouring exhibits and circulation. Keep a still reference and a visible centre crossing; retain useful transformation comparisons as secondary.
2. Start with one release experiment. Offer a deliberate reveal of angle and signed angular velocity, using the existing evidence modes where suitable. If a damping comparison is added, change only that setting; do not introduce every regime at once.
3. Check the initial cube collection against old map structure before consolidating. Preserve meaningful stationary/prescribed-motion examples so a calculated pendulum is distinguishable from a cube following sin(time).

#### Revise final.md

1. Open with two visits to the centre that travel in opposite directions; invite a release before explaining.
2. Describe position, direction and turning points, then connect the short integration excerpt to the force work already learned.
3. Let a second release trouble a prediction. Avoid promising exact small-angle behaviour at large releases.
4. End with the need to keep a record: the next room gives elapsed history a spatial direction.

**Code to trace and quote after implementation:** control_pendulum.gd: _physics_process, _damping_multiplier, _on_bob_dropped. Quote the actual angle/velocity update; do not replace it with y=sin(t).

#### Evidence to return

- Exercise the real pickup/drop path and confirm the bob is reachable at both release positions.
- Record two centre crossings with opposite angular velocities; demonstrate the selected regime with its actual config.
- Measure the full installation bounds and check player clearance during a swing.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Choose the casing, material and way the motion leaves evidence. A delicate instrument or an oversized suspended body can both work if the reference remains readable.

**Reusable method:** R1 controlled comparison; R2 housed readout; R3 explicit time.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_Intro/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Intro/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Intro&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Intro)
- `res://commons/artifacts/control_pendulum/control_pendulum.tscn`
- `commons/artifacts/control_pendulum/control_pendulum.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_Pendulum

**Active hall 2 in wavefunctions. Batch: W1. Runtime report reviewed; actual input and headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Where does a movement put its past?

Body/layer: A moving bob and a finite spatial record.

Proposed primary encounter: `PendulumWave`.

#### Starting evidence

W1 now integrates on physics ticks and records timestamped positions under 300-mark and 10-second limits. FINE requests 25 ms; actual gaps at 60 Hz alternate around 16.7/33.3 ms and are visible on the housed readout. COARSE requests 200 ms; STROBE follows the measured period. Frame, panel and history lane are staged in the open south half. Map-controlled placement and recovered platforms retained. See w1-review.html; reach, collision and rendered appearance are unverified.

Current map dimensions: {'width': 13, 'depth': 21, 'max_height': 4}. Current final: 656 words.

Current primaries: PendulumWave. Book anchors: PendulumWave.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Stage the bob and trace side-on with an unobstructed view along history. Place the numerical display beside the trace, not over it.
2. Show retained samples, sampling policy and retained duration. Prefer a bounded fixed-time sampler independent of render frequency, or make the current frame-based sampling explicit; record that decision and preserve the original version in the before snapshot.
3. Add a local trace reset/replay only if implemented and reachable. Reset this experiment's buffer and time, never the game clock. Compare two sampling intervals while keeping the motion driver fixed.

#### Revise final.md

1. Begin with the apparent second body behind the bob; ask what direction the record is travelling.
2. Let the reader locate two equivalent crossings and count intervening samples.
3. Show the actual append/evict code and explain that depth encodes elapsed history.
4. Let the oldest mark disappear in the prose. Relate this chosen memory to Point_Trace, then hand the periodic value to Sine Space.

**Code to trace and quote after implementation:** PendulumWave.gd: _physics_process, _draw_trail, recorded_interval_range, _update_readout. Source the append/evict block; distinguish target timing, actual timestamps and finite history.

#### Evidence to return

- At two render rates, record sample count and time span under the chosen policy.
- Verify old samples are evicted and memory use stabilises.
- Capture the bob, whole trail and readable cased count in the museum.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Use a conveyor, ribbon, scored sheet or another legible carrier of history. The count and finite retention must remain discoverable.

**Reusable method:** R2 housed readout; R3 explicit time; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_Pendulum/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Pendulum/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Pendulum&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Pendulum)
- `res://algorithms/wavefunctions/oscillation_driver/PendulumWave.tscn`
- `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_Sine_Space

**Active hall 3 in wavefunctions. Batch: W1. Runtime report reviewed; actual input and headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What kinds of passage can a repeating rule make?

Body/layer: The world around the player's moving body.

Proposed primary encounter: `sine_wall_corridor`.

#### Starting evidence

Runtime fixes produce a 7 m corridor with 4.5 fundamental cycles, floor at its origin, a thin supporting collision slab and no wall collision. One case remains at the west nook; rolling colour balls were removed from this hall. 57 probe checks report no failures: emitted controls, local-X gap and capsule routes. Shared sculpture-clear rectangles reserve the approach. Actual desktop input and headset checks remain open; see runtime-review.html.

Current map dimensions: {'width': 14, 'depth': 36, 'max_height': 8}. Current final: 1035 words.

Current primaries: sine_wall_corridor, sine_flow_tray. Book anchors: sine_flow_tray, sine_wall_corridor.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Retain an observation route through or alongside the animated installation. Establish actual world bounds, orientation and minimum gap before calling it traversable architecture.
2. Make amplitude and the relative phase of the two walls available as separate comparisons. Keep frequency and material stable initially; add local freeze for inspecting the same instant if needed.
3. Choose an honest physical contract: static collidable demonstration states rebuilt on deliberate changes, or animated visual skins around a stable passage. If animated collision is chosen, test the update budget and trapping cases. Mark the simulation's boundary and retain a clear museum bypass.

#### Revise final.md

1. Enter through a gap and notice how facing surfaces disagree; let the body supply the first question.
2. Compare moving the viewer through space with holding position while phase changes.
3. Read one actual sine contribution before the sum. Distinguish wavelength across space from temporal rate.
4. Return to the gap: a visible wall and a colliding wall may have different powers. End at the sound room on the current route, not an absent extension.

**Code to trace and quote after implementation:** SineWallCorridor.gd: _wave_displacement, _create_wall_mesh, gap_at, gap_range, _evaluate_color. Running phase enters once via phase_shift; x-gap compares matching local Z coordinates.

#### Evidence to return

- Measure minimum clearance across the exposed parameter range.
- Walk the implemented route with the actual player collider; record which surfaces collide.
- Verify freeze/parameter changes reach the displayed material or mesh and do not leave stale colliders.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Plush folds, architectural ribs or a translucent membrane are welcome. Choose a material that makes the crests and the gap readable.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R5 museum/arena boundary.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_Sine_Space/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Sine_Space/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Sine_Space&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Sine_Space)
- `res://algorithms/wavefunctions/sine_wall/sine_wall_corridor.tscn`
- `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd`
- `res://commons/artifacts/sine_flow_tray/sine_flow_tray.tscn`
- `commons/artifacts/sine_flow_tray/sine_flow_tray.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_Unit_Circle

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### How does going around become rising and falling?

Body/layer: A rotating point, its projections and a sampled construction.

Proposed primary encounter: `unit_circle_advanced`.

#### Starting evidence

Currently outside the museum route. UnitCircle.gd supports correspondence and progressive/complete configurations; builds a finite number of steps and then stops. Wave length defaults to 28 m, beyond the 14×17 source map unless staged/scaled deliberately. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 14, 'depth': 17, 'max_height': 4}. Current final: 412 words.

Current primaries: unit_circle_advanced. Book anchors: unit_circle_advanced.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Preserve the projection construction. Identify angle progression, x=cos(angle), y=sin(angle) and the graph's separate horizontal coordinate using matched points/rods.
2. Offer replay and a manageable local phase scrub, reusing current correspondence variants. Keep the first encounter sine/cosine; tangent and helix can remain optional.
3. Separate a hand-scale explanatory graph from any walkable bridge. Restore or extend the original arena only after footprint inspection; do not squeeze a long bridge into the museum walls by hiding its ends.

#### Revise final.md

1. Ask which height will appear next, then follow one point from circle to graph.
2. Return to the same height twice and notice what the projection lost.
3. Introduce the real sine/cosine code and the changed meaning of the graph axis.
4. Close toward Propagation in this extension route; if inserted on the spine, revise both neighbours and the book handoff together.

**Code to trace and quote after implementation:** UnitCircle.gd: _update_rotator_and_indicators, _create_bridge_step, _process. Record sample count and completion condition.

#### Evidence to return

- Check four quarter-turn correspondences and replay after completion.
- Confirm every graph sample and any physical tread remain within the intended stage.
- Do not call the bridge walkable without entrance, support and exit tests.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable may choose a circular table, moving pointer or spatial unfolding. Maintain exact correspondence, not merely a circle beside a decorative wave.

**Reusable method:** R1 controlled comparison; R2 housed readout; R5 arena boundary.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_Unit_Circle/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Unit_Circle/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Unit_Circle&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Unit_Circle)
- `res://algorithms/wavefunctions/unit_circle/unit_circle.tscn`
- `algorithms/wavefunctions/unit_circle/UnitCircle.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_3D_Wave_Propagation

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Does a crest travel, or do neighbours make it again?

Body/layer: A connected array of oscillating bodies.

Proposed primary encounter: `coupled_oscillator_lattice`.

#### Starting evidence

Outside the current museum route. The lattice computes neighbour coupling and exposes apply_displacement. It has nodes/bonds/sheet/boundary views. Random excitation currently uses a probability per rendered frame; integration order and step stability need inspection before quantitative claims. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 16, 'depth': 22, 'max_height': 5}. Current final: 411 words.

Current primaries: coupled_oscillator_lattice. Book anchors: coupled_oscillator_lattice.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Build a reachable excitation point that produces one local pulse; compare coupling zero with a nonzero value from the same initial state.
2. Use the existing node/bond views to reveal the relation between cells. Show a selected cell's displacement beside the local pair; let the visitor locate the delayed response.
3. Use a stable simulation step and separate old/new state if needed so array iteration order does not supply an unacknowledged preferred direction. Bound the energy/input range and expose the finite boundary.

#### Revise final.md

1. Follow one marked sphere while the disturbance spreads elsewhere.
2. Repeat with the neighbours disconnected, then ask what carried the change.
3. Read the restoring, damping and neighbour terms from the implemented update.
4. Let the edge interrupt the idea of an unlimited medium; keep wave motion distinct from a transported object.

**Code to trace and quote after implementation:** coupled_oscillator_lattice.gd: _apply_excitation, _update_oscillators, _get_neighbors, apply_displacement. Cite whichever time-stepping scheme actually ships.

#### Evidence to return

- From the same initial state, compare zero/nonzero coupling at selected cell times.
- Check bounded behaviour at the maximum offered setting.
- Verify boundary handling and that any pulse control triggers only the intended lattice.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Could be linked pearls, a fabric or architectural joints. Keep a way to see individual motion under the larger pattern.

**Reusable method:** R3 explicit time; R6 local state/seed; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_3D_Wave_Propagation/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_3D_Wave_Propagation/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_3D_Wave_Propagation&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_3D_Wave_Propagation)
- `res://algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.tscn`
- `algorithms/wavefunctions/coupled_oscillator_lattice/coupled_oscillator_lattice.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_Effect_Sound

**Active hall 4 in wavefunctions. Batch: W2 review. Claude implementation retained; Astra desktop review passed 100 checks on 12 September; listening and headset pending.**

[Current review, images and listening](/research/possible-bodies/effect-sound.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What changes when one oscillation enters another's rule?

Body/layer: Two hand-controlled parameters, an audible body and its trace.

Proposed primary encounter: `DualBallFMController`.

#### Starting evidence

The working two-desk phase-modulation instrument has held A/B audition and a short rescaled scope. Claude repaired the labels and removed the empty platform cell enclosing the readout. Astra independently reproduced 100 passing live checks with clean exit, preserved hand state and unchanged production sources. The final and supporting tutorial now follow the actual primary. The scope normalises modulation depth out of its orange lane above the small denominator threshold; the sound and its picture need separate interpretation.

Current map dimensions: {'width': 14, 'depth': 16, 'max_height': 4}. Current final: 729 words.

Current primaries: DualBallFMController. Book anchors: DualBallFMController.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Retain the repaired desks, low readout, name labels, scope and clear operating area. The current desktop view passes review.
2. During the later headset visit, inspect the small ball targets and audition labels from comfortable standing positions. Keep tracked-hand findings separate from the desktop probe.
3. Review the crowded backs of secondary displays from the hall entrance. Improve a specific sightline without removing useful instruments.

#### Revise final.md

1. Completed: the opening carries Sine Space into the phase-modulation encounter.
2. Completed: keep a reference, change one index or decay, listen, then read the production expression.
3. Completed: disclose the scope window and lane rescaling without claiming an image proves hearing.
4. Next: use a person's listening observations to refine descriptions; continue to AirMusic's struck response.

**Code to trace and quote after implementation:** DualBallFMController.gd: _on_carrier_changed, _on_modulator_changed, _generate_fm_sound, _fm_sample. Show actual sample rate/ranges only after checking the configured instance.

#### Evidence to return

- Independent isolated live run: 100 checks, zero failures, exit 0; original saved hand unchanged.
- Operating and close-readout captures inspected. Scope normalisation and all 11 tutorial/final code excerpts checked against the production source.
- Three exact probe-rendered WAVs and two labelled comparison pairs are available on the review page. A listening judgement and headset visit remain pending.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

An intimate duet or an extravagant instrument can work. Preserve the one-parameter listening task and room for awkward timbres.

**Reusable method:** R1 controlled comparison; R2 housed readout; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_Effect_Sound/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Effect_Sound/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Effect_Sound&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Effect_Sound)
- `res://algorithms/wavefunctions/mariocontrol/DualBallFMController.tscn`
- `algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`
- `commons/interfaces/value_mapper_3d.tscn`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Wavefunctions_Bernini

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Can a rhythm stand still as architecture?

Body/layer: A twisted column and a changing viewpoint.

Proposed primary encounter: `bernini_columns`.

#### Starting evidence

Outside the museum route. The mesh uses height-dependent sine/cosine and is also rotated as a whole. Existing colonnade modes include grid, ring, aisle and pair. Generated accompanying audio is not evidence of touch-driven sound. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 20, 'depth': 16, 'max_height': 3}. Current final: 419 words.

Current primaries: bernini_columns. Book anchors: bernini_columns.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Use the existing pair or aisle configuration to compare an untwisted reference and a twisted shaft with whole-object rotation initially stopped.
2. Let one control vary twist/density while material and height remain fixed; expose whole-object rotation as a separate second operation.
3. Fit the full column height and base inside a deliberate stage. Keep architectural atmosphere and optional dress/speech objects if they contribute an identifiable secondary encounter.

#### Revise final.md

1. Walk around an apparently moving twist before any motor starts.
2. Separate a profile that changes with height from an object rotating through time.
3. Read the mesh-coordinate construction, connecting back to Transformation.
4. Ask what makes the result a column when structural support is not simulated; keep any historical attribution limited to verified inspiration.

**Code to trace and quote after implementation:** BerniniColumns.gd: generate_spiral_column_mesh, _process, _plan_pair/_plan_aisle. Inspect the loaded base scene too.

#### Evidence to return

- Freeze whole-object rotation and show that twist persists.
- Vary twist at fixed height and check the reference remains unchanged.
- Verify wall/ceiling clearance and whether any load-bearing claim has a real mechanism.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

The ornament can be excessive and desirable. Fable chooses its material and arrangement; the two kinds of change must remain separable.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping.

#### Open and inspect

- Map: `commons/maps/Wavefunctions_Bernini/map_data.json`
- Book and supporting texts: `commons/maps/Wavefunctions_Bernini/`
- [Primary view](http://localhost:3003/necklace/thread?map=Wavefunctions_Bernini&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=Wavefunctions_Bernini)
- `res://algorithms/wavefunctions/berninicolumns/BerniniScene.tscn`
- `algorithms/wavefunctions/berninicolumns/BerniniColumns.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_John_Cage

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What has already been composed before chance begins?

Body/layer: A listening body inside a scheduled sound collection.

Proposed primary encounter: `john_cage_tech_noir`.

#### Starting evidence

Outside the active route. The scene generates a finite vocabulary of sounds and schedules events. There are separate RNG paths for threaded generation and other operations; chance_seed does not by itself establish full audio replay. Names and visuals do not establish spatialised sound sources. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 6}. Current final: 419 words.

Current primaries: john_cage_tech_noir. Book anchors: john_cage_tech_noir.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Provide a listening position, a small event ledger and an optional view of the available vocabulary. The first encounter should allow attention to settle before explanations accumulate.
2. If offering repeat, seed both generation and scheduling or record/replay the event schedule. A frozen visual ensemble must not be labelled repeated audio.
3. Inspect generation time, memory and thread teardown; avoid concurrent heavy sound generation from neighbouring halls. Add a reliable local stop/leave path while preserving the intended composition.

#### Revise final.md

1. Begin with an event arriving against a continuing background; ask what could arrive next.
2. Listen again for a recurring vocabulary rather than demanding a melody.
3. Show the actual selection/scheduling fragment after that discovery.
4. Treat the Cage title as a reference, not a performance of a named score. Carry finite choice into Randomness or return to AirMusic in an extension path.

**Code to trace and quote after implementation:** john_cage_tech_noir.gd: _thread_generate_sounds, _process, play_random_effect, RNG setup and visual chance configuration. Audit the per-frame threshold draw.

#### Evidence to return

- Capture a short timestamped event sequence and identify its eligible sound pool.
- If replay is implemented, compare two complete event logs, not only colours.
- Check leaving during generation and re-entering without leaked threads or audio.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Let silence, delay and spatial arrangement matter. No need to turn this into a quiz or make every sound visible.

**Reusable method:** R3 explicit time; R6 local state/seed; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_John_Cage/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_John_Cage/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_John_Cage&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_John_Cage)
- `res://algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.tscn`
- `algorithms/wavefunctions/technoirgameaudio/john_cage_tech_noir.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_AirMusic

**Active hall 5 in wavefunctions. Batch: W3 review. Claude staging retained; sampled scope added and 67 independent desktop checks passed; headset/listening pending.**

[Current review, images and listening](/research/possible-bodies/air-music.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What continues after your hand has left?

Body/layer: A struck instrument, overlapping decays and a chosen tuning.

Proposed primary encounter: `resonating_metallophone`.

#### Starting evidence

The existing striker, eight bars, table, cradle and return remain. The table scope now reads 512 samples over 12 ms near each bar's own playback position, including player gain and the final PCM fade, before spatial/bus/device processing. Independent decoding and ribbon geometry checks pass alongside the retained collision, overlap, return and route checks. Book hero and primary now both name the metallophone. The audio generator is unchanged.

Current map dimensions: {'width': 13, 'depth': 12, 'max_height': 3}. Current final: 765 words.

Current primaries: resonating_metallophone. Book anchors: resonating_metallophone.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Keep the tested table, left-end striker rest, protected operating strip and independent bar voices.
2. On the later headset visit, test actual held-stick reach, safe return and readout legibility with more voices.
3. Assess the secondary captions and ambient layers by standing and listening in the room before changing them.

#### Revise final.md

1. Completed: connect Effect Sound to contact ending before its response.
2. Completed: distinguish same-bar restart from two simultaneous voices, with separate ages.
3. Completed: explain generated PCM, the three-second decay constant, finite ending and 12 ms source window.
4. Next: carry separate terms and timing into the existing Synthesis Lab; use listener observations to refine the prose.

**Code to trace and quote after implementation:** ResonatingMetallophone.gd: _create_single_bar, _create_stick, _tuned_scale; follow resonating_bar.tscn to the actual synthesis/strike code.

#### Evidence to return

- 67 checks, zero failures, engine exit 0. Original saved hand and Claude's dated reports preserved.
- New scope samples independently compared with PCM, player gains and the actual ribbon vertices; two differing playback ages recorded.
- Two unchanged bar buffers exported; the review page compares them sequentially and overlapping. Listening and tracked-hand evidence remain pending.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable can dress the instrument lavishly or make it very spare. Keep the contact and continuing response easy to distinguish.

**Reusable method:** R1 controlled comparison; R2 housed readout; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_AirMusic/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_AirMusic/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_AirMusic&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_AirMusic)
- `res://algorithms/wavefunctions/resonance/resonating_metallophone.tscn`
- `algorithms/wavefunctions/resonance/ResonatingMetallophone.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Wavefunctions_Sky_Stairs

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### When does a sampled curve become a route for a body?

Body/layer: The player's feet, treads and a varying-radius spiral.

Proposed primary encounter: `sine_cylinder_staircase`.

#### Starting evidence

Outside the museum route. The placed scene sets WAVE_AMPLITUDE=0.45. The script constructs 80 treads with rise, turn and radius variation; membrane/none/rail/posts provisions already exist. Collider height offset and bridging geometry require a physical check. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 10}. Current final: 424 words.

Current primaries: sine_cylinder_staircase. Book anchors: sine_cylinder_staircase.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Recover the original footprint and start/end platforms before adapting this tall staircase to a hall.
2. Build one tested climb with entrance, headroom, continuous support and an exit; include a museum bypass. Correct any mismatch between visible tread and collider, rather than hiding it with an invisible lift.
3. Compare wave amplitude zero/nonzero at fixed rise/turn, or a short paired tread sample if a full second climb is too large. Keep the changed geometric variable explicit.

#### Revise final.md

1. Begin at the first tread and ask whether the smooth-looking spiral can carry the reader.
2. Inspect centres and edges separately, then try the tested ascent.
3. Quote the real sampled angle/radius/height construction.
4. Make the difference between curve continuity and bodily access tangible. A changed stride can expose a gap without the equation being wrong.

**Code to trace and quote after implementation:** sine_cylinder_staircase.gd: _compute_samples, _build, _add_plane_bridge, provision code; inspect COLLIDER_HEIGHT_OFFSET in world space.

#### Evidence to return

- Traverse from entry to exit with actual player dimensions and record collision alignment.
- Check the offered amplitude range for gaps/head clearance.
- Capture the whole route, not only an attractive crop of the middle.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Rail, posts or membrane may be chosen for what they do. Keep the support contract visible and the comparison controlled.

**Reusable method:** R4 sample-to-body mapping; R5 arena boundary.

#### Open and inspect

- Map: `commons/maps/Wavefunctions_Sky_Stairs/map_data.json`
- Book and supporting texts: `commons/maps/Wavefunctions_Sky_Stairs/`
- [Primary view](http://localhost:3003/necklace/thread?map=Wavefunctions_Sky_Stairs&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=Wavefunctions_Sky_Stairs)
- `res://algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.tscn`
- `algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_TrigWalkingPath

**Authored extension — outside the current museum route. Batch: W-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### How can two continuing motions make a quiet interval?

Body/layer: Two sources and their combined excursion.

Proposed primary encounter: `beat_frequency_demo`.

#### Starting evidence

Outside the museum route. The current primary shows A, B and A+B and has two frequency sliders. It is visual and silent. TrigWalkingPath and other waves are also placed; the name alone does not establish a walking experiment. Structure recovery on 10 September: interior 2 cells are one-metre platforms, perimeter 2 cells are explicit w walls, museum.wall_height is 3, and gate_depth_rows is 0. Preserve this contract; see recovery.html and the dated doc/space archive.

Current map dimensions: {'width': 14, 'depth': 14, 'max_height': 4}. Current final: 407 words.

Current primaries: beat_frequency_demo. Book anchors: beat_frequency_demo.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Make the three rows large enough to compare from one position, with frequencies and their difference in a side casing.
2. Provide close-frequency and equal-frequency baselines. Keep a visible reference location across the three rows; preserve input amplitudes as the sum narrows.
3. Decide whether the placed walking path adds a distinct bodily test. If so, make it a secondary, collidable application with separate controls; otherwise keep this hall a clear superposition encounter rather than inventing traversal.

#### Revise final.md

1. Ask whether both sources stopped when the sum became small.
2. Hold A fixed, move B closer, and follow the broad envelope before naming beats.
3. Read the actual A+B expression and frequency difference, explaining cancellation at a chosen sample.
4. Do not promise audible beats without audio. Carry component relationships into Synthesis Lab.

**Code to trace and quote after implementation:** beat_frequency_demo.gd: _animate_spheres, _update_beat_label, _create_controls. Check labels against the visible envelope convention.

#### Evidence to return

- At equal frequencies and matched phase, compare A, B and sum samples.
- At nearby frequencies record the envelope over a sufficient interval.
- Exercise both sliders and verify input rows still move during cancellation.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable may add an honest audible comparison or preserve silence. Any added modality must read the same parameters and be separately verified.

**Reusable method:** R1 controlled comparison; R2 housed readout.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_TrigWalkingPath/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_TrigWalkingPath/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_TrigWalkingPath&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_TrigWalkingPath)
- `res://algorithms/wavefunctions/beat_frequency/beat_frequency_demo.tscn`
- `algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### WaveFunctions_Synthesis_Lab

**Active hall 6 in wavefunctions. Batch: W4 review. Claude staging retained; recipe labels repaired; 110 independent desktop checks passed; headset pending..**

[Current review, images and listening](/research/possible-bodies/synthesis-lab.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What shape can several simple returns make together?

Body/layer: A composite signal with visible component bodies.

Proposed primary encounter: `additive_wave_demo`.

#### Starting evidence

The five-slider bench, component ladder, marker and three controls remain. Recipe recognition now checks all five ratios and distinguishes zero, single sines and the positive odd 1/n² mix. The map layers and all 25 placements are preserved. The book hero is corrected to additive_wave_demo. This primary is visual; it does not play its sum as sound.

Current map dimensions: {'width': 15, 'depth': 14, 'max_height': 4}. Current final: 933 words.

Current primaries: additive_wave_demo. Book anchors: additive_wave_demo.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Keep the reviewed bench, miniature hallway, recovered platforms and protected approach routes.
2. Later headset visit: check handle reach, upper lettering and high-amplitude curves extending beyond the dark backing.
3. A later material or motion specimen should share the actual coefficients and be reviewed separately; none is connected by this change.

#### Revise final.md

1. Completed: connect AirMusic independent beginnings to the shared phase of this bench.
2. Completed: remove and rebuild contributions before explaining the real sum and slider code.
3. Completed: examine naming tolerance, hidden small terms and finite corners without claiming arbitrary periodic shapes.
4. Next: Random_Definition and what state must be retained for replay.

**Code to trace and quote after implementation:** additive_wave_demo.gd: _calculate_wave_value, _on_harmonic_changed, set_preset, NUM_HARMONICS and WAVE_POINTS.

#### Evidence to return

- 110 checks, zero failures, exit 0; original saved hand and Claude evidence preserved.
- Ten coefficient configurations tested through slider paths; all 256 drawn samples independently compared, worst error below 9e-8.
- Current desktop captures and thirteen checked production-code excerpts; no headset or human listening claim.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Choose a compelling bodily use for the sum, or keep the instrument alone. Five clear contributions are more useful than an uncontrolled wall of sliders.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/WaveFunctions_Synthesis_Lab/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Synthesis_Lab/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Synthesis_Lab&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Synthesis_Lab)
- `res://commons/artifacts/additive_wave_demo/additive_wave_demo.tscn`
- `commons/artifacts/additive_wave_demo/additive_wave_demo.gd`
- `commons/interactables/slider_horizontal.tscn`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

## Randomness · choosing, accumulating, excluding

A reproducible procedure supplies choices; an eligibility rule and distribution decide their possibilities; accumulated choices form paths and populations; feedback and uncertain timing alter what a body can do.

A defined outcome space and selection procedure. Seed/state, draw order, distribution, boundary and interpretation are different decisions. A histogram cannot recover the order it discarded.

Keep the seven active halls while improving all fourteen authored maps. The extension rooms supply concrete routes into estimation, feedback and correlation; they are not automatically extra museum halls. In particular Random_Space_Geometry and Random_Space overlap the next sequence: use them as comparison laboratories, not duplicate introductory lectures.

### Random_Definition

**Active hall 1 in randomness. Batch: PILOT. 65 desktop checks passed; slider and contrast repaired; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-definition.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Can a surprise return exactly?

Body/layer: A coloured field, a seeded procedure and the visitor's expectation.

Proposed primary encounter: `seed_replay_demo`.

#### Starting evidence

Claude's west-facing table at (8,11) is clear of the west entropy cloud. All 15 placements remain. The seed slider used an obsolete node path; it now selects and displays integer seeds 0–999, synchronizing after RANDOM and rebuild. Local panel plates and lettered tags are unshaded, the cased action readout is larger, and repeat contrast passes preserve font size. 65 independent desktop checks pass, including exact colours, independent draw reconstruction, actual pointer drag, all three buttons, unload and rebuild. The engine still reports one resource at shutdown; headset reach and fine lettering remain unverified.

Current map dimensions: {'width': 13, 'depth': 22, 'max_height': 3}. Current final: 643 words.

Current primaries: seed_replay_demo. Book anchors: seed_replay_demo.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Reviewed: replicas, REPLAY and +1 DRAW compare a fixed seed under a changed draw procedure. The same 64 cube positions remain; RGB assignments shift by one draw.
2. Reviewed: the seed slider now uses the actual panel path and integer readout; RANDOM may repeat a seed. The local generators leave shared random state untouched.
3. Preserve Claude's table, clear east approach and west entropy cloud. All 15 placements and map layers remain. Later: check tracked-hand reach and text size, and investigate the shutdown resource warning separately.

#### Revise final.md

1. Retain the patch-and-replay opening, linked from Synthesis Lab: what state must be kept for a result to return?
2. Let the reader break the match before showing the discarded draw and the actual three-call RGB assignment.
3. Notice that a continuous hand movement selects integer seeds, and that more seeds leave the 64-cell representation fixed.
4. Keep an offset palette as a possible result. Carry its arrangement into Random_Entropy, where counts can remain while order changes.

**Code to trace and quote after implementation:** seed_replay_demo.gd: _column_seeds, _regenerate, _randomize_seed. Preserve global game RNG state; any extra-draw experiment uses an artifact-local generator.

#### Evidence to return

- 65 independent desktop checks, zero assertion failures, exit 0. One ObjectDB/resource shutdown warning remains; no headset claim.
- Seed 42 exports 193 source draws and both 64-cell RGB assignments. Exact bytes and independent generator reconstruction agree; matched cameras show the difference.
- Actual slider move paths plus a desktop pointer drag, all three buttons, and slider/replay after unload and rebuild were exercised.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable can choose fabric swatches, lit cubes or another clear carrier for the same samples. Keep the source of the difference inspectable.

**Reusable method:** R1 controlled comparison; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Random_Definition/map_data.json`
- Book and supporting texts: `commons/maps/Random_Definition/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Definition&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Definition)
- `res://algorithms/randomness/seed_replay/seed_replay_demo.tscn`
- `algorithms/randomness/seed_replay/seed_replay_demo.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Entropy

**Active hall 2 in randomness. Batch: R1. 149 desktop checks passed; text and control contrast reviewed; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-entropy.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Which differences disappear when a sequence becomes one number?

Body/layer: A symbol stream, its histogram and a measuring apparatus.

Proposed primary encounter: `shannon_entropy_meter`.

#### Starting evidence

Claude's staged meter now provides SORT, CONTRAST and DISCLOSE. The 200-tile ribbon moves while the enlarged first forty retain their original neighbours. Counts and marginal H are invariant under sorting; a second cached weighted sample changes the shares. Local button contrast, panel size and the excerpt caption are corrected. All nine placements remain declared; eight build, while secondary replay_casino lacks a living scene. Headset review and recorded engine diagnostics remain open.

Current map dimensions: {'width': 18, 'depth': 12, 'max_height': 3}. Current final: 1096 words.

Current primaries: shannon_entropy_meter. Book anchors: shannon_entropy_meter.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Reviewed: sorting permutes tile positions without changing the sampled sequence, counts or H; the enlarged first forty stay as drawn.
2. Reviewed: CONTRAST selects one of two cached local seeded samples over ten symbols and 200 draws. Source expectations follow the active law through both disclosure/contrast orders.
3. Improved: unshaded local panel backing and lettered tags, larger controls, larger first-forty caption without a false uniform magnification claim.
4. Preserve map geometry and the prior build-once, bar-lift and ghost-law repairs. Later: tracked-hand reach, fine text, missing secondary replay_casino scene and recorded engine diagnostics.

#### Revise final.md

1. Choose neighbouring colours, sort and discover what holds still before reading the count and entropy loops.
2. Keep the enlarged original excerpt beside the rearranging ribbon: different arrangements can enable different uses with the same H.
3. Inspect four zero-count marks and the changing histogram denominator. Display height is another translation of the sample.
4. Distinguish positions lost to counts from counts condensed into H. Carry the question of an eligible set into Random_Remove.

**Code to trace and quote after implementation:** shannon_entropy_meter.gd: _measure, set_sorted, set_contrast, active_probabilities and disclosure. The primary samples are fixed at build; no visitor resampling control.

#### Evidence to return

- 149 independent desktop checks, zero assertion failures, exit 0. Real pointer/buttons, active-law ghosts, endpoint samples, access and unload/rebuild exercised; headset unverified.
- Two complete 200-symbol samples exported; counts and H independently reconstructed. Three desktop captures share the same camera pose.
- All 40 enlarged colours match their symbols within stored colour precision (maximum channel error 0.000386834; palette separation above 0.19199). The strip stays fixed under SORT.
- No script errors. Unrecognized bus UID, root-certificate and logger errors plus an ObjectDB shutdown warning remain recorded separately from assertions.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

A ledger, sorting machine or rearranged ribbon can carry the argument. The invariant must be visible before the formula explains it.

**Reusable method:** R1 controlled comparison; R2 housed readout; R7 measurement contract.

#### Open and inspect

- Map: `commons/maps/Random_Entropy/map_data.json`
- Book and supporting texts: `commons/maps/Random_Entropy/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Entropy&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Entropy)
- `res://commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.tscn`
- `commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Remove

**Active hall 3 in randomness. Batch: R1. 87 desktop checks passed; existing bench preserved; text aligned; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-remove.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Who was eligible to disappear?

Body/layer: A selected set of cells and the spaces left behind.

Proposed primary encounter: `remove_random`.

#### Starting evidence

The existing owned bench has controls at right and a cased status at left. All three placements remain declared; remove_random and dark_sphere build, while hazards_demo has no living scene. 87 independent desktop checks pass, including full histories, row/column offset identity, cancellation and rapid presses. No production script or map layer changed. Book and registry prose no longer describe a hunt for the host map grid.

Current map dimensions: {'width': 13, 'depth': 18, 'max_height': 3}. Current final: 1034 words.

Current primaries: remove_random. Book anchors: remove_random.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Retain the owned 64-instance bench, persistent slot plates, right panel, left status and clear rectangle [[3,4,10,11]].
2. Reviewed: seven existing buttons; RESET restores original transforms and replays the seed; mode changes reset. No visitor START/STOP or seed-entry field.
3. Reviewed: ROW and COLUMN each remove eight cells with identical offsets under seed 777; ALL removes every cell once. Pending removals cancel on reset or mode change.
4. Later: headset approach/lettering; the missing secondary hazards_demo; legacy capture harness inputs/measurements; recorded startup diagnostics and generated decoration build times.

#### Revise final.md

1. Follow a grey cube through removals before reading eligibility, draw and zero-scaling as three operations.
2. Compare equal-sized ROW and COLUMN masks under one seed; distinguish this from changing the draw bounds with RANGE or ALL.
3. Inspect the persistent address, original transform and internal removal log. Visible absence retains the means of return.
4. Pause over an unfinished pattern. Exhausting the same range loses its visible history. Carry the changing set into Random_Walk.

**Code to trace and quote after implementation:** RemoveRandom.gd: _should_include_instance, find_all_instances, remove_one, set_random_seed; remove_random_fixture.gd for actual controls/collision.

#### Evidence to return

- 87 independent desktop checks, zero assertion failures, exit 0. Source stable during run; original saved hand preserved; no headset observation.
- Six complete captured histories, 128 removal entries; replay identical and every order a permutation of its eligible set. ROW/COLUMN offsets 7,0,4,2,1,1,0,0 at seed 777.
- Museum routes, real pointer REMOVE ONE/RESET, masks, exhausted set, rapid presses, pending reset/mode change and unload/rebuild checked.
- No script errors or shutdown leak warning in this run. Startup/renderer diagnostics and slow generated decorations remain recorded.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

The disappearing cells may become an invitation, excavation or interrupted pattern. Preserve the inspectable selection rule.

**Reusable method:** R1 controlled comparison; R5 arena boundary; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Random_Remove/map_data.json`
- Book and supporting texts: `commons/maps/Random_Remove/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Remove&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Remove)
- `res://algorithms/randomness/remove_random.tscn`
- `algorithms/randomness/RemoveRandom.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Randomness_10_PRINT_Algorithm

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### How much world can two choices make?

Body/layer: A binary mark, a wall and an agent's proposed path.

Proposed primary encounter: `ten_print_maze_3d`.

#### Starting evidence

Outside the active route. The generator has stroke/character/wall/tile modes, random diagonals, an ant/navigation grid and timed wall changes. It uses global seed/random calls; a new local RNG is needed for reliable isolation. Animated walls and navigation must be checked for agreement. Platform/wall recovery on 10 September: 1 interior cells restored as platforms; 0 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 6}. Current final: 424 words.

Current primaries: ten_print_maze_3d. Book anchors: ten_print_maze_3d.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Begin with one fixed seeded diagonal field. Present the same choices as marks and walls using existing impression configurations.
2. Make wall mutation a second, explicit intervention; synchronise visible orientation, collision and navigation or clearly keep the agent demonstration separate.
3. Fit an optional walkable version to the room using original layout evidence. Do not promise a solvable maze from independent diagonals; keep a bypass and show disconnected regions honestly.

#### Revise final.md

1. Let a slash become an obstruction by changing its embodiment.
2. Read one binary choice before showing the nested grid loop.
3. Follow a predicted path and notice whether the wall or the navigation model disagrees.
4. Leave with a distinction between generating marks and guaranteeing passage; avoid a historical attribution beyond checked sources.

**Code to trace and quote after implementation:** ten_print_maze.gd: generate_maze, build_navigation_grid, _on_wall_timer_timeout, impression methods. Inspect any repeated randi/seed use across mutations.

#### Evidence to return

- The mark and wall views encode the same stored diagonal matrix.
- After mutation, navigation/collision match the shown wall or the limitation is explicit.
- Load/reload without changing unrelated seeded artifacts.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable chooses printed tile, glass partition or a more theatrical translation. The same binary data must remain traceable.

**Reusable method:** R4 sample-to-body mapping; R5 arena boundary; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Randomness_10_PRINT_Algorithm/map_data.json`
- Book and supporting texts: `commons/maps/Randomness_10_PRINT_Algorithm/`
- [Primary view](http://localhost:3003/necklace/thread?map=Randomness_10_PRINT_Algorithm&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Randomness_10_PRINT_Algorithm)
- `res://algorithms/randomness/generative/tenprintantmaze/ten_print_maze_3d.tscn`
- `algorithms/randomness/generative/tenprintantmaze/ten_print_maze.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Cubes

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Does a convincing die prove a fair procedure?

Body/layer: A thrown body, its settled orientation and a tally.

Proposed primary encounter: `dice_throw`.

#### Starting evidence

Outside the active route. dice_throw creates a pickable physical die, reads a settled face and produces reward balls. Reset controls and several warrant views already exist. A physical simulation is not automatically a uniform six-way draw. Platform/wall recovery on 10 September: 2 interior cells restored as platforms; 33 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 13, 'depth': 20, 'max_height': 3}. Current final: 410 words.

Current primaries: dice_throw. Book anchors: dice_throw.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Keep the die on its existing rimmed table with reachable reset and clear settled-face readout. Contain and cap reward balls so they do not become corridor obstacles.
2. Show individual outcomes and a growing tally. Use the existing assay/net views where useful; include unresolved tilted/edge cases rather than silently counting them as a face.
3. An optional beside-it uniform integer generator can make a precise contrast. Label it as a second procedure and keep sample count/face colours comparable.

#### Revise final.md

1. Throw first, then compare the face the eye sees with the one the program counted.
2. Repeat and let the tally grow without promising fairness from a short run.
3. Read the upward-normal/settling decision; locate the interval between moving body and accepted symbol.
4. Ask what the tally can support and what the collision model decided before the throw.

**Code to trace and quote after implementation:** dice_throw.gd: _read_dice_result, FACE_NORMALS, settling logic, _update_stats, _clean_reward_balls.

#### Evidence to return

- Test six clearly settled orientations and ambiguous edge/tilted cases.
- Check actual pickup/drop and both reset paths.
- Observe bounded reward bodies and distinguish empirical counts from a fairness guarantee.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Casino, assay desk or surreal oversized die all remain possible. Do not let the spectacle obscure which process produced a number.

**Reusable method:** R2 housed readout; R7 measurement contract; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/Random_Cubes/map_data.json`
- Book and supporting texts: `commons/maps/Random_Cubes/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Cubes&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Cubes)
- `res://algorithms/randomness/dice_throw/dice_throw.tscn`
- `algorithms/randomness/dice_throw/dice_throw.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Rotate_Random_XYZ

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Which changes make an arrangement harder to inhabit?

Body/layer: A repeated array under angular perturbation.

Proposed primary encounter: `random_decay_multimesh`.

#### Starting evidence

Outside the active route. Current primary changes drift, rotation and colour, with different rates for the cube and prism stacks. It has TOGGLE/RESET; several rotation-specific artifacts are also placed. Its 'decay' is not an entropy measurement. Platform/wall recovery on 10 September: 45 interior cells restored as platforms; 47 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 12, 'depth': 17, 'max_height': 2}. Current final: 409 words.

Current primaries: random_decay_multimesh. Book anchors: random_decay_multimesh.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Start with a matched reference and a rotation-only array. Disable translation, sinking, scale and colour variation for that first comparison; inspect whether the existing rotation artifacts provide a clearer implementation.
2. Offer axis-specific or combined angular perturbation and a controlled magnitude at the same sample cadence and seed. Reuse the existing process controls.
3. Build a short collidable strip only if the bodily question is traversal. Keep the separate full decay presentation optional and label its extra variables.

#### Revise final.md

1. Recognise the same cubes, then find the gap or alignment that has changed.
2. Pause a rotation-only comparison and separate centre positions from edge directions.
3. Read the actual angular update, connecting to Trans_Rotation's axes and composition.
4. Ask which body can pass at the tested angle; call changed connectivity/reachability precisely, not 'topological entropy' without a defined measure.

**Code to trace and quote after implementation:** random_decay_multimesh.gd: _advance_layer, _create_vr_controls; inspect Random_Rotate_Random_XYZ and SlopeGradientCubes if promoting a more appropriate lead.

#### Evidence to return

- Prove scale/position/material stay fixed in the rotation-only mode.
- Replay the angular sequence at the chosen simulation cadence.
- Check traversability against actual colliders if claimed; update primary/book anchors together if the lead changes.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable may promote the better existing rotation artifact instead of forcing decay to teach everything. Document why it makes the question clearer.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Random_Rotate_Random_XYZ/map_data.json`
- Book and supporting texts: `commons/maps/Random_Rotate_Random_XYZ/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Rotate_Random_XYZ&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Rotate_Random_XYZ)
- `res://algorithms/randomness/randomdecay/scenes/random_decay_multimesh.tscn`
- `algorithms/randomness/randomdecay/scripts/random_decay_multimesh.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Walk

**Active hall 4 in randomness. Batch: R1. 129 desktop checks passed; terrarium preserved; text aligned; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-walk.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What does a trail remember that the next step does not use?

Body/layer: An agent, its accumulated position and a bounded enclosure.

Proposed primary encounter: `random_walk_terrarium`.

#### Starting evidence

The existing logbook terrarium remains the one primary. Three complete 300-step, five-walker histories at seed 31415 replay after deleting trail memory and selecting ALL. The trail keeps previous positions and omits wall contacts. The lab observation-window string parser is repaired. All twelve placements and recovered museum geometry remain.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 3}. Current final: 958 words.

Current primaries: random_walk_terrarium. Book anchors: random_walk_terrarium.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Preserve the dark backboard, enlarged red bead, keypad and logbook wing at the existing cell (4,1).
2. Seven controls checked: 2D/3D/LEVY/RESET and ONE/ALL/NEW SEED. There is no visitor pause or seed-entry field.
3. Use the existing boolean parser for the pavilion window token; preserve floor, raised cells and clearance.
4. Later: tracked-hand reach, fine trail/lettering visibility and headset performance; recorded startup diagnostics.

#### Revise final.md

1. Let a suggestive trail invite a prediction without declaring every prediction a failure.
2. Compare attempted movement, reflected endpoint and the previous-position drawing; wall contacts and the current bead are omitted from that line.
3. At equal step counts the named procedure replays. ONE/ALL changes observation while all five continue; the generator still has state.
4. Read a two-second frame against five accepted steps. Distinguish bounded five-body MSD from history, path length and entropy; continue to Random Gaussian.

**Code to trace and quote after implementation:** random_walk_terrarium.gd: mode/step generation, boundary reflection, trail retention and timestep accumulator. Verify RESET's seed policy instead of promising replay from its label.

#### Evidence to return

- 129 independent desktop checks, zero assertion failures, exit 0. No headset test.
- Three 300-step histories, five walkers each, seed 31415. Every frame replayed after clearing trails at step 60 and selecting ALL.
- Actual proposed steps exported without consuming extra draws; three mode images share a camera.
- Existing controls, desktop pointer, reflection, catch-up, bounds, reach, museum routes and unload/rebuild exercised.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Keep the creatures suggestive enough to invite misreading. A readable trace should let the reader test that affection rather than being told it is wrong.

**Reusable method:** R2 housed readout; R3 explicit time; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Random_Walk/map_data.json`
- Book and supporting texts: `commons/maps/Random_Walk/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Walk&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Walk)
- `res://commons/artifacts/random_walk_terrarium/random_walk_terrarium.tscn`
- `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Gaussian

**Active hall 5 in randomness. Batch: R1. 156 desktop checks passed; book aligned; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-gaussian.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What can many draws reveal that one draw cannot?

Body/layer: A distribution, a finite histogram and its clipped edges.

Proposed primary encounter: `distribution_sampler`.

#### Starting evidence

The existing sampler remains the primary. Corrected logarithm guards prevent invalid values; issued draws reserve the cap, CLEAR removes old meshes, and markers land at the drawn bars. The orange shape now stays inside the panel with its own scale labelled. Geometry and secondary artifacts remain.

Current map dimensions: {'width': 14, 'depth': 22, 'max_height': 6}. Current final: 912 words.

Current primaries: distribution_sampler. Book anchors: distribution_sampler.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Preserve the existing cabinet, outboard panels, headline and six-line account.
2. Nine controls: PAUSE toggles issuance while flight lands; CLEAR preserves paused state; BATCH reserves airborne capacity; BINS regroups retained values.
3. Blue and pale counts share a scale; the orange ideal shape has its own peak scale inside the panel.
4. Later: tracked-hand approach, small lettering and headset performance; recorded engine startup diagnostics.

#### Revise final.md

1. Compare GAUSS and UNIFORM at N=300 after PAUSE and CLEAR; do not invent exact sparse outcomes or controls.
2. The Gaussian is constructed directly; extra UNIFORM draws do not change its law into a bell.
3. Rebin retained values and read changes in estimates from bin centres; separate edge counts from clipped values.
4. Distinguish clamping from the previous hall's reflection. Carry the choice of varying properties into Random Mushrooms.

**Code to trace and quote after implementation:** distribution_sampler.gd: sample generation, _clear_samples, theoretical curve, clamping and bin assignment. Verify sample_seed and mode-specific formulas.

#### Evidence to return

- Independent source, control and desktop checks; final receipt linked from the review.
- Four common-seed samples, deep-copied count snapshots, replay and rebin comparisons; an explicitly selected exponential edge example.
- Injected logarithm endpoint inputs; flight/batch cap; synchronous CLEAR cleanup; actual bar landing; orange curve bounds.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Use colour, falling beads or another trace if it clarifies aggregation. Keep the strange early samples visible rather than smoothing them away.

**Reusable method:** R1 controlled comparison; R2 housed readout; R7 measurement contract.

#### Open and inspect

- Map: `commons/maps/Random_Gaussian/map_data.json`
- Book and supporting texts: `commons/maps/Random_Gaussian/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Gaussian&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Gaussian)
- `res://commons/artifacts/distribution_sampler/distribution_sampler.tscn`
- `commons/artifacts/distribution_sampler/distribution_sampler.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Mushrooms

**Active hall 6 in randomness. Batch: R2. 117 desktop checks passed; rendered shader verified; book aligned; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-mushrooms.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Which parts of this population were allowed to vary?

Body/layer: A field of recognisable bodies and the ground carrying them.

Proposed primary encounter: `mushrooms`.

#### Starting evidence

The specimen bed already supports a controlled comparison. Unit scale preserves template dimensions; new seeds can change template details. Captures separate noise-gated candidates from explicit rings/clusters. Repaired desktop eating shader and enlarged the existing readout.

Current map dimensions: {'width': 13, 'depth': 13, 'max_height': 3}. Current final: 931 words.

Current primaries: mushrooms. Book anchors: mushrooms.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Preserve six-metre bed, six explicit artifact placements and the west/south route.
2. Keep five controls and the three separately planted pickables. Enlarge the housed readout.
3. Repair the desktop effect shader; test actual rendered pixels, not only its running flag.

#### Revise final.md

1. Begin by following two apparently related bodies, then SHOW their template.
2. SIZE retains the draw and replaces its use; scale 1 does not imply equal dimensions.
3. Distinguish fixed-count candidates, ring/cluster permissions and discrete template selection.
4. Edible mushrooms give a similar form another capability and change the observer's view; timed peak plus fades, not an exact ten-second total.

**Code to trace and quote after implementation:** mushrooms.gd: create_mushroom_templates, generate_mushroom_positions, generate_mushroom_field, create_fairy_ring and RNG calls.

#### Evidence to return

- Independent museum run, desktop pointer and route checks.
- Full captured populations at two named seeds; exact SIZE/REGROW comparisons for instances, ground heights and template details.
- Rendered shader passthrough and active-image comparison, matched views of the bed.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable can make a luscious, oversized or miniature population. Preserve its surprise; the inspection station should reveal choices without making every specimen into a label.

**Reusable method:** R4 sample-to-body mapping; R6 local state/seed; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/Random_Mushrooms/map_data.json`
- Book and supporting texts: `commons/maps/Random_Mushrooms/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Mushrooms&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Mushrooms)
- `res://algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.tscn`
- `algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Space_Geometry

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What changes when neighbouring heights are related?

Body/layer: Two fields mapped to the same column body.

Proposed primary encounter: `perlin_noise_bridge`.

#### Starting evidence

Outside the active route. perlin_noise_bridge already compares independent heights with coherent noise on paired 16×16 grids, with octave/frequency/seed/resample controls. Height bounds are similar but distributions need not match.

Current map dimensions: {'width': 13, 'depth': 30, 'max_height': 3}. Current final: 399 words.

Current primaries: perlin_noise_bridge. Book anchors: perlin_noise_bridge.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Give the paired grids a common footprint, height axis and palette. Keep the two panels readable at the same viewing distance and do not independently normalise them without disclosing it.
2. Start at one octave and fixed seed. Isolate frequency before offering extra octaves; expose one selected coordinate and neighbouring samples.
3. Use this as the Randomness-to-Noise comparison laboratory. Reuse its paired sampler for Noise_Types or the later noise bench if helpful, while giving this extension its own geometry-mapping experiment.

#### Revise final.md

1. Describe adjacent height differences before calling either side a landscape.
2. Hold the seed, change coherent frequency and revisit a coordinate.
3. Read independent draw versus field-at-coordinate; distinguish correlation from equal distributions.
4. Let the same values become colour or height only if that shared-data mapping is implemented. Do not claim erosion or geology from appearance.

**Code to trace and quote after implementation:** perlin_noise_bridge.gd: _rebuild_grids, _apply_column, _create_vr_controls. Inspect FastNoiseLite basis and frequency mapping.

#### Evidence to return

- Paired displays use declared common dimensions, scale and colour mapping.
- Same seed/settings repeat; frequency changes leave the independent baseline stable if advertised.
- Confirm selected-coordinate readouts agree with the displayed columns.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Could be two miniature landscapes or two austere arrays. A useful alternative is a single field viewed as colour and relief after the basic comparison.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Random_Space_Geometry/map_data.json`
- Book and supporting texts: `commons/maps/Random_Space_Geometry/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Space_Geometry&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Space_Geometry)
- `res://algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.tscn`
- `algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Randomness_Examples_of_Randomness

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### When can an uncertain sample support a precise estimate?

Body/layer: A sampling region, an inclusion test and a growing ratio.

Proposed primary encounter: `monte_carlo_dartboard`.

#### Starting evidence

Outside the active route. The apparatus generates samples with THROW/AUTO/RESET; it is not a hand-aimed dart game. It may begin with 140 preseeded darts and caps at 500. Existing disclosure modes expose the measurement. Platform/wall recovery on 10 September: 2 interior cells restored as platforms; 1 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/. The spawn is now on existing floor at (1,1), preserving access after the old border became a wall.

Current map dimensions: {'width': 12, 'depth': 22, 'max_height': 4}. Current final: 405 words.

Current primaries: monte_carlo_dartboard. Book anchors: monte_carlo_dartboard.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Begin the lesson at zero or make preseeded history explicit. Put sample count, inside count and estimate together in the existing cabinet.
2. Offer one-sample THROW before AUTO. Add a deliberate biased-sampling comparison only if it is labelled and uses a separate mode; more points must not be presented as correcting bias.
3. Keep optional painting/pipe artifacts as a gallery of other uses of chance, with this estimator as the one clear primary experiment.

#### Revise final.md

1. Predict what an inside or outside sample will do before asking for it.
2. Let the estimate wobble and occasionally get worse as N grows.
3. Read the actual inside-circle condition and 4*inside/total expression.
4. Distinguish random sample placement from skillful aim and numerical stability from correctness; carry the question of selection into feedback.

**Code to trace and quote after implementation:** monte_carlo_dartboard.gd: _throw_dart, _unit_draw, _preseed, _update_display and reset seed handling.

#### Evidence to return

- Generated samples remain in the intended square; counts and estimate agree.
- AUTO stops/caps cleanly and RESET clears the displayed and numerical state.
- If bias mode is built, demonstrate it can stabilise at the wrong value rather than selecting a flattering run.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable may lean into the casino or laboratory. The experiment should reward a careful explanation, not a lucky estimate.

**Reusable method:** R3 explicit time; R6 local state/seed; R7 measurement contract.

#### Open and inspect

- Map: `commons/maps/Randomness_Examples_of_Randomness/map_data.json`
- Book and supporting texts: `commons/maps/Randomness_Examples_of_Randomness/`
- [Primary view](http://localhost:3003/necklace/thread?map=Randomness_Examples_of_Randomness&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Randomness_Examples_of_Randomness)
- `res://algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.tscn`
- `algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Pheromone

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### When does a path begin choosing its next visitor?

Body/layer: Agents, a decaying signal and a terrain that keeps another history.

Proposed primary encounter: `pheromone_terrain`.

#### Starting evidence

Outside the active route. Visits deposit pheromone and alter height; the signal decays separately. trail/sniff/avoid/grid rule variants and seeded warmup already exist. These are genuine stateful processes, unlike a stateless field lookup.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 3}. Current final: 411 words.

Current primaries: pheromone_terrain. Book anchors: pheromone_terrain.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Build a matched attraction/avoidance comparison from the same initial state using existing rule modes; expose a local reset and one clearly named rule choice.
2. Show pheromone strength and accumulated height separately, switching or pairing their readouts from the same state. Keep deposition and decay rates fixed initially.
3. Fit the evolving terrain within a stable observation border. Verify collider updates if a player can walk it; the agents' grid traversal and the player's body may use different representations.

#### Revise final.md

1. Find a repeated route, then ask what the next walker is actually reading.
2. Compare following a trace with avoiding it before calling either best.
3. Read deposit, decay and next-step choice as distinct operations.
4. Let an old high ridge lose its current scent. State precisely where history persists, then distinguish this feedback from the stateless noise mixer.

**Code to trace and quote after implementation:** pheromone_terrain.gd: _walk_step, _decay_pheromones, _choose_next_position, _update_mesh and rule configs.

#### Evidence to return

- At fixed timestep and seed, replay the initial run and log rule differences.
- Show pheromone decays while accumulated height follows its separate rule.
- Check index boundaries and any terrain collision updates.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Turn the traces into scent, glow or another legible local signal. Avoid describing a globally optimal path or attributing intent the algorithm does not have.

**Reusable method:** R3 explicit time; R4 sample-to-body mapping; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Random_Pheromone/map_data.json`
- Book and supporting texts: `commons/maps/Random_Pheromone/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Pheromone&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Pheromone)
- `res://algorithms/randomness/pheromone_terrain/pheromone_terrain.tscn`
- `algorithms/randomness/pheromone_terrain/pheromone_terrain.gd`
- `commons/resourses/shaders/SimpleGrid.gdshader`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Space

**Authored extension — outside the current museum route. Batch: R-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Can a deterministic sum persuade us it is a landscape?

Body/layer: A field assembled in layers and an interpretive palette.

Proposed primary encounter: `noise_mixer`.

#### Starting evidence

Outside the active route. noise_mixer sums a sine-based function over octaves with seeded offsets; it is not Perlin. The generated image normalises its own range and uses terrain colours. OCT/LAC/PER and random seed controls already exist. Platform/wall recovery on 10 September: 48 interior cells restored as platforms; 43 boundary cells made explicit w. Keep museum.wall_height: 3 and existing gate-depth settings. See structure-recovery.html and doc/space/sequence-platform-recovery-2026-09-10/.

Current map dimensions: {'width': 13, 'depth': 16, 'max_height': 5}. Current final: 409 words.

Current primaries: noise_mixer. Book anchors: noise_mixer.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Stage the existing mixer on a reachable stand. Begin with one layer, then add layers while keeping the seed and base function fixed.
2. Provide a fixed-scale/normalised view comparison with the actual min/max values visible; changing contrast should not masquerade as changing absolute height.
3. Make a grayscale or neutral colour option available to compare field structure with landscape associations. Coordinate its scope with Noise_6_Wall so this room teaches interpretation/normalisation and that one teaches shader layers.

#### Revise final.md

1. Meet an apparent coastline, then remove the landscape palette.
2. Build the image from one layer and trace what OCT, LAC and PER each change.
3. Quote _sin_noise and the octave accumulation, naming the actual construction.
4. Let normalisation conceal a numerical difference, then reveal it. Close with a precise question about mapping rather than claiming all irregularity is randomness.

**Code to trace and quote after implementation:** noise_mixer.gd: _fbm, _sin_noise, _generate_texture, _sample_color_ramp. Confirm the control units and range remapping.

#### Evidence to return

- Replay field samples at a fixed seed/settings.
- Show fixed versus per-image normalisation without resampling the field.
- At one octave, test the claimed effect of layer-spacing controls before describing it.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable can retain the seductive terrain colours. Their power becomes more interesting when another reading is available.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R7 measurement contract.

#### Open and inspect

- Map: `commons/maps/Random_Space/map_data.json`
- Book and supporting texts: `commons/maps/Random_Space/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Space&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Space)
- `res://commons/artifacts/noise_mixer/noise_mixer.tscn`
- `commons/artifacts/noise_mixer/noise_mixer.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Random_Game

**Active hall 7 in randomness. Batch: R2. 88 desktop checks passed; two book encounters aligned; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-game.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### How can you plan when the next state is known but its timing is not?

Body/layer: The player and an intermittently supporting platform.

Proposed primary encounter: `r_c`.

#### Starting evidence

Crossing and falling field make distinct arguments about where uncertainty enters. Repaired replay state/tween ownership, beacons, state readout, threshold access and early timer configuration. Field controls distinguish stopping a source from clearing flights. Monte Carlo has no living museum scene and incomplete extra modes; remains an open secondary placement.

Current map dimensions: {'width': 15, 'depth': 18, 'max_height': 3}. Current final: 967 words.

Current primaries: cube_projectile_spawner, r_c. Book anchors: r_c, cube_projectile_spawner.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Keep the recovered pit and alternative route; repair threshold access and replay during movement.
2. Give the existing field a housed local RUN / STOP and CLEAR panel with initial-position markings.
3. Retain other map placements; record missing Monte Carlo and unisolated creatures explicitly.

#### Revise final.md

1. Observe state order, drawn waits and available notice separately.
2. Compare the regular spawn clock with random positions and initial velocities.
3. Explain local reset and separate projectile jitter without claiming complete world replay.
4. Carry the distinction between a procedure and its choices into Noise_Types.

**Code to trace and quote after implementation:** random_cycle_cube.gd: _run_cycle_loop, _next_random_wait, _set_state, _set_collision_enabled and warning configs.

#### Evidence to return

- Independent rendered museum, pointer and recovery checks.
- Replay during a live sink; exact first waits and unchanged cue RNG/deadline state.
- Two sets of 24 launch records, cap, STOP/CLEAR and actual local button paths.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable may choose a playful platform challenge or a quieter timing crossing. The uncertainty must remain specific and observable.

**Reusable method:** R3 explicit time; R5 arena boundary; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Random_Game/map_data.json`
- Book and supporting texts: `commons/maps/Random_Game/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Game&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Game)
- `res://commons/primitives/cubes/cube_spawner.tscn`
- `commons/primitives/cubes/CubeSpawner.gd`
- `res://commons/primitives/cubes/random_cycle_cube.tscn`
- `commons/primitives/cubes/random_cycle_cube.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

## Noise · neighbouring, sampling, inhabiting

A spatial relation constrains variation. A field becomes colour, relief, occupied volume or a route through distinct reading rules. Layers and coordinate warps expand what those fields can do; fair comparisons reveal which change actually mattered.

A sampling domain and coordinates, a field-generating rule, and a mapping from values into an appearance or consequence. Correlation alone supplies no stored history, collision, ecology or intention.

Keep six active halls. Repair the Perlin/Simplex claim first. Develop domain warping and walkable noise as extension rooms; decide later whether they earn main-route slots. Lab_Path is a short optional reflective exit, not another long noise lesson.

### Random_Noise_Types

**Active hall 1 in noise. Batch: N1. Four primary passages; 81 gallery checks passed; earlier point review 84 passed; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-noise-types.html)

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Can randomly proposed points still keep their distance?

Body/layer: A cloud of pickable bodies and a rule of admission.

Proposed primary encounter: `randompoints`.

#### Starting evidence

All four existing works now have a place in the book. Retained point encounters and visual fields; restored full-size controls beside both miniature galleries. The galleries add independent image/sound sources, gradient mapping, display clamping and temporal memory/difference. Card questions may expand when the material warrants it.

Current map dimensions: {'width': 13, 'depth': 10, 'max_height': 6}. Current final: 1583 words.

Current primaries: randompoint, randompoints, WhiteNoiseGallery, NoiseColors3D. Book anchors: randompoint, randompoints, WhiteNoiseGallery, NoiseColors3D.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Frame and raise the single point; move it clear of the entrance wall.
2. Keep matched slabs, add LOAD x1/x4 with fixed spacing, enlarge the cased readout.
3. Count all refusals and distinct close pairs; report the bounded ghost sample and finite attempt budget.
4. Preserve both existing gallery fields and make their controls human-sized; repair actual pointer targets and keep the platform approach clear.

#### Revise final.md

1. Carry a point, release, then read local-coordinate clipping.
2. Compare every proposal kept with distance-based admission.
3. Increase the request and distinguish search shortfall from impossibility.
4. Move an admitted point and find where a generative rule stops acting.
5. Let height/colour and temporal filters add distinct encounters; show that the model rows do not measure audio.

**Code to trace and quote after implementation:** randompoints.gd: _generate_uniform, _generate_blue_noise, spawn_points, apply_grid_config; inspect pickable point behaviour.

#### Evidence to return

- Actual museum and project desktop rig pointer presses and grabs.
- Full-precision generated coordinates and separately recorded live-transform residue.
- Independent candidate arithmetic, pair geometry, Gaussian accounting and ghost-cap checks.
- Both gallery consumers exercised by pointer across five modes and STOP; actual generators exported as two-second dry audio with matched white innovations.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

A gathering of luminous bodies or a precise sampling cabinet can both work. Keep the excluded neighbourhood visible without prescribing a social moral.

**Reusable method:** R1 controlled comparison; R6 local state/seed; R7 measurement contract.

#### Open and inspect

- Map: `commons/maps/Random_Noise_Types/map_data.json`
- Book and supporting texts: `commons/maps/Random_Noise_Types/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Noise_Types&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Random_Noise_Types)
- `res://algorithms/randomness/randompoint/randompoint.tscn`
- `commons/primitives/line/coordinate_axes_xy.tscn`
- `algorithms/randomness/randompoint/randompoint.gd`
- `res://algorithms/randomness/randompoints/randompoints.tscn`
- `algorithms/randomness/randompoints/randompoints.gd`
- `res://algorithms/randomness/whitenoise/WhiteNoiseGallery.tscn`
- `algorithms/randomness/whitenoise/white_noise_spectrum.gd`
- `res://algorithms/randomness/whitenoise/NoiseColors3D.tscn`
- `algorithms/randomness/whitenoise/noise_spectrum_3d.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Noise_Columns

**Active hall 2 in noise. Batch: N2. Three primary passages; 53 rendered-museum checks passed; headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Where does change enter a body?

Body/layer: Generated shafts, an independently pulsing orb, and the existing six-orb construction.

Proposed primary encounter: `MeltingBerniniScene`, `dark_sphere`, `synthesis_stand`.

#### Starting evidence

Reviewed all three authored works. Retained the trio and both dark-sphere forms. Repaired local freeze for accessory shaders, improved the cased readout, cleared the synthesis stand approach and repaired the local passage. Corrected unsupported terrain, 3D Perlin erosion, invertibility and universal non-return claims.

Current map dimensions: {'width': 14, 'depth': 16, 'max_height': 3}. Current final: 1280 words.

Current primaries: dark_sphere, MeltingBerniniScene, synthesis_stand. Book anchors: MeltingBerniniScene, dark_sphere, synthesis_stand.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Retain the controlled trio and its established drivers. Its bases and capitals must obey the same local freeze as the CPU shafts.
2. Keep the dark orb and hush/swarm synthesis as distinct encounters; reserve a clear approach for the smaller body.
3. Preserve recovered structure and verify the museum route through the hall and its passage.

#### Revise final.md

1. Observe before reveal; distinguish shaft deformation, whole-body turning and shaft veining.
2. Let the independent orb make the scope of local time apparent.
3. Compare the single orb with the six-part construction; do not call it steering or flocking.
4. Carry the receiving operation into Noise_One: one field spent as relief or colour.

**Code to trace and quote after implementation:** MeltingBerniniColumns.gd: _process, update_column_mesh and generated mesh; marble_column.gdshader. Use a real coherent field for the new branch and label it as newly implemented.

#### Evidence to return

- 53 checks, actual pointer control for FREEZE/REVEAL/SPIN/MARBLE; all three authored works present.
- All nine material clock inputs hold under FREEZE; the orb continues. Full shaft-vertex arrays repeat for identical phase; unchanged index arrays do not prove invertibility.
- No reported hall/passage severance. Recorded driver samples, scene images and isolated saved-hand provenance.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Give the columns a material worth looking at. The comparison may remain ambiguous until the reader asks the instrument; avoid labelling every surface before it can surprise.

**Reusable method:** R1 controlled comparison; R3 explicit time; R4 sample-to-body mapping.

#### Open and inspect

- Map: `commons/maps/Noise_Columns/map_data.json`
- Book and supporting texts: `commons/maps/Noise_Columns/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_Columns&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_Columns)
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`
- `res://algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniScene.tscn`
- `algorithms/proceduralgeneration/hybrid_complex/berninicolumns/MeltingBerniniColumns.gd`
- `res://commons/artifacts/synthesis/synthesis_stand.tscn`
- `commons/artifacts/synthesis/synthesis_stand.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Noise_One

**Active hall 3 in noise. Batch: N1. Three primary passages; 49 rendered-museum checks passed; headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What does a value become?

Body/layer: Two field readings, a retained three-source terrain and an independently pulsing orb.

Proposed primary encounter: `noisetorus`, `noiselayers`, `dark_sphere`.

#### Starting evidence

Kept all three authored works. FREEZE now holds current shader/CPU phase; GPU readback validates the pair-only reproducible hash. REMAP compares clipping with signed encoding. The existing oversized terrain is staged as a four-metre basin with resource-isolation controls, retaining its complete generator and three source resources. Recovered structure and utilities remain unchanged.

Current map dimensions: {'width': 13, 'depth': 11, 'max_height': 5}. Current final: 1286 words.

Current primaries: dark_sphere, noisetorus, noiselayers. Book anchors: noisetorus, noiselayers, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Hold the same local time on CPU and both shader stages; preserve legacy single-ring behaviour.
2. Expose signed colour mapping as a choice, with a cased readout that fits.
3. Retain the three-source terrain and coordinate frame at 1:50; expose contribution controls and matching collision.
4. Move the dark orb onto the perimeter and keep the room route clear.

#### Revise final.md

1. Let a negative value become inward relief, clipped darkness or remapped brightness.
2. Distinguish displacement amplitude from coordinate frequency and vertex from fragment sampling.
3. Describe actual source settings and slope lowering; do not promise an octave brush or hydraulic erosion.
4. Carry the independent orb and the question of presence into Noise_Voxel.

**Code to trace and quote after implementation:** noisetorus.gd: _apply_readout; noiseTorus.gdshader vertex/fragment and TIME inputs. Determine which material is actually bound, including any stray sphere.

#### Evidence to return

- 49 checks; all five torus and four basin controls pressed through the desktop pointer.
- 256 GPU samples within 0.0001 of CPU values; held local shader time equals the CPU clock.
- Each terrain mode has one matching triangle collider; SUM restores the full 10,201-vertex array.
- All three authored works retained; original map structure and utilities intact; museum route connected.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Drag, lacquer, plush or a spare grey ring can all serve the experiment. Material changes must not quietly change the field being compared.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R7 measurement contract.

#### Open and inspect

- Map: `commons/maps/Noise_One/map_data.json`
- Book and supporting texts: `commons/maps/Noise_One/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_One&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_One)
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`
- `res://algorithms/randomness/noisetorus/noisetorus.tscn`
- `commons/resourses/shaders/noisePlanet2.gdshader`
- `commons/resourses/shaders/noiseTorus.gdshader`
- `algorithms/randomness/noisetorus/noisetorus.gd`
- `res://algorithms/randomness/noiselayers/noiselayers.tscn`
- `algorithms/randomness/noiselayers/noiselayers.gd`
- `algorithms/randomness/noiselayers/noiselayers_stage.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Noise_Voxel

**Active hall 4 in noise. Batch: N2. Four primary passages; 61 rendered-museum checks passed; headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What does the threshold let have a body?

Body/layer: A lattice model, a live score/decision section, a magnified volume and an independent pulsing orb.

Proposed primary encounter: `perlin_terrain_sculptor`, `science_screen`, `voxelnoise`, `dark_sphere`.

#### Starting evidence

All four authored works retained. Receiver rebuild now preserves the source Perlin sampler and samples the same 24 cubed positions. The volume is staged at 0.20 m cell spacing with exposed-face mesh and matching collision. The screen reads its actual same-hall lattice section. The cased model and tilted controls have a clear approach. Recovered structure and utilities remain unchanged.

Current map dimensions: {'width': 15, 'depth': 16, 'max_height': 3}. Current final: 1144 words.

Current primaries: dark_sphere, perlin_terrain_sculptor, science_screen, voxelnoise. Book anchors: perlin_terrain_sculptor, science_screen, voxelnoise, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Retain the sampler contract through rebuild, equalise sample indices and bound the volume to a 5.2 m frame.
2. Stage the existing lattice with a cased readout, reachable controls and a correctly centred sample marker.
3. Connect the retained science screen to the actual source; display scores beside stored decisions.
4. Preserve the independent orb and all recovered structure; remove only duplicate controls in lattice mode.

#### Revise final.md

1. Try the threshold before reading its predicate, including the height bias.
2. Compare monotonic occupied count with nonmonotonic component count; distinguish CUT from removing occupancy.
3. Read a live section, then approach the same occupied arrangement at another bodily scale.
4. Keep the orb and another use for varying values; carry the rejected sample into Noise_6_Wall.

**Code to trace and quote after implementation:** perlin_terrain_sculptor.gd: _generate_terrain; voxelnoise.gd: apply_perlin_terrain_controls, _configure_noise, _generate_chunk. Audit the link's scope so it cannot retune receivers in other halls.

#### Evidence to return

- 61 checks and four buttons through the actual desktop pointer.
- All 13,824 sample values and occupancy decisions match at five thresholds; each 576-cell section matches the stored array.
- Exposed boundary face counts, triangle colliders, sampled roof rays and empty-volume cleanup pass.
- Cross-hall receiver excluded; CUT changes model visibility only; recovered structure/utilities preserved and museum route connected.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Keep all four distinct readings. Further body-size, adjacency and rejected-value material experiments remain proposals.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R5 arena boundary.

#### Open and inspect

- Map: `commons/maps/Noise_Voxel/map_data.json`
- Book and supporting texts: `commons/maps/Noise_Voxel/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_Voxel&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_Voxel)
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`
- `res://commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.tscn`
- `commons/artifacts/perlin_terrain_sculptor/perlin_terrain_sculptor.gd`
- `res://commons/artifacts/science_screen/science_screen.tscn`
- `commons/artifacts/science_screen/science_screen.gd`
- `res://algorithms/randomness/voxelnoise/voxelnoise.tscn`
- `algorithms/randomness/voxelnoise/voxelnoise.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Noise_6_Wall

**Active hall 5 in noise. Batch: N1. Two primary passages, three placements; 39 rendered museum checks passed; headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What changes when the room changes its dress?

Body/layer: A four-patch instrument, an enterable shader enclosure with its original sphere, and an independent dark orb.

Proposed primary encounter: `shader_noise_space`, `dark_sphere`.

#### Starting evidence

All three authored placements retained. The room is staged within the hall, with a floor bridging the existing central opening and two tested doors. A supported four-control panel broadcasts basis, term count, finish and held/resumed state to its own hall receiver. The retained sphere now uses the shader at its actual combined CSG root. Recovered structure and utilities remain unchanged. Continue to Noise_Inside_Noise.

Current map dimensions: {'width': 13, 'depth': 13, 'max_height': 3}. Current final: 1062 words.

Current primaries: dark_sphere, shader_noise_space. Book anchors: shader_noise_space, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Preserve the panel and orb, and opt the enclosure into a five-metre floor with opposing side doors.
2. Hold current state without setting the shader rate to zero; share it across all local comparison surfaces.
3. Expose cloud sum versus full finish on the room and its retained sphere, with unchanged collision.
4. Keep legacy geometry available; correct the shared normal-map encoding and document its appearance impact.

#### Revise final.md

1. Enter the room before explaining its apparent folds; compare the same held moment through DRESS.
2. Read the actual abs accumulation, weights, animated coordinates and display clipping.
3. Separate the cloud loop from the independent four-term detail loop and investigate UV seams.
4. Retain the independent orb and move from adding values to changing sampling coordinates in Noise_Inside_Noise.

**Code to trace and quote after implementation:** noiseroom.gd: _apply_generator, _update_room_animation, apply_grid_config; WallNoiseShader.gdshader and QueerNoiseShader.gdshader accumulation and colour mapping.

#### Evidence to return

- 39 checks in the rendered museum, including all four controls through the actual desktop pointer.
- Matched sphere/wall shader output at 256 captured pixels for each 1/2/4/6 prefix; maximum difference zero.
- Freeze/resume continuity, complete local state propagation, foreign receiver exclusion and unchanged collision shapes.
- Desktop body crosses both doors and floor; three placements retained; recovered structure/utilities unchanged and surrounding route connected.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Future world-space mapping, exposed weights/gain and geometry displacement remain proposals. Keep surface pleasure and the distinction between appearance and physical support.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R8 bounded simulation.

#### Open and inspect

- Map: `commons/maps/Noise_6_Wall/map_data.json`
- Book and supporting texts: `commons/maps/Noise_6_Wall/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_6_Wall&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_6_Wall)
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`
- `res://algorithms/randomness/shadernoisespace/noiseroom.tscn`
- `algorithms/randomness/shadernoisespace/noiseroom.gd`
- `algorithms/randomness/shadernoisespace/QueerNoiseShader.gdshader`
- `algorithms/randomness/shadernoisespace/WallNoiseShader.gdshader`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Noise_Inside_Noise

**Active hall 6 in noise. Batch: N-EXT. Two primary works inside a noise sphere; 52 rendered museum checks passed; headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Where did the difference enter?

Body/layer: The visitor inside a ten-metre noise sphere, with two side openings, a circular floor and the comparison instrument within it.

Proposed primary encounter: `noisesphere`, `dark_sphere`.

#### Starting evidence

The book sequence included this hall while the live museum plan skipped it. Reconnected after Noise_6_Wall once its comparison and route were built. The original noisesphere gains an opt-in coordinate study; the independent orb remains. All previous structure cells and utilities are retained, with an added east boundary and museum-only approach/exit aprons. A Value base field is sampled at coordinates displaced by two Perlin fields. Zero warp reproduces all 9,216 image samples and matching relief geometry. Noise_Space_10 was subsequently reviewed and reconnected; its current record follows below. User correction: the sphere must enclose the visitor. A five-metre-radius spherical wall and ceiling now surround the comparison, with two real 2.5 m-high openings and a circular floor. WARP changes the enclosing field; RELIEF changes the small pair only. Enclosing geometry and collision remain fixed. The 37,248 encoded vertex colours match the shared sampler at gain .65; the actual desktop body crosses both openings.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 3}. Current final: 1169 words.

Current primaries: dark_sphere, noisesphere. Book anchors: noisesphere, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Keep the original sphere node as the direct member of a matched pair in an optional stage.
2. Make q = p + amount × displacement(p) the actual shared sampler for images, witnesses and spheres.
3. Provide WARP, SAMPLE, RELIEF and ZERO; make the study static between actions.
4. Preserve recovered cells and the exit landing; connect a level museum apron and restore the missing live plan row.
5. Enclose the visitor in the noise sphere and keep the instrument inside; provide a circular floor and two explicit portal openings in both geometry and collision.

#### Revise final.md

1. Begin inside the sphere; let a change of sampled neighbourhood reach the surrounding surface before explaining it.
2. Notice a changed neighbourhood, then return to zero before explaining.
3. Follow the original address and borrowed address in the actual coordinate witness.
4. Separate input-coordinate displacement from applying a sampled value as relief.
5. Keep projection, interpolation, collision and elapsed time as distinct questions; prepare Noise_Space_10.

**Code to trace and quote after implementation:** noisesphere.gd/noisePlanet2.gdshader for the baseline; commons/artifacts/the_same_cloud/the_same_cloud.gd: _build_warp_pair for a reuse candidate. Trace its actual FastNoiseLite settings before adapting.

#### Evidence to return

- 52 rendered checks, including the enclosure, actual desktop traversal, four pointer controls, shared sampling and local ownership.
- Every image sample agrees at zero; all 9,216 changed at each nonzero setting while the baseline remains unchanged.
- SKIN keeps geometry equal; RELIEF changes vertices from actual samples while retaining image values; ZERO restores identical relief.
- Coordinate markers, local ownership, a real desktop apron walk and museum route connectivity pass.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Further warp iterations, animated fields, exposed seeds, alternative projections and collider deformation remain proposals.

**Reusable method:** R1 controlled comparison; R4 sample-to-body mapping; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Noise_Inside_Noise/map_data.json`
- Book and supporting texts: `commons/maps/Noise_Inside_Noise/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_Inside_Noise&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_Inside_Noise)
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`
- `res://algorithms/randomness/noisesphere/noisesphere.tscn`
- `commons/resourses/shaders/noisePlanet2.gdshader`
- `algorithms/randomness/noisesphere/noisesphere.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Noise_Space_10

**Active hall 7 in noise. Batch: N-EXT. Two primary works; 36 rendered checks passed; headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### Which bodies can a field carry once it becomes ground?

Body/layer: A body crossing an eight-metre heightfield, a steady surrounding margin, two proposed routes and an independently pulsing orb.

Proposed primary encounter: `noise_space`, `dark_sphere`.

#### Starting evidence

Restored the declared hall after Noise_Inside_Noise in the active museum. Every original structure cell remains. Both original works are retained, with the orb on the east raised platform. Two added ramps connect the margin to the entrance and teleporter approach. stand:walk keeps one measured OpenSimplex2S field fixed while height scale changes from 0 to .90. Mesh and collider rebuild together only when the body is off the terrain. The recorded desktop body crosses route A at .25 and stops partway at .90; this does not classify all possible routes. Historical ten-slider prose is archived and corrected.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 3}. Current final: 1043 words.

Current primaries: noise_space, dark_sphere. Book anchors: noise_space, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Eight-metre terrain, 81 × 81 vertices, height base 1 m and a .75 m edge envelope meeting a stable surrounding margin. Preserve the existing grid structure and add entrance/exit ramps.
2. HEIGHT, ROUTE, SAMPLE and RESET through the native pointer. Both player_body and em_walker prevent rebuilding occupied terrain.
3. Two proposed routes and a supported section display with five shared witnesses; readings interpolate the actual mesh triangles. Keep the original terrain available without stand:walk.

#### Revise final.md

1. Choose a crossing before explaining the field-to-height rule. Return to the margin and raise HEIGHT; revisit the same features.
2. Follow a section without mistaking a line for a body. Compare actual desktop crossing and stall with the recorded section slopes.
3. Read exact height, border-envelope and mesh-to-collision code. Ask what the heightfield cannot hold: a cave needs more than one height.
4. Keep the orb’s independent time. Prepare a controlled generator comparison in Noise_Perlin_Simplex.

**Code to trace and quote after implementation:** NoiseSpace.gd: optional stand:walk, ground_at, edge_weight, walk_height_at and generate_space; noise_walk_study.gd: local controls, routes and profile. The original TopologySpace mesh/collision helpers remain unchanged.

#### Evidence to return

- 36 rendered checks, including four actual pointer controls, local ownership, native walker guards, both ramps and museum continuity.
- All 6,561 vertices and collision faces agree at four height scales; five fractional-grid physics rays per scale agree with the triangle-interpolated profile.
- Same forward desktop attempt crosses at .25 and stops partway at .90. Other paths, body configurations and headset checks remain open.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable may make a mountain refuge, a rolling promenade or another world that carries the body differently. The terrain should invite a route, not become generic noise scenery.

**Reusable method:** R4 sample-to-body mapping; R5 arena boundary; R6 local state/seed.

#### Open and inspect

- Map: `commons/maps/Noise_Space_10/map_data.json`
- Book and supporting texts: `commons/maps/Noise_Space_10/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_Space_10&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_Space_10)
- `res://commons/context/walkgrids/noise_space.tscn`
- `commons/context/walkgrids/NoiseSpace.gd`
- `commons/resourses/shaders/Grid.gdshader`
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Noise_Perlin_Simplex

**Active hall 8 in noise. Batch: PILOT. 39 rendered checks passed; 11 actual controls; headset pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What must stay the same before a difference can be attributed to a rule?

Body/layer: Two retained cube fields, their live comparison plate and shared sample, plus an independently changing sheet and orb.

Proposed primary encounter: `simplex_noise`, `perlin_noise`, `perlin_noise_terrain`, `dark_sphere`.

#### Starting evidence

The current map already declared Perlin versus OpenSimplex2, but its live museum row was stale. Replaced only this row with the accepted five-work configuration. Preserved all authored structure, utilities and current works. Turned the front controls and plate towards the entry. The plate now refreshes actual generator state and reports mismatches, including seed differences of one. SAMPLE marks five paired addresses, VIEW spends the values on colour alone or colour and relief, and MATCH restores the two declared configurations. The small terrain remains an independently timed 3D OpenSimplex2S slice. The unresolved optional Lab Path portal is retained, explicitly labelled and inactive.

Current map dimensions: {'width': 13, 'depth': 15, 'max_height': 3}. Current final: 1108 words.

Current primaries: simplex_noise, perlin_noise, perlin_noise_terrain, dark_sphere. Book anchors: simplex_noise, perlin_noise, perlin_noise_terrain, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Preserve the authored pair and its two independent panels; restore the current five-work map in the museum.
2. Add a shared sample, view and matched return through a supported local instrument. Keep other halls untouched.
3. Retain the small sheet on a low plinth and the orb as distinct book encounters. Mark the unconnected Lab Path route inactive until its loader is repaired.

#### Revise final.md

1. Keep the earlier discovery opening and code-grounded comparison.
2. Follow the same address in both fields, then change the display without changing the generator.
3. Let a mismatch revise the plate’s claim; do not infer corresponding features from a shared seed.
4. Give the moving sheet and orb their own passages. Carry the distinction between sampling a field and updating stored cell states into Cellular Automata.

**Code to trace and quote after implementation:** PerlinNoise.gd: apply_grid_config/_update_noise_parameters; NoiseVisualizer.gd: _noise_type_for/set_dna/generate_noise_at; SimplexVisualizer.gd setup and sampling.

#### Evidence to return

- 39 rendered checks with 11 actual pointer controls: four slider drags, four individual buttons, three shared buttons.
- All 64 samples per display agree with height and material mapping through relief, plate, a detuned state and matched return. Five shared witnesses agree at each state.
- Actual generator readback, seed difference of one, local ownership, independent terrain clock, portal inactive state and a desktop body crossing the aisle and far door.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

Fable can choose twin reliefs, a shared probe or a reversible display. A fair comparison matters more than preserving the current cabinet.

**Reusable method:** R1 controlled comparison; R6 local state/seed; R7 measurement contract.

#### Open and inspect

- Map: `commons/maps/Noise_Perlin_Simplex/map_data.json`
- Book and supporting texts: `commons/maps/Noise_Perlin_Simplex/`
- [Primary view](http://localhost:3003/necklace/thread?map=Noise_Perlin_Simplex&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Noise_Perlin_Simplex)
- `res://algorithms/randomness/simplexnoise/simplexnoise.tscn`
- `algorithms/randomness/simplexnoise/SimplexNoise.gd`
- `algorithms/randomness/simplexnoise/SimplexVisualizer.gd`
- `res://algorithms/randomness/perlinnoise/perlinnoise.tscn`
- `algorithms/randomness/perlinnoise/PerlinNoise.gd`
- `algorithms/randomness/perlinnoise/NoiseVisualizer.gd`
- `res://algorithms/randomness/noise/perlinnoise/scenes/perlin_noise_terrain.tscn`
- `algorithms/randomness/noise/perlinnoise/scripts/terrain_generator.gd`
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.

### Lab_Path

**Authored extension — outside the current museum route. Batch: N-EXT. Implementation pending.**

[Read the shared handoff](HANDOFF.md) · [All maps](all-maps.md)

#### What would you test next if your explanation were still uncertain?

Body/layer: A reader choosing a future experiment.

Proposed primary encounter: `dark_sphere`.

#### Starting evidence

Outside the active museum route. It is a 5×5 reflective exit with a dark sphere and a short existing manuscript. The sphere is currently primary/book-anchored, but it does not itself validate understanding or perform a new noise experiment.

Current map dimensions: {'width': 5, 'depth': 5, 'max_height': 1}. Current final: 391 words.

Current primaries: dark_sphere. Book anchors: dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

#### Build the encounter

1. Keep this a small, legible pause/return space rather than another instrument-filled lesson.
2. Offer links or a simple choice of concrete return destinations only through navigation mechanisms the game supports. Test every destination, especially its relation to the main Cellular Automata continuation.
3. Decide whether the sphere serves a real book encounter or is supporting atmosphere. If reclassified, update roles/anchors together; do not promote decoration just to fill a primary quota.

#### Revise final.md

1. Use a brief recollection of one observed difference instead of summarising every room.
2. Ask for two possible explanations and the one variable that would distinguish them.
3. Keep any short code excerpt tied to a previously visited sampler, with a reference; do not manufacture new functionality here.
4. Leave an attachment or unresolved question with the reader. A 150–250 word coda may be enough; use the length the encounter needs.

**Code to trace and quote after implementation:** map_data.json utility definitions and actual portal destination logic; dark_sphere.gd only for behaviours the text genuinely invokes.

#### Evidence to return

- Verify each offered navigation action lands in the named room with a usable return/continuation.
- Review book/role treatment after deciding whether the sphere is an encounter.
- Confirm no false completion badge, assessment or saved experiment is claimed.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

#### Room for a better solution

A bench, an unanswering presence or a small route diagram could work. Preserve the pause; no need to force another manipulation.

**Reusable method:** R5 arena boundary; R9 route/book reconciliation.

#### Open and inspect

- Map: `commons/maps/Lab_Path/map_data.json`
- Book and supporting texts: `commons/maps/Lab_Path/`
- [Primary view](http://localhost:3003/necklace/thread?map=Lab_Path&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=noise&room=Lab_Path)
- `res://commons/artifacts/dark_sphere/dark_sphere.tscn`
- `commons/artifacts/dark_sphere/dark_sphere.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
