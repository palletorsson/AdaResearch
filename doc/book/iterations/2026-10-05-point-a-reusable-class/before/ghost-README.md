# Ghost Student

An imagined student's code, carried from hall to hall. This is a small content repository inside Ada Encyclopedia's existing Git repository; it has no nested `.git` directory.

## Current starting chain

1. `states/001-point-one/point.gd` is built from the **complete printed Point One script** on an empty `Node3D`. It creates the static body, sphere mesh and matching collision shape itself. Both shapes belong to the point. No material helper or reconstructed starting fixture is assumed.
2. `states/002-point-coordinates/point.gd` continues those exact saved bytes. Declared edits change the body type and pickup settings, then add a `Label3D` that reads `global_position` and converts it with `to_local()`. The sphere and collider construction stays intact. The readout belongs to the study while the point moves.
3. `states/003-point-lines/line.gd` continues the **actual tested Coordinates output**. It keeps `point`, its shape construction and the LOCAL/WORLD readout, duplicates the point for a second endpoint, and adds a live segment and distance. The supplied `line_skin.gd` renderer is printed in full and remains unchanged.
4. `states/004-point-trace/trace.gd` continues Lines with the **original held point**. It removes the second endpoint and the single live relation, keeps the coordinate readout and helper, and stores accepted local positions in an array. An `if` checks distance from the last accepted sample; a `for` loop draws each neighbouring pair. The handoff is saved source code in the learner's working scene, not an automatic transfer of a running museum session.

The Point One and Coordinates evidence is retained under `evidence/2026-10-05-points-built-and-carried`. The fresh Lines continuation has its own code, full tutorial snapshot, exact-edit contract, native report, expected file, next-input record and pair exercises under `evidence/2026-10-05-lines-from-the-carried-point`. The reader checks that each complete printed GDScript block exactly matches its saved script, allowing only LF/CRLF normalization. Printed supplied files also match the saved helpers and report inputs. Point One has no predecessor; each continuation binds the actual preceding output hash.

Trace has its own full script, unchanged renderer, tutorial snapshot, exact edits from Lines, native report and two complete exercise programs under `evidence/2026-10-05-trace-the-carried-point`. The exercises change the acceptance threshold and omit the last drawn pair. Its report checks sample order, accumulated movement from the last accepted position, adjacent segments, pickup and release, and the readout. Separate deliberate failures remove the distance condition and use the wrong neighbour.

The native tests run in an isolated Godot project. They test geometry, collision, object relationships, pickup and release, and local/world readouts, with deliberate failure controls. XR Tools uses a synthetic controller. These reports do not certify headset input, rendered appearance, a museum playthrough or learner understanding. Opening the repository reads the saved results; it does not rerun them.

## Preserved earlier evidence

The original `evidence/2026-10-05-lesson-state-chain` archive remains byte for byte unchanged. It records the earlier assumed Point One input and pickup-only Coordinates output, with 62 native checks. Those files are historical evidence and are no longer the current steps 1 and 2.

The former Lines contract, code, supplied `line_skin.gd` renderer and 70-check native report remain under `evidence/2026-10-05-lines-relation-and-rule`. The separate full-code text check under `evidence/2026-10-05-lines-two-texts` also remains unchanged. That old native report still binds the former Lines tutorial; it has not been rebound to the new continuation.

The current Lines state uses its fresh native evidence and the current Coordinates input. The earlier archives remain separately downloadable through their original manifest IDs. A historical report never supplies the current lesson's check count or substitutes for its predecessor binding.

## Inspect and check

Open `/ghost-student` in Ada Encyclopedia. `GET /api/ghost-student` reads these saved files; `GET /api/ghost-student/file?id=point-one-code` exports only a manifest-listed file. There is no execution or mutation API.

Run from the Encyclopedia root:

```powershell
node --experimental-strip-types --test tests/ghost-student/backend.test.mjs
```

Set `ADA_RESEARCH_PATH` to the museum checkout for live freshness comparison. Each state's own source and dependency hashes are checked on every read. Changed sources mark evidence **stale**; an unset path makes freshness **unavailable**. Saved file, report or composition integrity failures mark it **invalid**. A deliberately retained historical predecessor that differs from the current chain marks it **needs-revision**. Matching source pins still refer to the saved native run, not a fresh run.

## Add one hall at a time

Start with the prior state's saved output and exact SHA-256. Write the short brief: bring, make, given, build, check, later. Declare exact unique-anchor edits and compose the next state mechanically. Reject missing or repeated anchors. Print the complete resulting learner script and bind it to the runtime evidence.

Check changed behavior and a plausible deliberate failure in an isolated runtime. Save a new dated report with its inputs and dependencies. Preserve older evidence and clearly mark any predecessor change. Give supplied helpers their own checksums and keep their relative locations.

Update `manifest.json`, the state brief and the explicit file allowlist. Verify composition, printed-code completeness, predecessor hashes, evidence bindings and source drift. Grid (`Point_Line_Grid`) remains planned until it has its own code and evidence.
