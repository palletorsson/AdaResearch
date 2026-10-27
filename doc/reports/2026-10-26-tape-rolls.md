# Point Lines / tape rolls

Added a tape supply to the saved main Point Lines floor, index 3, at x −8 / z 5.25. Existing placements and other floors were retained by a revision-guarded additive save; the Desktop mirror matches the shared desktop/VR layout. The first draft's tight route was corrected before publication. A native walking circuit around the final crate and both open shafts passed.

Three native XRTools pickable rolls share the same action: hold, fire at A, move the aim, fire at B. Masking is 5 cm, pink marking 7.5 cm and striped barrier 12 cm. Real collider-local endpoints follow moved, rotated and scaled targets. A preview, length budget, missed/blocked-shot refusals, cancellation on dropping, undo/refund and deliberate tidy/reset are implemented. Runtime strips remain session-local. Objects need solid colliders to receive tape.

All eleven station members export as real independently editable native geometry: 27 meshes and 12 embedded images. Generated tape patterns survive export. The shared catalogue, capacity tree and prefab workbench contain the station and three reusable rolls. Individual roll copies isolate their own member in both the production editor model and native scene; copy, move, rotate and validate-only save checks passed without retaining test edits.

Evidence:

- `ada_run/matter-reference/tape-rolls-checks.json`: native physics rays, XRTools held actions, all three kinds, transformed anchors, non-default collision layers, transient reparenting, hidden targets, deletion cleanup and isolated native copies.
- `ada_run/matter-reference/tape-rolls-player-checks.json`: actual desktop mouse and synthetic XR grip/trigger, all three roll pickups and A/B actions, preview, release cancellation, undo/tidy, real taped-plank pickup and hand movement, final approach/circuit and shaft checks.
- `ada_run/tape-rolls/save-checks.json`, `export.json`, `editor-checks.json`: production publication, native geometry, pattern textures, shared workbench placements and editor save parity.

The rendered probe isolates floor 3 from adjacent asynchronous content. An existing Point Trace hardware `Panel_left` readiness problem remains outside this receipt. Synthetic XR is not physical-headset acceptance. No Quest package was rebuilt for this change. Existing unrelated scene/model shader preview limits are unchanged; the new tape uses exportable standard materials.

Source: `commons/artifacts/tape_roll/`. Registration: `commons/artifacts/registry/tape_rolls.json`. No chapter text or existing artifact source was rewritten.

Final receipts and native inspection screenshots are copied into `doc/ports/2026-10-26-tape-rolls/`. The initial exact comparison also preserved the original Unicode labels and confirmed byte-identical canonical/Desktop saves after a damaged-label rewrite was detected and narrowly restored from the intact mirror. No other floor data was replaced.

The user's follow-up selected physical binding and dragging stripes over objects. Hold fire and drag now samples up to 256 collider-local points; release commits one stripe and one Undo operation. Actual sphere-ray tests verify curvature rather than a flat endpoint chord. Missed rays break the stroke, and the paid length is the sum of its drawn sections. Tap/tap straight spans remain available.

Separate bodies, with at least one rigid body, bind through reversible native Jolt fixed joints. Gravity and impulse tests verify that they carry load and retain their relative pose; Undo releases them. A reference-counted physics lease activates frozen utility pickables and restores their source settings when the last strip is removed. Pulling a bound piece 28 cm out of its held frame peels the joint and visually splits the ribbon. The physics state also restores correctly when peeling occurs during a native grab. This is an ideal fixed-frame adhesive model, not a tape-cloth simulation or an invisible collision wall.

The extension adds `tape-stripes-checks.json` for sampled curves, air gaps, native load-bearing joints, multi-strip cleanup and peeling. The main player receipt now includes actual desktop and synthetic-XR hold/drag/release, whole-stroke Undo, binding creation and hand peeling. No saved room arrangement changes were needed for the extension.
