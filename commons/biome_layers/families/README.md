# Composition families of the biome cage

The cage (`commons/artifacts/biome_vitrine/biome_vitrine.gd`) draws ONE composition per
seed and the halls of the ladder are its states. The seed picks a FAMILY, and the family
decides where the same elements fall: the point at the golden section of the work's spine,
the second point at its foot, the rod between them, two tilted planes, a cube at the head,
a beam off the axis, the spheres, the flowers seeded nearest the spine.

Three families are built into the cage (`diagonal`, `vertical`, `split` — a straight spine).
Every file in this folder is one more, written to this contract and loaded by path.

## Contract (`<name>.gd`, `extends RefCounted`, NO class_name)

```gdscript
const NAME := "<name>"                       # lower-case, the token value: #family:<name>
const REFERENCE := "<painter, work, year>"   # the composition this family is after
const LINE := "<one sentence: what this family argues about arrangement>"

## Once per cage. `rng` is seeded from (seed, "score") — draw ALL randomness from it.
## `inner` = half the cage side minus 0.5, in metres (2.0 for a 5 m cage, 11.5 for 24 m).
## `sx`, `sz` are ±1 mirror signs the seed drew; use them so mirrored seeds mirror.
## Must return: "a", "b" (Vector3, y = 0 — the spine's head and foot, |a - b| >= 1.1 * inner),
## "lift" (float, 0.6 .. 1.8, multiplies every element's height), "tilt0", "tilt1" (degrees,
## the two planes' tilts about their own x). Any private keys prefixed "<name>_".
static func score(rng: RandomNumberGenerator, inner: float, sx: float, sz: float) -> Dictionary

## The spine. t in [0, 1]; path(s, 0) == s.a, path(s, 1) == s.b (within 1e-4); y = 0.
## Straight, an arc, a fan, a spiral, a bent elbow, a meander — inside |x|, |z| <= inner.
static func path(s: Dictionary, t: float) -> Vector3

## Across the spine. u in [-1, 1]; an ABSOLUTE xz position (y = 0), u = ±1 near the cage's
## inner edge, u = 0 the family's cross-centre (the cage centre for the straight families).
static func across(s: Dictionary, u: float) -> Vector3

## Heading along the spine at t, radians about +y, as atan2(dx, dz) of the travel direction.
static func heading(s: Dictionary, t: float) -> float
```

Where the elements land (fixed t / u, so a family places them by shaping path and across):
point `path(0.618)` · second point `path(0.15)` · plane 0 `path(0.382)` · plane 1 `across(-0.6)`
· cube `path(0.85)` · boundary plane `path(0.5)` · ring centre `path(0)` · the flowers ranked by
distance to the spine.

Tilt is measured, not named: a plane stands upright at tilt 0 and lies flat at tilt 90 (rotation.x).

Every family ships with `commons/testing/probe_biome_family_<name>.gd` (headless, exits 1 on a
failed check): bounds, endpoints, span, determinism, and an ASCII plan of seed 7 at inner 2.0.
