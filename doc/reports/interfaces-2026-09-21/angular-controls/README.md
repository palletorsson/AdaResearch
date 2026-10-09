# Place / keep moving

21 September 2026. This pass repairs the shared smooth wheel and lever and adds a focused InteractableDemo encounter: one control sets angle, the other commands angular velocity. It continues the physical XY pad work without conflating position, velocity and force.

## Implemented

- `wheel_smooth.tscn` retains its UID, scene path, native hinge child path and ±360-degree limits. Its backing is now 18 × 25 cm; the wheel is 12 cm across. The old 40 cm frame collider is replaced by a matching rectangular collider, the wheel body has a real shape, and four visible grips coincide with their grab targets. A single moving index and stationary ticks make orientation visible.
- `lever_smooth.tscn` retains its path, child hierarchy and ±45-degree range. It uses the same backing, flat caption and value surface, with a visible travel strip. Two invalid hand-pose redirects were removed. Smooth lever and wheel both retain their setting on release, as before. Native fallback grabbing is used; this is not a custom hand-pose validation.
- `angular_driver.gd` resolves a grab in the stationary parent frame, unwraps the wheel around its current turn count, averages multiple held grips and preserves their world positions while the hinge moves. Native degree signals, radian movement, limits, detents and configured release behavior remain available.
- `physical_angular_control.gd` supplies pointer ownership, local angular dragging, cancellation and flat readouts. Wheel centre dragging is ignored because its direction is undefined. A mapped reading can express the receiver's unit. Pickup layer restoration now preserves the pointer layers; otherwise a grip stopped accepting rays after a physical grab.
- The reference groups unscaled controls at 28 cm centres on an inclined, supported station in front of two visible rotors. Its wheel uses ±180 degrees and retains its position. Its lever explicitly opts into zero return and maps ±45 degrees to ±90 degrees/second. Releasing it stops movement while preserving the receiver's accumulated pose. This is a velocity command, with no force or inertia model.
- InteractableDemo adds an opt-in `angular_reference` and `interactable_angular_demo.tscn`. This is a focused reference scene without its own player/camera. Default sampler behavior is retained. Sampler/audio footprint metadata and the component gallery's lever spacing account for the enlarged plate.

## Verification

**100 checks pass** in desktop Godot 4.6 Mobile, with real XR Tools pickup/release and real ray-hit pointer dispatch. Checks include tilted controls at yaw 0/90, stationary-hand stability, original release behavior and limits, optional detents, seam crossing, regrabbing beyond 180 degrees, two simultaneous wheel grips, pointer ownership/loss/focus cancellation, and post-grab ray dispatch from both wheel face and grip.

The reference is loaded through its actual InteractableDemo scene. Tests verify flat surface text, compact front placement, matching wheel/receiver direction, degrees-versus-degrees/second readings, timed accumulation, reverse velocity and both hand/pointer release. At zero speed the receiver stops processing. The hand proxies are synthetic test drivers using the real pickup API, not tracked headset hands.

Before/after component captures use identical cameras. `before/` contains the pre-edit source snapshots and six baseline failures. The new reference has no historical before equivalent. Its operating camera is at 1.60 m, z = 1.22 m; the console centre is 0.99 m high, z = 0.50 m, tilted 40 degrees. These measurements describe the fixture, not a certified reach envelope. Held/released captures are state comparisons; the fixture freezes the speed receiver for the held capture after explicitly testing timed integration.

The final run has no SCRIPT ERROR. An existing unresolved project UID (`uid://rwex60pqapc`) remains in the log. The autoload HUD and environmental tint are visible in the captures.

## Integration boundary and next pass

The repairs take effect wherever the two shared smooth scenes are instantiated. Their larger footprint is deliberate, so authored placements need review. No museum maps, manuscripts or artifact primacy were changed in this pass.

The existing `SoundscapeRadioRack` is the next useful consumer. Its current source shrinks its two wheels to 0.6 and 0.5 scale, still uses Label3D, maps only the positive volume half-turn, and can change station without resynchronizing the physical wheel. Preserve its `scale`, `presets`, `list` and intentionally information-poor `void` faces when integrating. It has been inspected and its source snapshotted, but not repaired or runtime-certified here. Audio listening and signal correctness remain untested.

The separate `lever_snap.tscn` and `lever_zero.tscn` are old duplicated scenes, not subclasses of the repaired smooth scene. Their full migration remains open. The zero scene currently declares default_position = 0.5 degrees with default_on_release disabled; do not claim it is spring-returning. The reference configures its release rule explicitly. UniversalVRAudioController's legacy wheel/lever rotation assumptions and decorative replacement faces also need an assembled-consumer pass.

Headset hand comfort, shorter/seated positions, Quest legibility/performance and museum placement remain pending. The fixture's stand and receiver supports are visual meshes, not locomotion colliders.

## Reproduce

```powershell
python doc/reports/interfaces-2026-09-21/angular-controls/run.py after
python doc/reports/interfaces-2026-09-21/angular-controls/publish_review.py
```

Baseline evidence is archived. Reproduce it in a separate checkout using the preserved sources; the harness refuses to overwrite it with current components. Captured source hashes accompany the published review.
