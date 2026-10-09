# Noise Space 10 — which way will carry you?

Reviewed on 13 September 2026. Next hall: Noise_Perlin_Simplex. Current illustrated review: `/research/possible-bodies/noise-space-ten.html`.

## Retain the work and give the comparison a place

The baseline run (PID 35856) captured both original works before editing. Negative terrain heights disappeared under the museum floor and the raised grid geometry cut into the terrain. The map's declared depth is 14 although its structure contains 15 rows; this existing mismatch is retained and the actual rows are used. Every original structure cell remains byte-for-value. The noise_space token now selects the optional stand:walk study at (6,6); dark_sphere remains on the raised east platform at (11,3). The scene, base TopologySpace code and orb script are unchanged. Original source, map, prose and plan snapshots are in before/; the original rendered run is in baseline/.

The study has an eight-metre square terrain, a .8 m surrounding margin at y=1, and an authored .75 m edge envelope. Two small pairs of posts mark the route ends. The grid gains wp at (1,1) and wp:180 at (10,11); original utilities remain. A museum-only floor cell supports the original teleporter approach. The original platforms, wall recovery and large raised block remain. The live museum had skipped this book hall; the accepted row is inserted after Noise_Inside_Noise.

## What changes and what stays put

OpenSimplex2S, seed zero, four fBM octaves, gain .5, lacunarity 2, frequency .1 and coordinate multiplier 5 stay fixed. HEIGHT selects 0, .25, .65 or .90. The same generated mesh supplies visible ground and collision. The optional study has 6,561 vertices (81 × 81 at .1 m spacing). Unconfigured placements still use the original ten-metre terrain with resolution 100.

ROUTE switches between two proposals without rebuilding ground. SAMPLE selects one of five witnesses shared by the ground and a cased section display. The profile has 101 points, evenly spaced in planar distance; the reported section length sums the 3D segments. Its steepest segment is a sampled section statistic, not the maximum slope of the complete mesh or a navigation certificate. Exact local triangle interpolation supplies the profile and sample heights. Analytically resampling between vertices can differ from the constructed collider. The pre-existing base helper is not altered.

HEIGHT and RESET wait while a player body is on the patch. Both the player_body group and the museum's em_walker group are checked. The original orb continues its own clock; controls do not broadcast across the museum.

## Recorded evidence

Accepted process: PID 23136, 2026-09-13T15:42:53+02:00 to 2026-09-13T15:43:20+02:00. Exit zero; 36 checks passed with no failures. Source hashes and the original saved necklace hand remained unchanged. The runner used an isolated hand snapshot, compatibility rendering, XR disabled and an owned hidden/offscreen process. Prelaunch Godot inventory was empty.

At each of four height scales all displayed vertices match the height rule, edge vertices remain at 1 m, and the raw noise values stay fixed. Collision faces exactly match the displayed mesh. Five fractional-grid vertical rays at each scale hit the terrain and agree with triangle-interpolated heights within .0001 m. Physics readback waits three physics frames after replacement; querying immediately had observed the previous server state. The tolerance was not widened to conceal that synchronization issue.

All four native pointer buttons change their intended local state. Both player groups prevent terrain replacement while occupied. ROUTE and SAMPLE leave the existing mesh and collider objects alone. A separate unconfigured NoiseSpace instance retains its original mesh through these operations.

The actual DesktopPlayer capsule (radius .3 m, height 1.8 m, floor limit 45 degrees) receives the same 120-frame forward input from the near margin. At .25 it reaches z=5.509 m, beyond the far edge. At .90 it stops near z=-.376 m, remaining supported. This is one recorded attempt at each setting, not proof that all paths are blocked or a direct headset traversal. Route A measures 8.133 m / 24.180 degrees at .25 and 9.450 m / 58.257 degrees at .90. Route B is longer and slightly steeper in this sampled section. No easier-route claim is made.

Both entry and exit ramps pass actual body walks, and the museum height-aware route check reports no severed path. The controls are reached from the stable margin. The final captures height_0..3 share one camera and route A; standing, instrument, orb and plan record the other views. The older terrain.png is a baseline image and is not published as a current view.

## Book and next questions

The two primary book anchors are noise_space and dark_sphere, in that order. The chapter oscillates between choosing a route, encountering a change, inspecting the short height and border rules, then discovering what a heightfield leaves out. The three code excerpts are exact source passages. Previous ten-slider/manifold claims are retained in the archive, with current technical, critical and tutorial files rewritten against the actual implementation. Existing historical field notes are explicitly dated as preceding this review.

The next hall, Noise_Perlin_Simplex, can change the generator while holding the question steady. Shelter and lines of sight need a future body/visibility comparison; this hall tests walking. Headset reach, comfort, text legibility and Quest performance remain deferred to the user's later headset session.

## Publication and browser check

The local encyclopedia serves all 57 declared publication files with HTTP 200 and SHA-256 matches. The browser exercises all four height states, route B and all five sample positions. Photographs are explicitly labelled as route A while the profile/plan follow the selected route. The book opens with three source excerpts and all five visible photographs load. The review has no horizontal overflow at the inspected 691 px viewport. The primary view shows noise_space and dark_sphere in encounter order, with both current book passages opened and verified. Its pre-existing narrow-layout overflow remains outside this hall change. The accepted run introduces no new diagnostics relative to the original baseline; the pre-existing UID/resource and compatibility-renderer warnings are retained in diagnostic-comparison.json.
