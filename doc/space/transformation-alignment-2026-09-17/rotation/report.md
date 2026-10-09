# Rotation alignment — 17 September 2026

`final.md` is 1,081 word tokens including code, reduced from 1,659 (34.8%). The prior text is in `before/final.md`; `verification.json` records the count, anchors, final hash and inspected source hashes.

The four primary encounters remain in order: `rotation_wall_crossings`, `rotation_array_compare`, `boolean_tunnel`, `carousel_cake`. Five code blocks remain. The edit removes repeated explanations of axes, dimensions and passage, and the radius/rim-speed tangent at the exit. It retains the distinction between climbing a stationary blade and riding an upright endpoint deck, X's forward route and Z's sideways route, the unexpected wider-body result, the tunnel's separate subtraction/rotation operations, and all five carousel profiles.

The closing question now concerns the relation between body and surrounding dimensions. The map exit label is **WHAT FITS THIS BODY?** and the corresponding learning objective follows that relation into Scale. These were the only map edits made by this agent; the root agent owns the separate spawn correction. The tutorial's concluding bridge and the critical paragraph describing the two body trials were aligned. No runtime sources were edited during this pass.

## Runtime dependencies to include when versioning

The following two scripts exist locally but are untracked at this review:

- `commons/artifacts/rotation_studies/array_body_comparison.gd` — required by the tracked, modified `array_compare.gd` preload. Provides the visible narrow/wide trials, endpoint markers, readouts and replay.
- `commons/artifacts/rotation_studies/rotation_rider_deck.gd` — required by the tracked, modified `wall_crossings.gd` preload. Provides actual foot support, incremental XR/desktop carry and release.

Include both helper scripts with their respective parent-script changes. They are instantiated with `.new()`, so they need no separate scene or artifact registry entry. Existing tracked `array_compare.tscn`, `wall_crossings.tscn`, `parts.gd`, `commons/interactables/push_button.tscn`, and `commons/artifacts/registry/rotation_studies.json` already provide the scene/registry chain.

Both local UID companions exist:

- `array_body_comparison.gd.uid`: `uid://b3v7b00dovekr`
- `rotation_rider_deck.gd.uid`: `uid://cndg4fe4ng06l`

`.gitignore:330` ignores all `*.uid`. These preloads and scene script references use explicit `res://` paths, so they do not require those UID files to resolve. This pass does not change the repository's UID policy or force-add ignored files.

For the complete compact map, retain the existing numeric-configuration whitelist change in `commons/grid/GridInteractablesComponent.gd` for `band_spacing`, `row_angle_step`, `num_segments`, `rotation_per_segment`, `segment_vertical_offset`, and `plinth`. Without it, the authored configuration values can be interpreted as tutorial shorthand. No additional parser changes are needed here.

Focused tests also remain untracked: `commons/testing/probe_rotation_rides.gd`, `commons/testing/probe_rotation_compact.gd`, and `ada_run/probe_rotation_body_comparison.gd`. They can accompany the corresponding implementations; they are not runtime scene dependencies. No commit or index mutation was performed by this agent.

## Verification and limits

Checked the prose against the current six source scripts for the wall, ride deck, arrays, body comparison, tunnel and carousels. Preserved all primary anchors in order, checked balanced fences and absence of unfinished markers, and validated the revised length. Map JSON parses and the scoped text diff has no whitespace errors.

Existing runtime evidence is retained: 53 actual-museum XR ride checks, 1,638 clear standing-capsule placements, 40 body-comparison checks, and actual-museum images from 16 September. Those tests were not rerun for this editorial change. The root agent is validating the separate map/spawn changes. None of this marks the chapter as learner-verified or establishes headset comfort.
