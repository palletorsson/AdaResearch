# Leaning Together / brittle posture

The user asked for gravity and a precarious arrangement that holds untouched and falls apart when disturbed. Floor 46 retains all eight other installations, the same work-area position/facing/scale, and all other floor arrangements. The selected config explicitly sets `brittle: true`; any authored member overrides are preserved.

## What changed

- The same 1.25 × 0.07 × 0.26 m planks stand on their 70 mm edges. Both chocks bear near their edges with a nominal 8 mm depth overlap.
- The outlined cube rests above the plank ends, slightly offset toward the approach. The ball remains a loose probe weight in the board tray. It is not a hidden collapse trigger.
- All six parts run native gravity. The frame uses lower contact friction (0.15 for planks/cube); the board remains 0.22 and wooden chocks 0.85. No joints, snap locks, balancing corrections, timer or touch-to-collapse flag.
- A desktop click or VR pointer trigger applies one finite impulse at the actual surface hit: mass × 0.25 m/s along the pointer ray. It is a digital nudge, not a fall animation. Natural XR collision-hand contact can also disturb the frame with the grip released.
- A low physical lip retains the loose ball and fallen parts nearby. The ball has native damping and may sleep once at rest; it is never frozen during play. Reset releases held parts, restores authored poses, zeroes their velocities and returns them to gravity.

## Evidence and limits

39 native checks passed: 30 seconds untouched at three rotations and negative elevation, all six gravity bodies, ball retained by real geometry, actual ray-surface taps on both planks, cube and both chocks, hover without a tap, fall and reset. The taps dismantled the tested initial arrangement; this is not a claim that every infinitesimal contact or force direction must cause a collapse.

54 actual main-floor input checks passed: desktop mouse and synthetic XR trigger taps on plank/cube/chock, a physical ungripped synthetic XR collision-hand nudge, ball pickup and held reset. The physical hand case generates no pointer-tap signal. Physical headset testing remains.

10 authoring members / 36 native meshes. Production editor move/rotate/copy/save validation and desktop/VR mirror parity passed without saving test edits. The whole work area and each of its ten members remain editable. Arbitrary authoring edits may remove the precarious starting contacts.

The editor preview deliberately resets/freezes only its export copy. Gravity runs in Godot desktop/VR, not in the static Three.js lab-editor layout preview. Runtime hand arrangements are temporary; save starting arrangements in the editor. Native grabbed bodies follow kinematic hands, without biological compliance or haptic force.

Photographs show the real registered floor after 15 untouched seconds, during a probe-pointer tap and after collapse. Those inspection cameras hide neighbouring storeys. Separate before/after images come from the actual desktop-input test. Source fingerprints and all six receipts are alongside this review. Earlier braced-posture receipts remain historical.

Gallery: http://localhost:3003/book-review/doc/book/iterations/2026-10-25-leaning-brittle/index.html
Editor: http://localhost:3003/lab-editor?mode=void&floor=46
