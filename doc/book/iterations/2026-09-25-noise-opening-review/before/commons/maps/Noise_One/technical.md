# Noise One: implementation and limits

## Torus instrument

`noisetorus:180#stand:pair` at (5,4). Two equal TorusMesh objects, 96 rings and 40 ring segments, inner radius 0.18 m and outer radius 0.46 m. Both use `noiseTorus.gdshader`. The left relief/right colour assignment follows each holder, not the viewer's camera orientation.

FREEZE holds an artifact-owned accumulated time used by both shader stages and the CPU coordinate readout. Noise speed remains 0.935 and hue speed 0.725. The old approach set those speeds to zero, which reset the shader to time zero instead of preserving the displayed moment. Other shader consumers still default to engine TIME. The inherited one-hour offset wrap is not a proven seamless loop.

Pair mode replaces the fragile floating-point lattice hash with wrapped 32-bit integer operations, followed by the same cubic value interpolation. The CPU and GPU perform equivalent operations; a rendered 256-coordinate readback measures their difference. The original floating hash remains available to legacy single-ring mode. This changes the pair's field realization, not just its readout; baseline source and images are archived.

AMPLITUDE cycles 0, 0.01, 0.02, 0.04 m. FREQUENCY cycles 7, 14, 24 coordinate units per local metre. SAMPLE selects six angles around the outer equator. The marker sits 0.04 m beyond the analytically displaced coordinate. Readout values are rounded, and it refreshes about four times a second while running. FREEZE gives a stable comparison.

REMAP toggles brightness between `max(value, 0)` and `(value+1)/2`. The latter distinguishes signed values at the encoding stage; the final lit pixel is also affected by hue, illumination, rendering and display precision. Relief is evaluated at vertices, colour at fragments; neither the plate nor an analytical marker claims to measure a final pixel exactly. Rings have no colliders; bench and buttons do.

## Retained terrain

`noiselayers:0:0.8#stand:basin` at (5,7) attaches an optional staging script to the existing scene root. It retains the complete terrain generator and all three supplied FastNoiseLite resources. Scene cameras, environment and directional light are omitted only in this museum mode, where the museum supplies those services. Original meshes and all three grid planes are retained at 0.02 scale; grid material copies use fewer and fainter lines. The original root tilt is removed in the basin.

| Contribution | Runtime noise type | Seed | Base frequency | Octaves | Weight |
|---|---:|---:|---:|---:|---:|
| LOW | 1 | 54321 | 0.0056 | 4 | 12 |
| MIDDLE | 2 | 98765 | 0.0057 | 1 | 6 |
| HIGH | 1 | 12345 | 0.0175 | 3 | 1.5 |

Resource settings supplied in the scene take precedence over defaults that the generator constructs only when resources are absent. LOW/MIDDLE/HIGH isolate weighted resources, not individual octaves. SUM restores all three. Each rebuild samples 101×101 positions, combines heights, performs the original three-pass slope-dependent lowering and builds 20,000 triangles. Lowering is in-place, is order-sensitive and does not conserve material. It is not a hydraulic simulation.

The terrain generator and all its height functions are unchanged. Basin mode disables automatic LOD because the legacy LOD meshes bypass the lowering pass. It uses one triangle collider generated from the displayed mesh, rebuilt when a layer changes, instead of the legacy extra walkability collider. Shader normals are a lighting approximation and do not establish whether a slope is traversable.

The landscape spans four metres plus its surrounding case and coordinate frame. It is a model viewed from the room perimeter. The recovered map grows from 13×11 to 13×13 by inserting two floor rows immediately inside the entrance. Every old row remains, with the central five-by-five opening, raised east strip, artifacts and utilities shifted together below the insertion. The dark orb is at (8,10); its independent animation is unchanged. Hall controls reserve a clear area against automatically dealt sculpture plinths.

## Verification

Evidence: `doc/space/torus-review-2026-09-13/`. An isolated rendered Godot museum run checks all authored works, CPU/GPU field agreement, local clock hold, signed remapping, amplitude/frequency separation, terrain restoration, triangle collision equality, desktop pointer controls and museum route continuity. The saved necklace hand remains unchanged. Desktop rendering does not establish Quest performance, physical hand reach or headset comfort.

## Standing comparison, 25 September 2026

Pair-mode holders now turn both rings and their child coordinate markers by +90 degrees around local X. Their centres are 1.40 m high. The unchanged 0.46 m outer radius gives an undisplaced vertical span of 0.94–1.86 m. Each small display mount reaches from the bench top at 0.78 m into the lower tube. The rings still have no collider.

The shader, CPU field functions, sample positions, amplitude/frequency choices and clock are unchanged. Local XZ is still the sampling plane; the holder transform changes its orientation in the room. Equal local XZ positions now lie toward/away from the viewer on the upright tube, rather than above/below a flat tube. No extra field dimension has been introduced.

The two new approach rows move the instrument beyond the entrance piers and reserve a standing view of both recipients. Native evidence, before/after views at a declared held t=2 seconds, scope and limits: `doc/book/iterations/2026-09-25-noise-one-standing/`.
