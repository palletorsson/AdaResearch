# Movement becomes a seed — 13 October 2026

Built the small embodied sampling experiment at the existing Random Definition
colour bench. The point inherits the museum's PointBody pickup behaviour. Desktop
carry and VR controller tracking supply different, explicitly named sources.
Release records a seed; replay repeats the paired 4 × 4 grids. The existing ride
sphere remains a separate encounter, following its own out-and-back path.

The implementation and measurement limits are in
`algorithms/randomness/seed_replay/MOVEMENT.md`. The learner's `tutorial.md` and
reflective `final.md` were not rewritten in this pass. The illustrated review
page proposes a route for their next editorial pass without adding it automatically.

## Evidence

`runtime-report.json` contains 59 passing checks from Godot 4.6's real isolated
museum, including production desktop carry and sampling updates. A separate
Python calculation verified the fixture's SHA-256 digest and little-endian
modulo mapping to seed 880. The pose fixture is deterministic; its photographed
result is labelled accordingly. It supplies no evidence about human entropy.

XR tracking tests use a synthetic XRControllerTracker to verify rejection of
low confidence and stale poses, and exclusion of virtual-origin movement.
Physical Quest pickup, tracking characteristics and comfort remain unverified.
No new APK was installed. No network request was made in these tests.

The test harness dynamically loads the desktop pointer after autoload startup,
avoiding a startup-order dependency in XRTools. Godot assertions and screenshots
were checked; the remaining engine warnings concern renderer feature support,
Jolt solver bias and existing museum placement fallback.

`before/` retains the edited script and map as they stood before this pass, plus
the affected museum-plan entry. `seed-replay-change.diff` shows this pass's changes
to the existing bench script, independently of earlier uncommitted work.

## Editorial consequence

The offline museum still receives input from a person. A movement can contribute
to a seed without directly selecting the resulting colours. Keeping that seed
makes the picture repeatable. The technical text can teach these transformations;
the reflection can follow the relation between an encounter and what remains of
it. Neither should infer certified true randomness from changing pose values.
