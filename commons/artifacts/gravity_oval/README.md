# Gravity oval

Forces → The room gives a direction (`Vectors_Act3_FieldsAndMotion`). A new bay after the existing vortex comparisons; all earlier placements and the eleven-hall sequence remain.

24 bodies reuse the black PointBody and the museum's crate, chair and extinguisher prefab geometry. A standing oval is 5.6 m wide, from 1.2 m to 10.2 m above the floor. The left column rises, the top turns right, the right column descends and the bottom returns left. Step into the rose-marked side to join it. Walk sideways out of the stream. Props can be picked up and taken out; outside, ordinary gravity returns. RESET restores props and refuses while one is held.

The field integrates acceleration, not a path animation. It relaxes velocity toward a tangent at 3.2 m/s and applies a restoring acceleration toward the oval section. Jolt contacts can disturb the result. Native cargo receives mass × acceleration; the player receives the same acceleration through the existing desktop/XR movement owner, with walking input added. Velocity, collision and time steps still matter. No rotation is applied to the tracked head or XR origin basis.

This is an artificial, driven force field: it supplies energy and is not an inverse-square gravity model. The visual arrows show the intended flow, not measured instantaneous acceleration. Engine gravity is disabled for these props while free inside the stream, restored outside/while held. The player receiver samples 0.7 m above its feet. Only this artifact's prefab cast and the player are field receivers; unrelated museum furniture is not captured automatically. Flow is bounded to the bay. The shared extreme out-of-bounds recovery remains available; tests require zero recoveries during normal circuits.

The floor is a shallow 5 cm surface with no enclosing cage. A clear 2+ m museum perimeter route bypasses the installation. Rose/cyan floor marks are visual. Finite bodies and bounded trails; no per-frame spawning. Reset changes the prop experiment, not the player's location. Museum teleport remains available for navigation.

Tutorial relation: a comparison beside the primary PointBody vortex. Reuse the distinction between a field sample, acceleration, accumulated velocity and position. A continuous loop needs energy supplied; it does not demonstrate free energy or real antigravity. Full tutorial.md is unchanged.

Verification: `tools/probes/gravity_oval.gd` tests Jolt circuits, actual XRTools player movement, upright tracked pose, leaving by movement input, pickup, ordinary gravity outside, and held-safe reset. `gravity_oval_museum.gd` checks production placement, route clearance, actual museum player circuits and captures. Headset comfort and Quest frame time require a physical VR visit.
