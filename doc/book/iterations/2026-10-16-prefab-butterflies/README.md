# Butterflies belong to the prefab tables

User request: improve the apparently upside-down butterflies, increase their number, and keep them only inside `prefab_disorder`.

The room-wide butterfly's turning function mixed local movement with a world-space `look_at` target. It now constructs a local basis and preserves its scale. The wing mesh inspection confirms that its dorsal normal is +Y and the image's head faces −Z.

Entropy Workshop replaces its separate aisle swarm with `#butterflies:16` on the existing prefab installation. Its current curated location (8,12), yaw 180°, is retained. The bounded flock reuses the monarch wing artwork, without the old room-wide movement script, helper or cameras. Sixteen butterflies begin immediately; each has its own phase and beat rate. Wingspan is about 28 cm, half the old scene's scale. Smooth turns and shallow climbs keep the body upright.

The habitat is prefab-local: x −2.2…2.2, y 1.35…2.8, z −0.7…0.7 metres. Bodies remain inside an inset of 19 cm so wing tips also fit. Position and orientation follow a moved or rotated installation. There is no attraction to the nearby point field. GALLERY pauses and hides flight; returning resumes it. Other prefab placements have no flock unless configured. The original general butterfly artifact remains available to other maps.

The flock uses a private seeded stream, independent of hybrid draws. It is staging, not an entropy measure, and is intentionally absent from saved hybrid records. Seeded hybrid generation, gallery and replay remain intact.

`verify.gd` checks two simulated minutes of body and wing containment, upright orientations, long-frame containment, local transform following, gallery visibility, repeatable initial flock and unchanged hybrid records. The test yields deferred physics cleanup before exiting. `museum_probe.gd` checks actual installation, absence of the old aisle swarm, a minute of containment, controls/state preservation and native views. Scripted checks do not establish headset comfort.

Run:

```powershell
python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag prefab-butterflies --probe doc/book/iterations/2026-10-16-prefab-butterflies/museum_probe.gd
```
