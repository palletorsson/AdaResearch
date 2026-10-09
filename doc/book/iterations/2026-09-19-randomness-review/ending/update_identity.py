from pathlib import Path
import json
b=Path('doc/book/iterations/2026-09-19-randomness-review/ending')
changes={
'algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd':[
('# Perlin Noise Bridge — from chaos to terrain.','# Perlin Noise Bridge — independent heights beside a spatially correlated field.'),
('# Shows how noise functions transform raw randomness into structured, terrain-like form.','# Compares two sampling procedures; one field is not transformed into the other.'),
('# essence: Perlin(x,y) = smoothstep(dot(gradient, offset)) — gradient noise with spatial memory','# essence: seeded uniform heights beside FastNoiseLite Perlin samples — independent draws versus spatial correlation'),
('# desire: see two grids side by side — one chaotic, one terrain — and feel the moment randomness becomes landscape','# desire: compare neighbouring heights before interpreting either grid as a landscape'),
('# emerges: the Perlin grid looks like terrain not because terrain was coded, but because neighbors remember each other','# emerges: the correlated field supports broader features; the colour mapping invites a landscape reading'),
('# truth: Coherence is not the opposite of randomness — it is randomness with memory.','# truth: Nearby samples can be related by a spatial construction without recording a history of visits.')],
'commons/artifacts/noise_mixer/noise_mixer.gd':[
('# essence: total(p) = Σ(i=0..octaves) persistence^i * noise(base_frequency * lacunarity^i * p) — each octave doubles frequency, halves amplitude, adds finer detail','# essence: sum i=0..octaves-1 of persistence^i times a sine-based function at base_frequency*lacunarity^i and seeded offsets'),
('# desire: to see how terrain emerges from iteration — one octave is a hill, four octaves is a landscape, and the only difference is repetition at scale','# desire: compare a broad sine-based layer with weighted additions at other scales before naming the picture as land'),
('# triggers: _ready → _generate_texture → per pixel sum octaves → clamp [0,1] → earth-tone color ramp (deep water → forest → rock → peak)','# triggers: startup and slider callbacks regenerate the finite sum, remap its own min/max range, then apply an earth-tone palette'),
('# emerges: altitude-colored terrain — the low-frequency base octave creates large valleys, high-frequency octaves texture the ridges; color reveals the hierarchy','# emerges: a normalized, landscape-like texture; neither the values nor the palette simulate geological processes'),
('# needs: real-time slider regeneration [missing], octave count control [has via export]','# needs: live OCT/LAC/PER slider regeneration [has], seeded-offset control [has]')],
'algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd':[
('# vs total darts gives ratio ≈ π/4. Live counter shows π estimate improving.','# vs total darts gives ratio ≈ π/4. The estimate need not improve on every sample.'),
('# QFEP: Computation through accumulation — random sampling converges to truth.','# QFEP: Computation through accumulation — the estimator depends on the sampling rule.'),
('# critical_parameter: max_darts — more darts means tighter convergence; error scales as 1/sqrt(n); disclosure —','# critical_parameter: max_darts — sampling uncertainty typically decreases as 1/sqrt(n) for independent uniform draws; disclosure —'),
('# truth: Randomness is not the enemy of precision — given enough samples, it converges to any truth.','# truth: Uniform samples estimate this circle-to-square area ratio; more biased samples would not repair a biased sampler.')],
'algorithms/randomness/pheromone_terrain/pheromone_terrain.gd':[
('##   avoid  the sign of the gradient flipped — flee the strongest scent. Anti-stigmergy:\r\n##          a trail as a record of where you no longer need to go. The ridges never form;\r\n##          the walkers spread and the plot churns evenly.','##   avoid  choose the weakest sensed concentration instead of the strongest.\r\n##          Deposits now discourage a return; the resulting coverage and ridges depend\r\n##          on the seed, boundary, random branch and observation interval.'),
('## interval so the dynamics are the shipped dynamics played fast. 0 is the shipped','## interval for a fixed-step comparison. The live frame-based decay schedule can differ.\r\n## 0 is the shipped'),
('## interval each step so this is the shipped dynamics played fast rather than a\r\n## different process. At the shipped 0 it returns before touching anything.','## interval each step. This fixes the decay schedule; the live frame-based schedule\r\n## may differ. At the shipped 0 it returns before touching anything.')]
}
for s,pairs in changes.items():
 p=Path(s);data=p.read_bytes()
 for old,new in pairs:
  a,b=old.encode(),new.encode();assert data.count(a)==1,(s,old);data=data.replace(a,b)
 p.write_bytes(data)
print('source_identity_files',len(changes))
