# Editing the walk and the book together

2026-09-15. Open <http://localhost:3003/long-museum/encounters?map=Point_Lines>.

## Working together

1. Choose a hall. The default list follows the actual curriculum spine (currently 24 sequences, 193 halls). Search or enable maps outside the spine to browse the rest of the 2,795-map catalog.
2. Select an encounter on the plan or its card. Read the actual book passages alongside its proposed action and question.
3. Open **Edit encounters**. Move an encounter earlier/later, group participating artifacts, or choose a placed instance for the route to visit. A recorder such as player_trace can participate without requiring the visitor to walk to its scene anchor.
4. Write a **Draft book passage**. Markdown and code fences are supported. It appears as a proposed passage alongside the current book. **Save proposal** persists the whole encounter plan and its drafts, not final.md.
5. Use **Copy encounter for review**, or **Copy reading route** to read the proposed thread continuously. Bring it to the conversation for a scoped revision. Apply an agreed passage to final.md through the established Sources workflow; preserve the rest of the book.

Changes can be discarded before saving. Switching maps and refreshing are disabled while local changes are unsaved. Browser navigation also warns about unsaved changes. Saves retain prior versions and reject stale edits when the underlying map, book, roles or saved proposal have changed. If that happens, copy the draft, discard local edits, refresh sources and compare before saving again.

## What is new in Point Lines

The first three encounters have proposed passages:

- **Connect:** the existing line_demo text followed by the existing barrier passage, so the consequence stays with the connection.
- **Measure:** an endpoint operation introduces the metre, distance and direction, with the example code retained and rounded readings made concrete.
- **Red line:** a new encounter distinguishes the visible division from an enforced collision boundary and leads into walking the black stripe.

These are review drafts. The approved book, map placements and role decisions have not been overwritten. Later interaction improvements remain proposals, not claims about existing controls.

## How unreviewed halls start

Routes without a saved overlay scaffold from the current book's anchored primary/unruled passages, followed by explicitly primary artifacts without passages. Explicitly secondary/decoration passages remain available but do not automatically become route stops. The scaffold supplies no invented questions or controls. Empty halls can start with an artifact chosen in the editor. Missing book text and ambiguous duplicate instances are visible as gaps.

The floor plan can set explicit entrance/exit cells for the proposal. This changes the review trace only. The estimator handles flat floors and configured glass basins; lifts, ramps, terrain, moving bodies and collider footprints still need spatial inspection. Zoom the plan to inspect longer halls. A disconnected stop breaks the displayed itinerary rather than inventing a shortcut.

## Sources and implementation

- Editable proposals: `commons/data/encounter_routes/<map>.json`.
- Prior saved versions: `doc/book/encounter-route-history/<map>/*.json`, including the previous file bytes and the new proposal.
- App model: `src/lib/encounter-route.ts`.
- Catalog, guarded persistence and validation: `src/lib/encounter-store.ts`.
- API: `src/app/api/encounter-route/route.ts` (GET map/catalog, POST proposal with expected source version).
- Interface: `src/app/long-museum/encounters/page.tsx` and `EncounterEditor.tsx`.

The original install scripts in `ada_run/encounter-route-web/` and `ada_run/encounter-route-editor/` are one-time staging tools. Do not rerun them. The app sources are authoritative for further development.

## Checks

Run from the game repository with Node on PATH:

```powershell
node ada_run/encounter-route-editor/test.cjs
```

Sixteen behavioral checks passed, including save/reload, grouping, source conflicts, locks, revision history, invalid IDs, path rejection, empty halls and preservation of the map/book/roles. All 193 spine halls loaded. Scoped TypeScript compilation passed. The earlier 12 floor-route checks also passed after the extension.

Live HTTP checks exercised a Point Lines save and reload with all three drafts retained, pages for Point Lines and Point One, a Soft Bodies API read, invalid-body rejection (400) and stale-save rejection (409). Evidence is in `ada_run/encounter-route-editor/test-report.json` and `http-report.json`.

Browser automation failed during connection setup. Rendered layout, clicks, clipboard and unsaved-change navigation have not been exercised in a browser. Full-museum collision, physical reach and headset comfort remain unverified. Automated data coverage does not certify the pedagogical quality or spatial traversability of every hall.
