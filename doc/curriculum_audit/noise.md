# Noise — Curriculum Audit

**Sequence ID:** `noise`
**Title:** Noise: Entropy with Memory
**QFEP term:** λE(S) — λ tuned for coherence
**Spine order:** 8 (phase E_entropy)
**Maps declared:** 10 (Random_Noise_Types, Noise_Columns, Noise_One, Noise_Voxel, Noise_6_Wall, Noise_Inside_Noise, Noise_Space_10, Noise_Perlin_Simplex, Lab_Path, Chamber_Noise)
**Deferred maps:** 3 (Noise_Blue, Noise_Functions, Noise_Volume)
**Evolutions written:** 0 (only blurb/intent/technical)

## 1. Core Concept

Noise is **randomness that remembers its neighbors**. Where pure entropy forgets instantly (each coin flip independent), noise maintains continuity — each sample smoothly related to those around it. The sequence teaches noise as the λ parameter of QFEP tuned for coherence: structured disorder, organic unpredictability, entropy constrained by smoothness. The pedagogical arc moves from noise-as-distribution (spectral identity) through noise-as-texture (single field on geometry) to noise-as-architecture (discretized worlds) to noise-as-algorithm (GPU hash, Perlin vs Simplex). The sequence is the bridge between Randomness (memoryless) and Procedural Generation (worlds assembled from structured chaos). Its central claim: entropy's E term is not a scalar but a texture, and the politics of noise is the choice of filter.

## 2. The Red Thread

1. **Spectrum** (Random_Noise_Types)
   - Randomness is not monolithic — white/blue/pink/brown noise differ in frequency weighting
   - Captures: the noise-color analogy, constrained vs unconstrained placement, that "more random-looking" can mean "mathematically less random"
   - Leaks: what coherent noise (gradient-based) looks like as a field

2. **Coherence / Displacement** (Noise_Columns)
   - A single 3D Perlin field deforms geometry; adjacent vertices get adjacent displacements
   - Captures: noise as sculptural force (Bernini melt), reversible entropy, neighborhood preservation
   - Leaks: how to get richer detail than a single frequency provides

3. **Octaves / fBM** (Noise_One)
   - Fractal Brownian Motion — sum of noise at doubling frequencies, halving amplitudes
   - Captures: fractal summation, persistence, lacunarity, natural scale invariance, tileability on a torus
   - Leaks: what happens when noise is discretized into solid/void

4. **Discretization / Threshold** (Noise_Voxel)
   - Continuous field sampled on a voxel grid, thresholded to binary solid/void
   - Captures: noise-as-architecture, caves/overhangs/floating islands, threshold as political act
   - Leaks: how this scales to millions of samples in real time

5. **GPU / Hash** (Noise_6_Wall)
   - Stateless hash-based noise in a fragment shader, six octaves per pixel
   - Captures: parallel evaluation, hash-as-gradient-table, resolution independence, entropy as pure computation
   - Leaks: what non-additive composition can produce

6. **Domain Warping** (Noise_Inside_Noise)
   - Noise distorts the input coordinates of another noise — `noise(p + noise(p))`
   - Captures: recursive composition, turbulence, marble/cloud/skin textures, information scrambled but not lost
   - Leaks: how the full parameter space connects these techniques

7. **Parameter Space** (Noise_Space_10)
   - Ten sliders: position (xyz), time, octaves, persistence, lacunarity, frequency, amplitude, seed
   - Captures: meta-view, configurations as points in a 10-dim manifold, distribution-thinking vs object-thinking
   - Leaks: that these parameters are algorithm-relative — Perlin and Simplex respond differently

8. **Algorithms / History** (Noise_Perlin_Simplex)
   - Perlin (1983, cubic lattice) vs Simplex (2001, simplicial grid) side by side
   - Captures: axis-aligned artifacts as lattice signature, evolution of an algorithm, geometry shapes output
   - Leaks: into procedural generation and morphogenesis (downstream sequences)

9. **Return** (Lab_Path)
   - Dark-sphere corridor back to Lab; minimal navigation
   - Captures: threshold crossing, "becoming doesn't announce itself"
   - Leaks: the chamber moment (Chamber_Noise) where the player sculpts world

10. **Chamber** (Chamber_Noise)
    - Catalyst chamber — no weapon, no creature, player sculpts terrain with Perlin
    - Captures: world-building as synthesis, player-as-designer
    - Leaks: into procgen/morphogenesis sequence

## 3. Map-to-Concept Mapping

| Order | Map | Concept | Anchor Artifact | Status |
|-------|-----|---------|-----------------|--------|
| 1 | Random_Noise_Types | Spectrum (white/blue/pink) | NoiseColors3D, WhiteNoiseGallery | intent ✓, no evolution |
| 2 | Noise_Columns | Coherent displacement | MeltingBerniniScene | intent ✓, no evolution |
| 3 | Noise_One | Octaves / fBM | noiselayers, noisetorus | intent ✓, no evolution |
| 4 | Noise_Voxel | Discretization / threshold | perlin_terrain_sculptor, voxelnoise | intent ✓, no evolution |
| 5 | Noise_6_Wall | GPU / hash noise | shader_noise_space | intent ✓, no evolution |
| 6 | Noise_Inside_Noise | Domain warping | noisesphere | intent ✓, no evolution |
| 7 | Noise_Space_10 | Parameter space | noise_space | intent ✓, no evolution |
| 8 | Noise_Perlin_Simplex | Algorithm comparison | perlin_noise, simplex_noise, noise_terrain, perlin_noise_terrain, configurable_portal | intent ✓, no evolution |
| 9 | Lab_Path | Return corridor | dark_sphere | blurb ✓ |
| 10 | Chamber_Noise | Synthesis / catalyst | (catalyst, none specified) | blurb ✓ minimal |

## 4. Artifact Inventory

Artifacts grouped by concept-atom:

| Concept | Artifact | File | Status |
|---------|----------|------|--------|
| Spectrum — full color map | NoiseColors3D | algorithms/randomness/whitenoise/ | ✓ registered |
| Spectrum — white baseline | WhiteNoiseGallery | algorithms/randomness/whitenoise/ | ✓ registered |
| Spectrum — spectrum 3D | noise_spectrum_3d, white_noise_spectrum | algorithms/randomness/whitenoise/ | ✓ |
| Spectrum — blue noise | blue_noise | registered | ✓ (map Noise_Blue is deferred) |
| Point placement (companion) | randompoint, randompoints | commons/primitives/ | ✓ (borrowed from randomness) |
| Coherent displacement | MeltingBerniniScene | algorithms/proceduralgeneration/hybrid_complex/berninicolumns/ | ✓ registered |
| Octaves — layers | noiselayers | algorithms/randomness/noiselayers/ | ✓ |
| Octaves — wrapped | noisetorus | registered | ✓ |
| Octaves — shader | shader_07_noise, noiseroom | algorithms/shaders/, algorithms/randomness/shadernoisespace/ | ✓ |
| Octaves — wall | noisewall | algorithms/randomness/noiselayers/ | ✓ |
| Voxelization | voxelnoise, voxelnoise1 | algorithms/randomness/voxelnoise/ | ✓ |
| Voxelization — interactive | perlin_terrain_sculptor | commons/artifacts/perlin_terrain_sculptor/ | ✓ registered |
| Voxelization — marching cubes | marchingcubes_voxel_noise_demo | registered | ✓ |
| Voxelization — ROIs | VoxelNoiseROIs | registered | ✓ |
| GPU / hash | shader_noise_space | algorithms/randomness/shadernoisespace/ | ✓ |
| GPU / cellular | shader_08_cellularnoise, worley_noise, pool_hole_noise | algorithms/shaders/, commons/artifacts/, algorithms/randomness/noise/cellularnoise/ | ✓ |
| Domain warping | noisesphere | registered | ✓ |
| Domain warping — other | noisetext | registered | ✓ (decorative) |
| Parameter space | noise_space | registered | ✓ |
| Algorithm — Perlin | perlin_noise, perlin_noise_terrain, perlinvolume, perlin_noise_clouds | algorithms/randomness/perlinnoise/, perlinnoiseclouds/ | ✓ |
| Algorithm — Simplex | simplex_noise | registered | ✓ |
| Algorithm — Value | value_noise | registered | ✓ (underused) |
| Algorithm — Worley/Cellular | worley_noise, shader_08_cellularnoise | commons/artifacts/worley_noise/, algorithms/shaders/ | ✓ (deferred map Noise_Functions would host) |
| Terrain | noise_terrain, noise_terrain_with_blobs, noiseterrain, noise_blob_spawner | algorithms/randomness/noiseterrain/ | ✓ |
| Flow / vectors | curl_noise_particles | commons/artifacts/curl_noise_particles/ | ✓ but **not placed in any noise map** |
| Flow / vectors — flowfield | VectorFieldFlow | algorithms/vectors/flowfield/ | algorithm_path declared, **no map anchors it** |
| Bridge (to procgen) | perlin_noise_bridge | algorithms/randomness/perlin_noise_bridge/ | ✓ |
| Composition | noise_mixer | commons/artifacts/noise_mixer/ | ✓ but **not placed in any noise map** |
| Hazard | noise_field | commons/hazards/noise_field/ | ✓ (reserved for downstream) |
| Cartridges (paper) | paper_perlin_noise, paper_noise_octaves, cartridge_noise_1d, cartridge_noise_octaves | commons/substrates/ | ✓ substrate coverage |
| Mesh op | noise_displace_op | commons/mesh_grammar/operations/ | ✓ (used in mesh grammar, not placed as artifact) |
| Anchor | dark_sphere | every map | ✓ constant |

**Strong coverage.** 30+ noise-flavored artifacts exist. The bottleneck is not artifact supply — it is artifact *placement* and *evolution text*.

## 5. Gap Analysis

### Missing evolutions (highest priority — same pattern as primitives)
All nine teaching maps have intent.md + technical.md + blurb.md written. None has an evolution file. This is where Noise lags behind Primitives (3 evolutions done).

### Concepts with artifacts but no map anchor
- **Vector fields / flow** — `curl_noise_particles` and the `algorithms/vectors/flowfield/` system are declared in `algorithm_paths` but no map places them. The learning_objective "Vector fields: noise as flow direction" is unanchored. Either fold into Noise_Space_10 or resurrect Noise_Volume.
- **Noise mixer** — `noise_mixer` artifact exists but is unplaced. Natural fit in Noise_Inside_Noise (alternative composition operator to domain warping) or a reopened Noise_Functions.
- **Cellular / Worley** — `worley_noise` + `shader_08_cellularnoise` exist but have no dedicated home. The deferred `Noise_Functions` was meant to hold these; its absence leaves a concept-atom implicit.
- **Value noise** — `value_noise` registered but unplaced. Belongs in Noise_Perlin_Simplex as a third algorithm for historical completeness.

### Deferred maps that leave thread gaps
- **Noise_Blue** (deferred): blue-noise artifact exists. The Random_Noise_Types intent carries this load single-handedly — a dedicated map would make the Poisson-disk / sampling story navigable (and connects forward to ML/dithering).
- **Noise_Functions** (deferred): would naturally host Worley/cellular, value noise, and a function-menu comparison. Its absence leaves the Perlin_Simplex map carrying more than it should.
- **Noise_Volume** (deferred): 3D volumetric noise (perlinvolume, perlin_noise_clouds) is shown only as terrain, never as clouds/smoke/gas. Forward leak to VFX and softbodies is weaker because of this.

### Ordering issues
The current order (spectrum → displacement → octaves → voxel → GPU → warp → params → algorithms) is strong pedagogically: concept before implementation. Two small frictions:

- **Noise_6_Wall (GPU) sits after Noise_Voxel.** This makes sense (octaves on GPU after octaves + voxelization), but it means learners meet shader programming before they've seen algorithm comparison (Perlin vs Simplex). The shader map assumes algorithm knowledge it hasn't formally introduced. Consider swapping Noise_6_Wall with Noise_Inside_Noise so the GPU reveal comes *after* warping as the capstone technique, or moving Perlin_Simplex earlier.
- **Chamber_Noise is after Lab_Path.** In every other sequence, the chamber is the final synthesis before the return corridor. Chamber_Noise appears to be the catalyst pickup AFTER Lab_Path according to the `maps` array — this inverts the pattern. Verify whether Lab_Path is truly meant to come before Chamber_Noise or whether the array order should be swapped.

### Weak transitions
- **Random_Noise_Types → Noise_Columns**: from statistical spectrum to geometric displacement is a large conceptual leap. No intermediate showing a 1D noise line or 2D noise heightfield before the full 3D vertex displacement. The deferred Noise_Functions or a new "Noise_One_Dimension" bridge map would help.
- **Noise_Perlin_Simplex → Lab_Path**: the sequence ends on an algorithm comparison, which is a technical peak, not a synthesis. Chamber_Noise is where synthesis happens but it is sparsely documented ("No weapon, no creature. You sculpt the terrain with Perlin noise.") — underwritten for a catalyst chamber.

### Documentation gaps
- Chamber_Noise has only a 2-line blurb and minimal intent. Compare to the intent depth of the teaching maps.
- Every map notes a "Gap" in intent.md (side-by-side white-vs-Perlin, audio octaves, cross-section of pre-threshold field, shader editor, grid-warp visualization, parameter bookmarks, lattice overlay). These are concrete build tasks queued by the writing itself — the sequence has already told us what to build next.

## 6. Forward Leaks

Concepts this sequence raises but cannot fully answer:
- **Procedural worlds** → proceduralgeneration sequence (explicitly unlocked)
- **Growth and pattern formation** → morphogenesis sequence (explicitly unlocked)
- **Softbodies / clouds / smoke** → wavefunctions and softbody sequences (volumetric noise is the bridge)
- **Vector fields as flow** → vectors/forces sequence (curl noise, flowfield)
- **ML and perceptual uniformity** → Blue-noise / Poisson-disk ties to dithering, stippling, neural texture synthesis
- **Shader authorship** → shaders sequence (the hash-function substrate)
- **Time as dimension** → wavefunctions (animated noise, frequency vs time)
- **Reversibility vs irreversibility** → thermodynamics / QFEP chamber (noise is reversible; domain warping is practically not)
- **Compression / information theory** → a deeper Randomness follow-up (why 1/f distributions appear everywhere)
- **The politics of the filter** → critical theory / QFEP (who chooses the smoothness, who names the spectrum)

## 7. Proposed Ordering

The current flow is close to optimal. Proposed refinement:

```
1. Random_Noise_Types      — Spectrum (white / blue / pink)
2. Noise_Columns           — Coherent displacement (single field on geometry)
3. Noise_One               — Octaves / fBM
4. Noise_Voxel             — Discretization / threshold
5. Noise_Inside_Noise      — Domain warping (advanced composition)
6. Noise_Perlin_Simplex    — Algorithm comparison (how it's made)
7. Noise_6_Wall            — GPU / hash (how it's computed at scale)
8. Noise_Space_10          — Parameter space (synthesis meta-view)
9. Chamber_Noise           — Catalyst: player sculpts world
10. Lab_Path               — Return corridor
```

Rationale for the swap:
- Put **Perlin_Simplex before GPU noise** — the GPU map builds on algorithmic knowledge.
- Put **Noise_Space_10 at the end** — the parameter-space meta-view works better as synthesis than as a step before algorithm comparison.
- Keep the chamber **before** Lab_Path (catalyst then threshold), matching the pattern used in other sequences.

### Priority actions
1. **Write evolutions** for the 8 teaching maps (Noise_One, Columns, Voxel, 6_Wall, Inside_Noise, Space_10, Perlin_Simplex, Random_Noise_Types). The intent.md files are rich enough to seed evolutions directly.
2. **Expand Chamber_Noise** — it's the weakest-documented map in the sequence and carries the synthesis load. Use the Chamber_Primitives pattern as template.
3. **Resurrect or discard deferred maps.** If Noise_Functions stays deferred, move Worley/value_noise into Perlin_Simplex and update the learning_objective for "vector fields" to explicitly map to an existing map.
4. **Place curl_noise_particles and noise_mixer** in an existing map — both are built artifacts currently homeless.
5. **Verify the Lab_Path ↔ Chamber_Noise order** in the `maps` array. Current order puts Lab_Path before Chamber_Noise, which contradicts the pattern used elsewhere.
6. **Build the per-map gap tasks** already written into every intent.md — the sequence has self-identified 9 specific missing visualizations.

## Summary

Noise is **artifact-rich and evolution-poor**. Unlike Primitives (which needs maps built), Noise needs its existing maps *deepened*: evolutions written, the Chamber expanded, 2–3 homeless artifacts placed, and one ordering ambiguity resolved. The red thread (spectrum → displacement → octaves → voxel → warping → parameter space → algorithms → GPU) is coherent and covers the QFEP λ-as-coherence framing well. The three deferred maps (Blue, Functions, Volume) would thicken rather than restructure the sequence. The sequence is ready for evolution-writing work; that is the head.
