# Point Lines encounter-route pilot

2026-09-15. Live: <http://localhost:3003/long-museum/encounters?map=Point_Lines>.

The Long Museum sidebar links to this view. It reads the current authored map, current final.md and existing role decisions. The seven proposed encounters live in `commons/data/encounter_routes/Point_Lines.json`; this is a review overlay, not a replacement owner of book order, primary roles or placements.

Click a numbered stop or its summary to read the current passages and see all participating artifacts. Copy an encounter to carry its action, question, exact passages and source hashes into a revision discussion. The Sources links open the existing comment workflow. Refresh sources after map or text edits.

## What this reveals

The initial read found 145 grid steps and 51 revisits to route cells across nine legs (seven encounters, two visits for plus/X, then the exit). This is a floor-grid estimate, not an observed player's journey. The later construction stations currently require backtracking. The book includes `two_point_ruler`, which is not placed; the proposed red-line encounter has no book passage. Existing passages outside the new route are listed for review, not deletion.

Next work: inspect/stage the connection and barrier, then the interactive metre line, then the red line. Use the view to propose local placement and passage changes. Later encounters remain interaction proposals. Do not turn those proposals into claims that their new controls already exist.

## Spatial limits

- Routes use four-connected flat floor cells and the engine's enclosed-zero basin rule (at least four cells), with glass support only when configured.
- Goals are adjacent standing cells, not artifact centres. These are estimates of approach, not proof of controller reach or visibility.
- An explicit spawn utility definition takes priority over the generic `s` marker. Ambiguous entrances/exits are reported.
- Duplicate artifact types require instance coordinates. If a selected instance moves, the route reports a missing instance rather than silently choosing another.
- An unresolved leg breaks subsequent continuity; the route never draws a shortcut through a wall or silently resumes beyond the gap.
- Barrier states are selectable snapshots. The intact barrier excludes its anchor cell only. Its rotated collider footprint, other artifact collisions, player width and the museum's assembled vestibules remain outside this model.
- The trace approaches the walking stripe; it does not prescribe a walk along it. Secondary spatial groups are shown as participating artifact anchors, with explicit visited instances in the proposal.

## Implementation and verification

App files: `src/lib/encounter-route.ts`, `src/app/api/encounter-route/route.ts`, `src/app/long-museum/encounters/page.tsx`, plus one link in `src/app/long-museum/page.tsx`.

Reproducible model tests: `node ada_run/encounter-route-web/test.cjs` from the game repository (Node must be on PATH). The test loads the app's actual model and shared Long Museum cell vocabulary. Twelve checks passed, including glass handling, duplicate instances, passage extraction, role expansion, wall exclusion, failed-route continuity and preservation of the map, book and role files. Scoped TypeScript compilation passed. Report: `ada_run/encounter-route-web/test-report.json`.

Live HTTP: API and page returned 200; unsupported map returned 400. Browser automation failed during connection setup, so rendered layout, clicks and clipboard have **not** been verified. Full-museum collisions, real reach/sightlines and headset comfort are also **not run**.

`ada_run/encounter-route-web/` contains staging copies and the installation snapshot. The live app sources are authoritative for later implementation edits. Do not rerun install.py: it deliberately refuses to overwrite an existing installation. The preservation test compares with this turn's baseline; future intentional content changes require a new baseline rather than treating the old hashes as permanent artistic constraints.
