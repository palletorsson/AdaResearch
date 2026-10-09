# Noise_Space_10

**Active hall 7 in noise. Batch: N-EXT. Two primary works; 36 rendered checks passed; headset pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## Which bodies can a field carry once it becomes ground?

Body/layer: A body crossing an eight-metre heightfield, a steady surrounding margin, two proposed routes and an independently pulsing orb.

Proposed primary encounter: `noise_space`, `dark_sphere`.

## Starting evidence

Restored the declared hall after Noise_Inside_Noise in the active museum. Every original structure cell remains. Both original works are retained, with the orb on the east raised platform. Two added ramps connect the margin to the entrance and teleporter approach. stand:walk keeps one measured OpenSimplex2S field fixed while height scale changes from 0 to .90. Mesh and collider rebuild together only when the body is off the terrain. The recorded desktop body crosses route A at .25 and stops partway at .90; this does not classify all possible routes. Historical ten-slider prose is archived and corrected.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 3}. Current final: 1043 words.

Current primaries: noise_space, dark_sphere. Book anchors: noise_space, dark_sphere.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Eight-metre terrain, 81 × 81 vertices, height base 1 m and a .75 m edge envelope meeting a stable surrounding margin. Preserve the existing grid structure and add entrance/exit ramps.
2. HEIGHT, ROUTE, SAMPLE and RESET through the native pointer. Both player_body and em_walker prevent rebuilding occupied terrain.
3. Two proposed routes and a supported section display with five shared witnesses; readings interpolate the actual mesh triangles. Keep the original terrain available without stand:walk.

## Revise final.md

1. Choose a crossing before explaining the field-to-height rule. Return to the margin and raise HEIGHT; revisit the same features.
2. Follow a section without mistaking a line for a body. Compare actual desktop crossing and stall with the recorded section slopes.
3. Read exact height, border-envelope and mesh-to-collision code. Ask what the heightfield cannot hold: a cave needs more than one height.
4. Keep the orb’s independent time. Prepare a controlled generator comparison in Noise_Perlin_Simplex.

**Code to trace and quote after implementation:** NoiseSpace.gd: optional stand:walk, ground_at, edge_weight, walk_height_at and generate_space; noise_walk_study.gd: local controls, routes and profile. The original TopologySpace mesh/collision helpers remain unchanged.

## Evidence to return

- 36 rendered checks, including four actual pointer controls, local ownership, native walker guards, both ramps and museum continuity.
- All 6,561 vertices and collision faces agree at four height scales; five fractional-grid physics rays per scale agree with the triangle-interpolated profile.
- Same forward desktop attempt crosses at .25 and stops partway at .90. Other paths, body configurations and headset checks remain open.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Fable may make a mountain refuge, a rolling promenade or another world that carries the body differently. The terrain should invite a route, not become generic noise scenery.

**Reusable method:** R4 sample-to-body mapping; R5 arena boundary; R6 local state/seed.

## Open and inspect

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
