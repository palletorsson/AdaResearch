# Boids: who enters the radius?

A presentation and input adapter around the existing `flocking_controls` scene in the Endless Museum's Boids hall. The same PointBody class used by earlier swarm encounters controls the original perception radius.

## Encounter

Pick up the black point on the left. Move it left to narrow the radius or right to widen it; the range remains the original 0.05–0.5 metres. The value is relative to the hand position at pickup, so picking it up again does not jump the radius. Trigger while holding, or press the nearby right button, to pause/play. Dropping the point returns it after 1.5 seconds and retains the radius and playback state.

Three gold circles show the spherical neighbourhood of body zero. Gold links join it to the neighbours the original calculation includes. The counter excludes the selected body itself and positions within 0.001 metres, matching the source. Pausing preserves all thirty positions and velocities while you vary the radius or the original five sliders. The original reset produces a new random scatter, not a replay.

Red, blue and green arrows show the next separation, alignment and cohesion requests for body zero; white is their sum. Numbers give their full magnitudes. Arrow length is compressed by `0.32 * magnitude / (1 + magnitude)` to fit the table. These are weighted steering requests before the original integration and speed limits, not forces labelled in newtons or a prediction of the next velocity direction.

## Model and observer

The adapter instances the original scene unchanged and schedules its existing `_process(delta)` only while playing. Its thirty bodies, bounds, weights, sequential updates, wrapping, speed cap and minimum speed remain the original implementation. The original cached force arrows are hidden because they describe the preceding update. A read-only calculation previews the first body's next requests from the currently displayed positions and velocities. Tests compare this preview with the original body's next cached requests.

This optional museum exhibit is distinct from the small snapshot/fixed-step example in the canonical tutorial. It does not replace that lesson or turn the player into a flock neighbour. The existing open flock, fish school, aquarium and drone comparison are separate models and remain in the hall.

## Validation

`tools/probes/boids_lens_checks.gd` checks the production scene, original-model equivalence over 300 variable time steps, neighbour selection, vectors, pause, render-backed links, original sliders, and supplied desktop and XR near-grab inputs. Use a real rendering backend: Godot's dummy headless renderer does not return the MultiMesh transforms needed by the link assertions.

`tools/probes/boids_lens_museum.gd` checks the installed exhibit, five sampled routes for floor and standing-capsule clearance, the displayed radius/links/arrows and a paused hand-controlled comparison. `tools/probes/boids_lens_portals.gd` supplies actual portal-coordinator requests for Boids → Agent-Based Modelling → Boids. These tests do not certify physical headset interaction or Quest performance.

Publish the evidence with `python -X utf8 tools/publish_boids_lens.py`. The publisher also checks the exact intended map/plan differences and hashes of 47 preserved source/text files. Its baseline is this iteration; later authorised hall changes may invalidate those assertions.
