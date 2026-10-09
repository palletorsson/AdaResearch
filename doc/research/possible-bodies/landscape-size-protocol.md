# Landscape size series — protocol recorded before results

Question: with each terrain and the release pattern held fixed, how does changing sphere radius change the number crossing the downstream outlet by the observation deadline?

Three selected field seeds (1729, 1730, 1731), three sphere radii (0.045, 0.075, 0.105 m), and two repeatability runs per seed/radius combination: 18 trials, each with four simultaneous trays and 32 spheres per tray. Maximum active bodies remains 128. Total releases: 2,304. Each seed supplies the same generated fields across the three radii. Sine ignores seed and therefore has one underlying landscape throughout, not three independent landscapes.

The only deliberately changed artifact setting within a seed block is radius. Tilt stays 20 degrees, relief 0.30 m, observation window 12 seconds, rate 60 physics ticks/s and Engine.time_scale 1. Mass stays 0.1 kg: this is not a constant-density comparison. Sphere geometry, contact spacing and derived inertia can change with radius. Centres, zero initial velocity, gravity, material and damping settings stay fixed. The 20 by 32 triangulated sampling grid and per-field min/max normalisation remain unchanged. The three terrain seeds are deliberately selected nearby integers, not a random sample of all terrains.

Radius order rotates by seed/repetition to make the order explicit and avoid always running the small spheres first. No randomisation or statistical independence is claimed. Repeated runs assess repeatability under this release arrangement. Spheres can collide and are not independent experimental replicates.

Record the three mutually exclusive outcomes: outlet crossed, still in at the deadline, other exit. Record the artifact snapshot each simulated second, first observed outcome-change tick per sphere, initial/final positions, the complete sampled height arrays, engine/settings and source hashes. Final positions of exited spheres are collection-display positions, not their exit locations. Event ticks are observations of the artifact's own state, not continuous collision times. The existing artifact deadline includes its initial activation tick; results use that declared counter consistently rather than claiming sub-tick exit-time accuracy.

Figures are chosen before the run: the first repetition at seed 1729 for each of the three radii. Keep all results, including identical results, failures and other exits. Report per-trial counts and within-seed paired differences. Do not infer generator-wide rankings, permanent trapping, entropy, hiding, human walkability or freedom from the counts.

These meshes and conditions differ from the historical 2021 Unity report. No numerical replication is claimed. The existing prototype's 45 checks establish its tested operation; this series investigates one experimental question using that implementation.
