# Hand tools and attachments

7 October 2026. The existing force_play encounters use actual Jolt bodies and joints.

`play_space.keep_attached()` marks both rigid ends of every hinge/pin, disables XRTools direct pickup, and the desktop pointer refuses that marker. Bodies remain collidable and dynamic. Separate rose grips use constraint_grip.gd to apply a capped spring force. The seven spring points also use those grips. Moving a grip does not reparent or freeze its target.

`push_stick.gd` makes a 2.2 m cylinder with a full-length capsule, a rose handle and pale tip. It is a kinematic collider while held, so it transfers contact impulses; this is not a measured hand-strength model. It excludes player collision layers while touching world and artifact bodies. XRTools grips and desktop carry are supported. Drop restores dynamics. Each spring, swing, torque, constraint and friction station has a local rack and a RETURN STICK button, which refuses to take a held tool. The stick is a local encounter tool, not a new persistent inventory weapon.

Four matching low basins now receive the friction ramps. Their dark base and pale rim distinguish incline, runoff and retained objects. The contact coefficients and slope remain unchanged.

The existing full BecomingCatalyst is offered near the entrances of Motion, Oscillation and Arena by force_halls/hall_display.gd. It starts in Forces mode, with no lease and without clearing earlier abilities. Its actual effect is slowing and temporary damping. Forces projectiles now collide with the museum pickup layer and include that layer in the effect query. Repeated shots refresh one timed effect, rather than stacking stale damping restorations. Held/frozen bodies are excluded. Experiment RESET restores the body's original damping.

Tests: tools/probes/forces_hand_tools.gd; force_play_models.gd for friction/springs/swings/torque/constraints; forces_hands_museum.gd for real hall placement, captures, clear routes and the configured catalyst. Supplied XR controller movement tests engine behavior; physical headset reach, feel and Quest frame time remain unverified.
