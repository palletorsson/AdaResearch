# Void / left-stick staccato

User clarified the problem is LEFT controller movement, not grabbing or the
right-hand snap turn. Wants the same controller tested in a room with artifacts.

Added motion_room.tscn/gd, inheriting game.gd and calling its _build_player
unchanged. Actual Point Coordinates point and line_black_box artifacts; one flat
20x22m floor and a clear marked lane. F5 menu → Movement test beside The Void.
Left Y routes through staging to The Void with the same telemetry. Right B
resets room; A jumps; X menu. Desktop R/T/M. MainMenu3D has one additional button.

No movement tuning, rest offsets, global deadzones, hand poses or floor layout
changed. The base has JoystickDeadzoneFix history for worn controllers (0.5 y /
0.3 x fallback), but the Void does not mount that writer. The inspected PC
settings were x=0.2, y=0.1. StartXR already matches physics to headset refresh,
or uses 144 Hz if the runtime supplies none. Neither is proof of this symptom.

motion_meter.gd is opt-in (always in room, tower only after Y or
--void-motion-test). Shows input/speed/frame timing. Saves bounded one-second
summaries with raw per-physics-tick min/max, frame p95/max, rates, stalls and
tower loading state to user://void-motion-{room,tower}.json. Automated tests
set its output directory to doc/book/iterations/2026-10-18-void-movement-room.

tools/test_void_motion.py --capture --menu: native full project, synthetic XR
trackers, samples actual displacement AFTER every physics tick. Do not sample
positions once per rendered frame and multiply by physics Hz: at 60 rendered /
90 physics that falsely appears to alternate between one and two movement steps.
36 checks / 12 movement trials: stable full, slow, diagonal, neutral and held
point motion at 60/90 Hz, release stop, pickup/drop, jump/landing, exact rig
signature and telemetry. Room/tower full speed 3.5m/s, raw0.3 gives0.778m/s.
This has NOT reproduced the physical controller symptom. PC window renders
about60fps; cannot use this as a Quest/PCVR performance result.

Menu/staging fixture: five checks passed for actual menu button signal, scene
readiness, room-to-tower route and cleanup. Headless baseline and room route
both emit the same 11 existing null-material cleanup messages; no new script
errors. The rendered 36-check movement run has no engine/script errors.

Next evidence is actual headset use of the room, then Y tower, then leave so
records save. If raw input is unstable while thumb is steady: calibration/hardware
path. If raw/motion steady but image hitches: rendering/runtime. If room smooth
but tower hitches: content/loading path. Keep right snap-turn unchanged.

## Follow-up: player body / invisible menu / mushrooms

User suspects these colliders. Added tools/probes/void_staging_collision_probe.gd
and tools/test_void_collisions.py to exercise REAL vr_staging.tscn, room, tower,
then menu return. force_xr is set on Scene.child_entered_tree before scene ready;
synthetic trackers only, --desktop suppresses actual XR startup.

25 functional checks / eight movement trials passed. Menu panel's collision
shapes disable on ancestor visibility; buttons layer21 is excluded by player's
mask1023. One capsule per loaded scene; no avatar solid on player mask. Actual
MushroomHand._build_vr_hand creates no CollisionObject3Ds. There is no evidence
these cause the staccato. Specific artifact/floor/beam contacts remain untested.

motion_meter.gd now records existing slide collisions (up to32 paths per1s,
300 summaries), normal/layer/visibility/body position. Contact HUD retains a
non-floor hit for2.5s and appends (hidden). No physics behavior changes, new
queries, global deadzones, or layout changes. A temporary invisible wall in the
probe verifies detection and saved evidence. It never exists in shipped scenes.

Full staging test is NOT a clean exit: all assertions run/pass, then shutdown
emits44 null-material errors,61 resource leaks and Windows0xC0000005. Native
menu-only baseline (--menu-baseline) reproduces exactly this without any Void
scene or MotionMeter. Kept runner strict (fails), logs/JSON in report folder.
Separate python tools/test_void_motion.py --capture passes36checks/12trials
with no engine/script errors after telemetry change. Do not tune locomotion
on this evidence alone. Read actual headset samples next. Existing user://
samples timestamp18:32 withheadsetHz0 match earlier synthetic tests, NOT a
physical headset session. New runs save under report directory.

## Follow-up: restore right-stick forward/backward

User explicitly requested the earlier right Y walking in both Void and room,
while retaining left movement and right turn. base.tscn has two Direct providers:
left strafe=true, right strafe=false. Void's builder had omitted the right one.
Added RightHand/Move using the existing XRTools script, speed=3.5, strafe=false.
The shared builder now assigns [turn, move, right_move, jump] to its own body.
Room inherits this exact builder. No turn, left-stick, filter or layout tuning.
Updated provider-count expectations in void_avatar_probe and void_game_probe;
those broader suites were not rerun for this change.

motion_meter now shows/records both raw and adjusted sticks, each tick's ranges,
live X/Y deadzones, rest offsets and snap threshold. Combined movement demand
also drives the existing stall/contact diagnostic. Normal tower has no meter
unless requested. Room and console instructions reflect the restored mapping.

Native Mobile test: python tools/test_void_motion.py --capture PASSED 108 checks
across 29 movement trials, exit 0, no engine/script errors. Actual full project,
synthetic XR, room + tower at 60/90 physics Hz. Both forward/backward direction,
gentle walking, release, unchanged left strafe, right 30-degree turn while
walking, non-repeating held turn, carry/drop, reset, jump and landing. Both sticks
full forward cap at 3.5 m/s; opposing inputs cancel. Test waits for settled floor
contact after reset before pressing A (XRTools rejects landing velocity >0.01).
Jump signal counted: one press, one jump, no repeat while held through landing.
Snap test measures the eye position, not capsule position: the capsule correctly
shifts under the eye when turning. These fixes correct test preconditions/oracles;
they do not change production jump or turning code.

Filters confirmed in that run: shared deadzone X=.20/Y=.10, no rest offsets;
right raw X turn threshold .25. PlayerBody ignores requested speed below .1m/s
and uses traction=30 / drag=5, with possible surface overrides. Older base helpers
VelocityDeadzone (.15m/s cutoff) and JoystickDeadzoneFix (fallback X=.3/Y=.5,
optional calibration) are NOT mounted here. Their shared settings/offsets can
remain after switching from another base scene in the same app session. No reset
or tuning performed. HUD shows actual session values. Physical controller feel
and headset performance still unverified; do not call the staccato fixed. Prior
menu-only shutdown failure remains separate, documented above and in report.
