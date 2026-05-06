# Wavefunctions — Curriculum Audit

**Sequence ID:** `wavefunctions`
**Spine order:** oscillation-phase (after Forces, inheriting its springs/pendulums)
**Truth:** "Everything oscillates. Fourier shows every signal is a sum of sines."
**QFEP term:** dynamics (edge-of-chaos temporal evolution, φΔE(S,t))
**Maps declared:** 13 (in `maps:`) / 12 (in `artifact_groups:`) — Chamber_Waves is listed as a map but has no artifact group
**Evolutions written:** 0 (all 13 have intent.md, most have blurb.md; only Intro has full 4-doc set)

## 1. Core Concept

Waves are the mathematical form of non-rest — perpetual periodic motion between poles. The sequence teaches four compounding claims: (1) oscillation is inevitable wherever there is a restoring force, (2) all oscillation is rotation seen from a lower dimension, (3) any signal decomposes into a sum of sines (Fourier), and (4) the world that results — from sound to baroque columns to silence — is built entirely from that single primitive. Waves are the first proper *dynamics* in the curriculum. Points sit. Lines measure. Pendulums swing forever, because the universe cannot be made to stop.

## 2. The Red Thread

The intended thread (inferred from truth + learning objectives + intent files) is six concept-atoms, in order:

1. **Oscillation parameters** (WaveFunctions_Intro)
   - Amplitude, frequency, phase — the vocabulary of periodic motion
   - Captures: x = A·sin(ωt + φ) as adjustable knobs
   - Leaks: where sine *comes from*, and why oscillation is inevitable (deferred to Pendulum, Unit_Circle)

2. **Mechanical oscillation** (WaveFunctions_Pendulum)
   - Gravity + restoring force + momentum = rhythm
   - Captures: pendulum period T = 2π√(L/g), chaos in the double pendulum
   - Leaks: the mathematical identity of sine (why *this* shape?) — deferred to Unit_Circle

3. **Spatial oscillation** (WaveFunctions_Sine_Space)
   - Sine as architecture — wave frozen into walkable geometry
   - Captures: sine as displacement field, phase offsets as spatial propagation
   - Leaks: *why* this shape and not another; temporal propagation

4. **Trigonometric origin** (WaveFunctions_Unit_Circle)
   - The Rosetta Stone: x=cos(θ), y=sin(θ) as θ sweeps 2π
   - Captures: oscillation IS rotation projected to a line
   - Leaks: what happens when many sources oscillate simultaneously

5. **Propagation through medium** (WaveFunctions_3D_Wave_Propagation)
   - Waves travel — pattern moves, medium stays
   - Captures: sin(ωt − k·dist), inverse-square attenuation, superposition
   - Leaks: what the wave is made of when the medium is air (sound)

6. **Material instantiation** (Effect_Sound, AirMusic, Bernini, Sky_Stairs, TrigWalkingPath)
   - The same primitive expressed in different materials: audio, fabric, stone, staircase, footpath
   - Captures: waves are substrate-agnostic
   - Leaks: what happens when the wave refuses to oscillate, or when the signal is only noise

7. **Silence / noise floor** (WaveFunctions_John_Cage)
   - There is no zero signal — the noise floor is the irreducible oscillation
   - Captures: aleatoric composition, ambient drift, thermal noise
   - Leaks: randomness as correlated wave (forward leak to the Randomness sequence)

8. **Synthesis theorem** (WaveFunctions_Synthesis_Lab)
   - Fourier: every signal = Σ Aₙ·sin(nωt + φₙ)
   - Captures: harmonics as integer multiples, resonance, biological oscillation
   - Leaks: how oscillation couples (chains of oscillators → physics simulation, softbodies)

9. **Resonance as relation** (Chamber_Waves — catalyst chamber)
   - Resonance with a creature: wave matching becomes synchronization
   - Captures: wave-as-relationship, catalyst integration
   - Leaks: transition to Physics Simulation / Procedural Audio sequences

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | WaveFunctions_Intro | Parameters vocabulary | oscillation_controlled_cube | Needs evolution — has full docset |
| 2 | WaveFunctions_Pendulum | Mechanical oscillation | PendulumWave, foucault_pendulum | Needs evolution |
| 3 | WaveFunctions_Sine_Space | Spatial sine | sine_space, sine_wall_corridor | Needs evolution |
| 4 | WaveFunctions_Unit_Circle | Rotation→oscillation | unit_circle_advanced, SimpleOscillatingBridge | Needs evolution |
| 5 | WaveFunctions_3D_Wave_Propagation | Propagation & interference | wave_propagation_3d, kusama_sine | Needs evolution |
| 6 | WaveFunctions_Effect_Sound | Wave → audible | Rack* synths, VRAudioMonitor | Needs evolution |
| 7 | Wavefunctions_Bernini | Wave → sculpted form | bernini_columns, ElphabaDress | Needs evolution |
| 8 | WaveFunctions_John_Cage | Silence / noise floor | john_cage_tech_noir, ruth_asawa_sculpture | Needs evolution |
| 9 | WaveFunctions_AirMusic | Generative / position-triggered sound | SystemsMusicTest, RackAmbientDrone | Needs evolution |
| 10 | Wavefunctions_Sky_Stairs | Vertical embodied wave | sine_cylinder_staircase | Needs evolution |
| 11 | WaveFunctions_TrigWalkingPath | sin/cos phase offset walked | TrigWalkingPath | Needs evolution |
| 12 | WaveFunctions_Synthesis_Lab | Fourier synthesis | additive_wave_demo, chladni_plate, lissajous_curves | Needs evolution |
| 13 | Chamber_Waves | Resonance chamber | waterbomb_enemy + catalyst | Needs evolution; barely-written intent.md |

## 4. Artifact Inventory

The wavefunctions domain is the most artifact-rich sequence in the project. Registry counts:
- `commons/artifacts/registry/wavefunctions.json` — **140 artifacts**
- `commons/artifacts/registry/wavefunctions_extra.json` — **9 artifacts**
- Source tree: `algorithms/wavefunctions/` — **~60 subfolders**

### Spine artifacts (per concept-atom)

| Concept | Artifact | File | @identity truth |
|---------|----------|------|-----------------|
| Parameters | oscillation_controlled_cube | algorithms/wavefunctions/…/OscillationCurve.gd | "A sine wave is the shadow of uniform circular motion projected onto a line." |
| Parameters (reference) | static_reference_cube, y_oscillation_cube | same folder | stage progression in map_info |
| Pendulum | PendulumWave.gd | algorithms/wavefunctions/oscillation_driver/PendulumWave.gd | "Gravity and a string are sufficient to generate periodic motion." |
| Pendulum (chaos) | DoublePendulum.gd | same folder | (no truth statement — gap) |
| Pendulum (Earth) | foucault_pendulum.gd | algorithms/wavefunctions/oscillation_driver/ | — |
| Spatial sine | sine_space.gd, SineSpace.gd | algorithms/wavefunctions/sine_space/ | "The sine function is universal — it generates different worlds depending on the coordinate system you wrap it in." |
| Spatial sine (corridor) | sine_wall.gd | algorithms/wavefunctions/sine_wall/ | "A wave is not a thing — it is a pattern of displacement that moves through things." |
| Unit circle | UnitCircle.gd, UnitCircleTrig.gd | algorithms/wavefunctions/unit_circle/ and /oscillation_driver/ | "The unit circle is the Rosetta Stone of trigonometry." |
| Unit circle (bridge) | SimpleOscillatingBridge.gd | algorithms/wavefunctions/unit_circle/ | "A traveling wave is identical oscillators displaced in phase." |
| Propagation | WavePropagation3D.gd | algorithms/wavefunctions/wave_propagation_3d/ | "Every point in a wave field is the sum of all waves that have reached it — superposition is the law." |
| Interference | wave_interference_3d | algorithms/wavefunctions/wave_interference_3d/ | "Two waves meeting don't fight — they add. The pattern they make holds more information than either wave alone." |
| Beat frequency | beat_frequency_demo | algorithms/wavefunctions/beat_frequency/ | "When two nearly identical things interfere, their tiny difference becomes the loudest signal." |
| Sound synthesis (4 racks) | Rack303Acid, RackDX7Piano, RackMoogBass, RackSineBasic | algorithms/wavefunctions/ | — |
| FM | DualBallFMController.gd | algorithms/wavefunctions/ | "All timbral complexity is phase modulation of simple oscillators." |
| Spectrum | SpectralDisplayController, GameSoundMeter | algorithms/wavefunctions/spectralanalysis/ | "sound is invisible until you give it a surface" |
| Baroque form | BerniniColumns.gd | algorithms/wavefunctions/berninicolumns/ | "A spiral column is a sine wave wrapped around a vertical axis." |
| Fabric wave | ElphabaDress.gd | algorithms/wavefunctions/cloaks/ | "Fabric is a surface that remembers every wave that passes through it." |
| Vertical wave | sine_cylinder_staircase | algorithms/wavefunctions/sine_cylinder_staircase/ | "A spiral staircase with sine-modulated radius is a helix that breathes." |
| sin/cos walk | TrigWalkingPath.gd | algorithms/wavefunctions/oscillation_driver/ | "Sine and cosine are the same motion, separated by a quarter turn." |
| Silence | john_cage_tech_noir.gd | algorithms/wavefunctions/noirsequencer/ | "Silence is not the absence of sound — it is the space between algorithmically chosen events." |
| Silence (visual) | ruth_asawa_sculpture.gd | algorithms/wavefunctions/ruth_asawa/ | "A wire sculpture is a surface of revolution that has learned to listen." |
| Fourier | FourierTransform.gd, additive_wave_demo | algorithms/wavefunctions/fourier_transform/ | "every signal is a sum of pure frequencies — the Fourier transform does not create this decomposition, it reveals the one that was always there" |
| Resonance (visible) | chladni_plate | algorithms/wavefunctions/ | — |
| Frequency ratio | lissajous_curves, Lissajous3D | algorithms/wavefunctions/lissajous_curves/ | "The ratio of two frequencies determines whether a curve closes or wanders forever." |
| Spherical | SphericalHarmonics.gd | algorithms/wavefunctions/spherical_harmonics/ | "Every function on a sphere decomposes into spherical harmonics, the way every signal decomposes into sines." |
| Coupled oscillators | coupled_oscillator_lattice, spring_network | algorithms/wavefunctions/ | — |
| Standing waves | standing_waves | algorithms/wavefunctions/standing_waves/ | — |
| Resonance frequencies | resonance_frequencies, resonating_metallophone | algorithms/wavefunctions/resonancefrequencies/, /resonance/ | "Every object has frequencies at which it wants to vibrate — striking reveals its voice." |
| Melody path | MelodyChaser3D.gd | algorithms/wavefunctions/ | "A melody is a path through pitch-space traversed in time." |

### Artifact density by map

| Map | Artifact count | Budget | Notes |
|-----|---------------:|--------|-------|
| WaveFunctions_Intro | 15 | environment | Bloated — 4 distinct cube variants, pickup cubes, transformation cubes |
| WaveFunctions_Pendulum | 10 | environment | Balanced |
| WaveFunctions_Sine_Space | 6 | world_scale | Focused |
| WaveFunctions_Unit_Circle | 6 | environment | Focused |
| WaveFunctions_3D_Wave_Propagation | 3 | world_scale | Minimal, strong |
| WaveFunctions_Effect_Sound | **21** | mixed | Very heavy — audio lab character, could split |
| Wavefunctions_Bernini | 4 | compact | Focused |
| WaveFunctions_John_Cage | 4 | environment | Focused (deliberate sparsity matches theme) |
| WaveFunctions_AirMusic | 8 | environment | Balanced |
| Wavefunctions_Sky_Stairs | 4 | environment | Focused |
| WaveFunctions_TrigWalkingPath | **2** | world_scale | Minimal — intent notes an overlay gap |
| WaveFunctions_Synthesis_Lab | **24** | world_scale | Heaviest in sequence — by design (synthesis) |
| Chamber_Waves | — | chamber | Not in artifact_groups |

## 5. Gap Analysis

### Sequence structure

- **13 maps is at the high end**, but most earn their place. The red thread has a clean first half (Intro → Pendulum → Sine_Space → Unit_Circle → Propagation — 5 maps building the theory). The second half is material instantiation (Sound, Bernini, Cage, AirMusic, Sky_Stairs, TrigWalkingPath — 6 maps) which could be tightened.
- **The middle sags**. Maps 7–11 all demonstrate "the wave made material" in different substrates. There's no conceptual escalation, only substrate rotation. Bernini → Cage → AirMusic → Sky_Stairs → TrigWalkingPath reads more like a gallery than a progression.

### Ordering issues

- **Unit_Circle (4) should arguably come before Sine_Space (3).** Unit_Circle explains *where sine comes from* (projection of rotation). Sine_Space then shows *what happens when you wrap that function around 3D*. Current order presents spatialization before origin. Intent files acknowledge this tension — the Unit_Circle intent calls itself "the conceptual keystone" and "the deepest explanation" while sitting in position 4 after the spatialization.
- **Effect_Sound (6) could profitably move earlier.** Sound is the most visceral wave instance; placing it right after Propagation (where wave = disturbance in medium) makes the sound=pressure-wave-in-air connection immediate. Currently five conceptual maps precede any audio.
- **TrigWalkingPath (11)** reinforces Unit_Circle's lesson (sin vs cos phase) but arrives seven maps later. It should either move adjacent to Unit_Circle, or its own intent.md gap ("an overlay showing the unit circle rotating as the learner walks") should be built.
- **Sky_Stairs (10)** is another Sine_Space variant (spatial sine, now vertical). Consider merging with Sine_Space or placing them adjacent.

### Bloat / redundancy

- **WaveFunctions_Intro has 15 artifacts** including four near-duplicate cubes (`pick_up_cube`, `pickup_cube_rotating`, `pickup_cube_static`, `pickup_cube_transforming`) plus `rotating_cube`, `rotating_cube_demo`, `rotatescalecubes`, `cube_scene`, `transformation_cube`, `oscillation_controlled_cube`, `y_oscillation_cube`. The stage progression in documentation specifies only four stages (static, y-osc, rotation, combined) — the other ~8 cubes are incidental clutter.
- **Synthesis_Lab has 24 artifacts** including lab dressing (`chemicalapparatus`, `samplevialrack`, `electronicscales`, `microscope`, `multimeter`, `holographicdisplay`, `petri_dish_worms`, `dna_specimen`, `double_helix_scene`) that teach oscillation-in-biology but aren't anchor teachers. The core Fourier/harmonic artifacts (additive_wave_demo, chladni_plate, lissajous_curves, UnitCircleTrig) are excellent but could drown in the dressing.
- **Effect_Sound has 21 artifacts** with overlapping synth racks (303, DX7, Moog, Sine Basic, Mario). Genre coverage is nice but five racks may be four too many for a single map.

### Chamber_Waves is thin

- `intent.md` is 5 lines (vs 7–8 for other maps). No technical.md. No blurb.md content beyond the auto stub.
- Not listed in `artifact_groups` of the sequence JSON — the rest of the catalyst-chamber infrastructure (catalyst, Science Screen, creature arena) is implicit rather than specified.
- The "waterbomb_enemy resonance" mechanic is promising but undocumented.

### Missing concept-artifacts

- **Small-angle approximation** (Pendulum): no artifact shows the approximation breaking down at large amplitude; DoublePendulum has no @identity truth.
- **Standing waves** (between propagation and Fourier): `standing_waves` artifact exists but isn't placed in any map.
- **Harmonic series made audible**: `RackSineBasic` + additive_wave_demo approximate this, but no single artifact plays "fundamental → +2nd harmonic → +3rd" as a guided progression.
- **Beat frequency** (`beat_frequency_demo` exists, strong truth statement) — not placed in any map.
- **Wave interference** (`wave_interference_3d` exists, strong truth statement) — listed in registry but not in any map's artifact_groups.
- **Spherical harmonics** (`SphericalHarmonics`) placed in Intro as one of 15 artifacts — this is a Synthesis-Lab-tier concept buried too early.

### Missing transitions

- **Forces → Wavefunctions**: the sequence truth says "inheriting oscillation from Forces" but the Intro map doesn't explicitly reference springs/Hooke's Law as the bridge. A `spring_demo` artifact exists but appears only in Synthesis_Lab, not Intro.
- **Wavefunctions → Physics Simulation**: the `unlocks` field names `physicssimulation` but no bridge map (coupled oscillator chain as proto-mesh?). Coupled_oscillator_lattice exists but isn't placed.
- **Wavefunctions → Procedural Audio**: `unlocks` names `proceduralaudio`. The Rack* artifacts are the bridge but the hand-off isn't narrated.

### Documentation gaps

- **0 evolutions written** (vs 3 for primitives). This is a major sequence with rich intent.md but no evolution files — the narrative layer on top of the intent is missing.
- Only WaveFunctions_Intro has the full 4-doc set (blurb, intent, technical, critical, summary).
- Chamber_Waves has essentially no documentation.

## 6. Forward Leaks

Concepts this sequence raises but cannot hold — the ontological edges:

- **Chaos / sensitive dependence** → Chaos sequence (double pendulum shown here, theory there)
- **Audio synthesis as standalone discipline** → Procedural Audio sequence (deferred from Primitives and expanded here, but a full synthesizer pedagogy needs its own sequence)
- **Coupled oscillators → mesh physics** → Physics Simulation / Softbodies (springs oscillate; a grid of springs is a cloth)
- **Random signals as correlated waves** → Randomness (Perlin noise = sum of sines with random phases; the John Cage map flirts with this but doesn't close it)
- **Wave equation as PDE** → Numerical Methods (the sequence demonstrates but never writes ∂²u/∂t² = c²∇²u)
- **Fourier → spectral methods** → Signal Processing / ML (FFT shown; convolution, filters, compression deferred)
- **Resonance as causal coupling** → Physics Simulation (what vibrates with what and why)
- **Music theory as emergent structure** → absent — harmonic_distance_table hints but no sequence owns it
- **Quantum wavefunctions** → absent from curriculum entirely; the term "wavefunctions" here is classical, not Ψ
- **The wave that doesn't close (quasi-periodic, irrational ratios)** → Lissajous_curves hints; fractals and chaos own this later

## 7. Proposed Ordering

### Option A: Minimal reordering (preserve all 13 maps)

```
1. WaveFunctions_Intro              — parameters vocabulary
2. WaveFunctions_Pendulum           — oscillation from physics
3. WaveFunctions_Unit_Circle        — *moved earlier* — where sine comes from
4. WaveFunctions_Sine_Space         — sine as spatial displacement
5. Wavefunctions_Sky_Stairs         — *moved earlier, adjacent to Sine_Space* — vertical sine
6. WaveFunctions_TrigWalkingPath    — *moved much earlier* — phase offset of sin vs cos walked
7. WaveFunctions_3D_Wave_Propagation — propagation, superposition, interference
8. WaveFunctions_Effect_Sound       — waves become sound
9. WaveFunctions_AirMusic           — generative / spatial audio
10. Wavefunctions_Bernini           — wave as form (sculpture)
11. WaveFunctions_John_Cage         — silence / noise floor
12. WaveFunctions_Synthesis_Lab     — Fourier: every signal = Σ sines
13. Chamber_Waves                   — resonance as relation
```

The key moves: pull Unit_Circle forward so origin precedes spatialization; cluster the three "spatial/embodied sine" maps (Sine_Space, Sky_Stairs, TrigWalkingPath); keep Bernini/Cage/AirMusic as the material-and-philosophy arc; Synthesis_Lab stays the capstone; Chamber_Waves closes.

### Option B: Consolidation (10 maps)

Merge:
- Sky_Stairs + TrigWalkingPath → one "embodied trig" map (they both teach walking the function)
- Effect_Sound + AirMusic → one "sound lab" map with Cage-adjacent silence zone
- John_Cage becomes a *zone* inside the sound lab rather than a full map

Result:
```
1. Intro · 2. Pendulum · 3. Unit_Circle · 4. Sine_Space · 5. Embodied_Trig
· 6. 3D_Propagation · 7. Sound_Lab (with Cage silence zone) · 8. Bernini
· 9. Synthesis_Lab · 10. Chamber_Waves
```

Simpler, but loses the deliberate sparsity of the Cage map and the distinct philosophical beat it provides.

### Recommendation

**Option A**. The 13-map count reflects real pedagogical scope (this is the sequence that teaches dynamics — it earns its length). The fix is reordering the first half so Unit_Circle precedes spatialization, and clustering the embodied-sine maps. The gallery-like middle is a feature when the substrates are distinct (stone, fabric, silence, ambient) — the issue is only that they currently arrive before the learner has propagation and sound to carry them.

Additionally:
1. Place `wave_interference_3d` and `beat_frequency_demo` artifacts — they have strong truths and nowhere to live.
2. Place `coupled_oscillator_lattice` and `standing_waves` somewhere between Propagation and Synthesis_Lab as the physical-bridge artifacts.
3. Move `SphericalHarmonics` out of Intro (it's Synthesis_Lab-tier).
4. Write Chamber_Waves properly: catalyst mechanic, creature resonance rules, Science Screen contents.
5. Build the Forces→Wavefunctions bridge by placing `spring_demo` in Intro.
6. Write evolutions for Unit_Circle, Synthesis_Lab, and Sine_Space first — they are the three conceptual peaks.

## Summary

Wavefunctions is the most artifact-rich sequence in the project (149 artifacts across two registries, ~60 algorithm folders) and also the most at risk of overflowing its own thread. Its red thread is excellent in principle — oscillation parameters → mechanism → spatialization → rotational origin → propagation → substrate-variation → Fourier synthesis → resonance-as-relation. But the current map order inverts origin and spatialization (Sine_Space precedes Unit_Circle), and five maps in the middle rotate substrates without escalating concept. The first half (maps 1–5) and the capstone (Synthesis_Lab) are strong. Intro is bloated (15 cubes). Chamber_Waves is thin. No evolutions are written. Three high-value artifacts (wave_interference_3d, beat_frequency_demo, standing_waves) exist in code but aren't placed in any map. The sequence is close to excellent — it needs surgery, not rebuilding.
