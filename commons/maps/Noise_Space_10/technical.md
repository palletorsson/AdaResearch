# Noise Space 10 — sampled ground and a moving body

This chapter follows the enclosing Noise_Inside_Noise sphere and the Cellular Noise / Box Noise comparisons, and prepares Noise_Perlin_Simplex. The existing NoiseSpace extends TopologySpace, creates a height mesh and supplies a trimesh collider. Its previous hall placement intersected the museum floor, hiding negative heights. The optional stand:walk configuration stages a complete patch above that floor and makes one controlled alteration available.

## Fixed field and height mapping

The declared generator is FastNoiseLite TYPE_SIMPLEX_SMOOTH (OpenSimplex2S), seed 0, frequency .1, FRACTAL_FBM, four octaves, gain .5 and lacunarity 2. The native generator performs its fractal accumulation. Input x/z coordinates are multiplied by noise_scale=5. These settings match the measured legacy generator; the new patch's extent, vertical reference, amplitude and edge envelope are explicit staging changes.

The patch spans [-4,4]² with resolution 80: 6,561 vertices and 12,800 triangles at .1 m spacing. At a vertex, y = 1 + amplitude × smoothstep(0,.75,min(4−abs(x),4−abs(z))) × noise(x×5,z×5). Amplitude choices are 0/.25/.65/.90. The boundary returns to y=1 exactly and matches the .8 m-wide margin. This envelope modifies the sampled field near the perimeter; the border is not an unaltered noise realization.

The mesh and collision are regenerated from the same vertex/triangle arrays on a deliberate height change. The generator remains unchanged. No per-frame terrain generation or noise clock runs. Legacy stand:none keeps the original 10 m scene, 100 resolution and original material path. TopologySpace.gd and the scene resource are unchanged.

## Route and witness

Route A joins (0,-4) to (0,4). B uses (0,-4), (-2.4,-2), (-2.4,2), (0,4). They are fixed proposals, not paths computed by a navigation algorithm. Each is sampled at 101 evenly spaced positions along its planar length. The surface length sums successive 3D segments; maximum grade is the largest absolute atan2(height difference,horizontal distance) over those segments. It is not the maximum face slope of the entire terrain or an accessibility certificate.

The profile's horizontal axis is normalized planar distance. Its vertical axis is (height−1) × .55 in the physical panel. Five witnesses select indices 0,25,50,75,100 and show a matching marker in both places. Raw field value, edge weight, exact analytical query and triangle-interpolated height remain separate in the evidence.

walk_height_at follows the actual two-triangle subdivision of each cell. In the lower triangle it weights h00/h10/h01; in the upper it weights h11/h01/h10. This is local to the optional study. It does not use the inherited helper called get_height_at_world_position, whose current implementation returns a nearby vertex rather than the claimed bilinear interpolation. No shared helper is silently changed.

## The remembered walk

The optional WalkStudy now owns noise_walk_trace.gd. It queries the actual em_walker or player_body CharacterBody3D at .08 s intervals and records supported horizontal movement within the patch. The body's origin must be within .45 m of the local mesh height. New samples require .06 m horizontal movement. There is no synthetic path or time-driven example.

The record contains at most 384 positions. Older positions are dropped when full. Unsupported movement leaves a break, and jumps between recorded positions greater than .75 m are not connected. A new entry starts a new attempt; leaving retains the drawing. Successful HEIGHT and RESET changes clear it. The existing occupancy refusal returns before either terrain or trace changes. ROUTE and SAMPLE preserve the record.

The 4.4 cm-wide pink ribbon has no collision and is raised .035 m above triangle-interpolated terrain heights. Each recorded segment is subdivided into drawing spans no longer than .04 m so its triangles follow the ground between observations. Those extra drawing vertices are not extra measured body positions. The recorder adds no node or logic to legacy stand:none. The held trail is local session memory, not a saved route or a pathfinding result.

## Place, colour and controls

The patch occupies (6,6) in the map. Frame bars extend to a 9.6 m outer square, top y=1, around the 8 m terrain. The east instrument is supported, cased and tilted, with four native pointer buttons. HEIGHT cycles amplitude; ROUTE selects a proposal; SAMPLE moves a witness; RESET restores .25/A/sample1. ROUTE and SAMPLE preserve the mesh and collision. HEIGHT/RESET decline to regenerate while a player_body or em_walker origin lies within the patch bounds and vertical band; the readout asks them to return to the margin. This is a local occupancy guard, not a global player teleport or pause.

The shared height-colour shader uses a fixed .1–1.9 m range, green-to-gold palette and .1 m contour interval. The appearance does not determine the collider. Shading and finite display resolution can hide a slope that remains present in the triangles. The original dark orb rests on the east platform and retains its independent pulse.

Every original structure cell remains. Ramps are added at (1,1), default orientation, and (10,11), rotated 180 degrees. Museum-only floor at (10,12) supports the preserved teleporter. The declared museum row is restored after Noise_Inside_Noise. Original sp and annotation tokens remain, and the two existing artifact tokens are retained.

## What was tested

Rendered museum evidence lives in doc/space/space-review-2026-09-13. Checks compare every vertex with the mapping, exact mesh/collider face arrays, and vertical physics rays at points between vertices. Physics readback waits for server updates after assigning a replacement shape. The real desktop pointer operates all four controls. Both the DesktopPlayer and museum Walker prevent rebuilding beneath them. The desktop body walks the lower-amplitude route, tests the stronger terrain, and crosses both access ramps. The height-aware museum route remains connected.

The tested DesktopPlayer capsule is .3 m in radius and 1.8 m tall, with floor_max_angle 45 degrees. At .25 it crosses route A; at .90 the recorded identical forward input stops partway. This is one traversal experiment, not a proof that the stronger terrain has no traversable paths. Headset behaviour, comfort and Quest frame rate remain unverified.

## Representation limit

A heightfield assigns one y to each horizontal coordinate. It cannot encode a cave roof and floor there without additional surfaces or another representation. The parameter name Noise_Space_10 is a historical map identifier; this encounter exposes one height parameter rather than claiming a universal smooth ten-dimensional parameter space. Different seeds do not guarantee identical finite-sample histograms, and discrete octave/basis choices are not continuous axes.

## Reversible miniature visit — 25 September 2026

`noise_scale_portals.gd` belongs only to stand:walk. Feet entering the full frame trigger a factor of .125; feet entering the small frame restore the captured state. Detection is local-space and recognises museum CharacterBody3D and XRToolsPlayerBody. A cooldown and clear landing prevent immediate retrigger. Leaving the patch or destroying the study also releases scaling. HEIGHT/RESET refuse throughout an active miniature visit, including the transition.

Desktop capsule dimensions and offset change directly, keeping body transform scale at one. Camera and nonphysical visual children receive a temporary scaled parent; near clip, floor snap and safe margin follow the body. EmFeel instance speeds, acceleration and stride lengths are captured and scaled. A default-one body metadata factor also adjusts museum fallback speed, jumping and gravity. On exit, original resources, parents and properties are restored, not reset to assumed defaults.

XR uses XRServer.world_scale rather than scaling the rig node. XRTools already scales its capsule, tracked hands, direct movement and jumping. A temporary movement provider scales gravity; it is removed on exit. After three physics frames for tracked poses to update, body.teleport places the visitor on the sampled terrain. The previous world scale, camera near plane and enabled state are restored. A rig without a camera/origin is refused before any mutation.

The mesh and collider do not regenerate for scale changes. Pink trace spacing, width, offset and segment threshold follow body scale; its existing 384-position cap remains. The small return frame refreshes its mesh-relative height only after an accepted terrain change. Native desktop and synthetic XR evidence is in doc/book/iterations/2026-09-25-noise-small-world; tracked headset comfort and tracking transitions still need a headset session.
