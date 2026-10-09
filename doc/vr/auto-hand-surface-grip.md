# Surface grips in Ada

Ada adapts the useful contact-solving part of Unity AutoHand to the existing
Godot XR Tools hands. This is a surface-pose fallback, not a port of the whole
AutoHand physics, input, joint, or locomotion package.

## Why the hand grabbed air

XR Tools accepts nearby pickups within a 0.3 m search sphere. A free grab retains
the object-to-controller offset, including the gap present at pickup. Its default
hand animation closes identically around every object. Only an authored hand
grab point previously supplied a matching hand transform and finger pose.

The left museum hand also lacked its exported blend tree and default pose,
preventing the pose-override API from affecting that hand. `commons/scenes/base.tscn`
now supplies those resources on both sides.

## What the fallback does

1. Wait until a near pickup or distance pickup has arrived.
2. Copy the held object's enabled physics shapes into an isolated physics space.
   Areas, other scenery, and the object's changing pickup collision mask cannot
   become accidental finger contacts.
3. Find a real collider surface within the permitted palm adjustment distance.
   Search bounds help aim rays; a bounding-box face is never used as a contact.
4. Calibrate the palm against the actual skinned hand mesh: the bundled palm
   markers sit about 22 mm outside the visible central palm. Align this surface
   to contact using the shortest rotation. Left and right have different normals.
5. Extend any initially intersecting fingers within a bounded range, then close
   each finger separately against those colliders and install the resulting
   pose and object-relative visual hand target at priority 90.
6. Retain that fit while held; remove it on release, grab-point change, or object
   removal. Authored hand poses use priority 100 and retain precedence. Generic
   authored grab points also bypass automatic fitting.

The solver does not move the physical controller, change object collision layers,
or replace the existing object driver and throwing code. Each hand owns its own
fit, including two-hand holds. Finger queries run once at pickup, not every frame.

## Controls and limits

`XRToolsHand.surface_grip_enabled` enables the fallback. Set it to false to compare
against the old free-grab behavior. `surface_grip_max_distance` bounds the visible
palm adjustment (default 0.35 m, multiplied by XR world scale).

The object needs enabled collision shapes matching its visible surface. A poorly
fitted collider still yields a poorly fitted visual grip. Objects without usable
colliders or without a contact within reach retain the normal XR Tools behavior.
The pose starts from the rig's existing finger animations. Its relaxed open pose
is already partly curled, so affected fingers may first extend at their roots
(up to 60 degrees) to get clear. A fit that still starts inside geometry is
rejected. These are posed fingers, not physically simulated finger joints.
Small sphere samples approximate their volume; very thin or complex colliders
still need inspection. Geometry or scale changed during a hold needs a new grab.

The modified addon scripts are a small overlay on installed XR Tools 4.5.1.
They and the upstream MIT license are explicitly included by `.gitignore`;
installing a replacement addon must preserve or reapply this overlay.

## Source correspondence

The local Unity reference is `Assets/AutoHand/Scripts` in
`Unity_Work/sirens_final-working-sw-current`:

- `HandBase.HandClosestHit`: choose actual collider contact.
- `Hand.AutoPose`: place a dedicated palm surface marker at that contact.
- `Finger.BendFingerUntilHit`: independently stop each finger's closing motion.
- `Hand.GrabObject`: authored poses first; retain the result relative to the object.

Godot implementation:

- `addons/godot-xr-tools/hands/surface_grip.gd`: collision snapshot, surface fitting,
  override ownership and cleanup.
- `addons/godot-xr-tools/hands/surface_grip_pose.gd`: rig calibration and finger pose.
- `addons/godot-xr-tools/objects/grab_points/grab.gd`: pickup/release integration.
- `tests/test_surface_grip.gd`: synthetic controller and real rig/collider checks.

## Verification

Run `python tools/run_surface_grip_probe.py` (set `GODOT_EXE` if necessary).
The 2026-10-05 run passed 166 checks, with a clean engine exit: both museum hands,
box/sphere/capsule/rotated compound colliders, object and XR world scale, finger
clearance, rendered skeleton pose, object movement, release and deletion,
two-hand ownership, authored/generic/free grip transitions, and the real ranged
pickup LERP/drop lifecycle. Reports are generated under
`ada_run/auto-hand-2026-10-05/`. A desktop render was also inspected. The existing
audio-bus UID warning is independent of these tests.

Headset review remains necessary: approach the same cube from its sides and top,
try a sphere and a handled tool, release/regrab, then hold with both hands and
release one. Check palm placement, finger penetration, tracking comfort, and that
the remaining hand keeps its grip. Automated checks cannot establish that feel.
