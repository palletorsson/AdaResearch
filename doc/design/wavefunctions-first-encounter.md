# Wavefunctions: the first staging conversation

2026-10-23. Apply the artifact-space rules as a flexible repertoire. No layout
or source behaviour changed in this first discussion.

## Encounter selected from the existing sequence

Main Void floor59: WaveFunctions_Intro, "Wave Functions / the cube comes back".
Begin with artifact `clock` / `y_oscillation_cube`, on the existing `clock-bench`.
The adjacent `turn` / `rotating_cube_demo` is a meaningful comparison, not filler.

Source references inspected:

- commons/maps/WaveFunctions_Intro/final.md
- commons/maps/WaveFunctions_Intro/intent.md
- commons/artifacts/y_oscillation_cube/y_oscillation_cube.gd
- tools/publish_wavefunctions_opening.py
- commons/void/rooms.json, floor59
- Current exported native source geometry in public/void-models/manifest.json
  (the main floor currently reuses the existing trial model snapshots).

The maintained chapter begins with a clock-driven cube. It revisits one height
with opposite directions. The pendulum later compares prescribed motion with a
responding state. The older intent.md names the pendulum as the primary encounter;
the later opening publisher explicitly records the author correction to begin
with the cube. Do not follow the stale priority when staging the introduction.

## Preserve the distinction

The cube evaluates sine from elapsed time; its return is not caused by a physical
collision, spring or hand. The source header mentions missing amplitude/frequency
sliders. Do not stage a fake switch or imply that such controls already exist.
Its labels and rail are the current means of observing it.

Current placement: clock at[-3,3], height1.3, scale2; workbench at[-3,3].
Default source cube size0.15m, amplitude0.2m, frequency1Hz. At scale2 the visible
cube is0.3m wide and travels0.8m peak-to-peak. Including the body, its intended
vertical sweep is0.9m to2.0m above the floor at the saved mount height.
The declared workbench height is1m. Inspect the actual tabletop before accepting
the support: the lower sweep may intersect it. A static snapshot cannot settle
clearance throughout the cycle. No height fix is chosen yet.

## Possible staging strategies — not selected

1. Shared comparison work area (recommended): keep the rising and turning cubes
   visible from a common approach. Use the existing benches, a selected backdrop
   and purposeful storage to define the outer margin. Each artifact remains
   independently editable. Keep an open front and walk-around access; do not put
   a divider between the cause/difference the visitor needs to compare.
2. Focused first bay with a sightline to the next bench: give the rising cube
   stronger enclosure and reveal the turning comparison on departure.
3. Open island: keep the cube accessible from all sides; shape the approach with
   a low boundary and a place for familiar spare parts rather than a rear wall.

Use existing prefabs only. Do not add every enclosure type. Preserve the original
source scene, comparison objects, shaft circulation and chapter text. Incidental
play with loose objects can remain possible; there is no new mandatory completion
condition in this staging discussion.

## First decision for Palle

Should the first cube and the nearby turning cube share one working area, with
both visible from the approach? Recommendation: yes. Their different movements
are the reason to keep them together. Choice of backdrop, support clearance and
specific props follows this decision; no bay has been built yet.

## First staging trial installed — 2026-10-23

Palle accepted the shared working area ("let try that"). The floor59 placement
now has six separate existing props: scaffold_tarp, unfinished_wall,
steel_barrier, crate, timber_plank_2m and work_light. Both original benches and
all21 original artifacts remain. Only the rising cube's mount height changed,
from1.3m to1.45m. Its source motion, scale, parameters and labels are preserved.
The recorded native minimum clearance over the actual0.95m tabletop is about0.10m.

The open front, complete walk-around and departure to the original pendulum
approach pass actual capsule movement checks. No prescribed completion condition
was added. All other floors, existing props and the authored route are unchanged.
There are23 targeted native checks and4 isolated editor model/validation checks.
Physical headset and full player-input acceptance remain untested.

Evidence: ada_run/wavefunctions-shared-bay/review.json. Visual review:
doc/book/iterations/2026-10-23-wavefunctions-shared-bay/index.html.

Review with Palle before extending to the next encounter: does it feel cared
for and useful? Does the scaffold frame the two motions or compete with them?
