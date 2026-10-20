# Authorized implementation: Random_Noise_Types trial

Palle now asks Claude Code to BUILD the proposed Random_Noise_Types trial:
“use the weather walls as partitions and keep the sampling bench. Keep it
editable in the lab editor, test it and show me screenshots.”

This supersedes the earlier read-only scouting restriction for this task.
Read live project guidance and live sources. You may edit and run appropriate
tools/tests in AdaResearch_46 and sibling ada_encyclopedia. Complete the
implementation, rather than returning another proposal. No commits, unrelated
cleanup, credential changes, or overwriting concurrent work.

## Scope

- Separate selectable trial; preserve curated tower and Transformation trial.
- Reuse all six existing Random_Noise_Types artifacts and their actual museum
  configurations: randompoint, randompoints sampling bench, WhiteNoiseGallery,
  NoiseColors3D, related_weather, geometry_noise.
- The weather's fixed glass walls partition the space; people walk around their
  ends. Moving slits are visual openings, not walk-through doors. Retain a clear
  arrival, controls, routes, shaft access and escape from each lane.
- Keep the bench central to the learning encounter: REDRAW, LOAD, admitted and
  refused candidates, finite budget, minimum distance at admission. Preserve the
  algorithm. Give the trial bench an explicit reproducible seed.
- Use the tower's overhead supply, restrained construction mounts and lighting
  to make these feel like recovered alien instruments integrated into a building.
  Measure bounds and adjust your provisional coordinates: gallery/bench positions
  can overlap weather controls in the scouting proposal.
- Fixed floor/pillars/shafts; no unrelated frame changes. All artifact placements
  and added props remain editable through the existing lab-editor Void trial
  workflow. Export real geometry and retain independent artifact records.
- Keep tutorial.md and final.md unchanged; record spatial references needing
  later review separately.

## Implementation and evidence

Follow live commons/void/trials/README.md, playable.json, Transformation trial,
exporter and editor save APIs. Prefer a clear trial ID such as random-noise-types
if the current registry accepts it. Reuse existing mechanisms; extend only where
needed. Check exporter side effects: export_void_trial.py may write shared
line_parts.json; preserve concurrent/shared entries.

Review ASSESSMENT.md in this directory: config metadata is already stamped before
ready; don't add unnecessary adapters. related_weather uses seed 4321; changing
it is not required. The source packet is a reading snapshot, not runnable closure.

Run real native Godot checks of load, configuration, bench determinism and
admission accounting/minimum distance/bounded failure. Verify controls/pickup,
fixed-glass collision, gallery audio inactivity/unload, retry and re-entry as
applicable. Test editor move/copy/rotation/save/reload and isolation from curated
rooms. Do not simulate evidence by merely asserting authored constants.

Capture several real rendered screenshots from inside the tower: arrival/bench,
weather partitions with a traversable route, and a wider view. Inspect captures
and fix glaring overlap/lighting/legibility issues. Distinguish native desktop,
synthetic XR and actual physical headset observations. Never claim physical VR
tested without doing it.

Put a concise report with screenshots under
doc/book/iterations/2026-10-20-void-noise-types-trial/ and provide the lab-editor
URL, game launch path, touched files, exact test commands/results and remaining
limitations. Tell this conversation when complete or concretely blocked.
