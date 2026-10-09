# Claude handover: where an artifact can contribute

Prepared 2026-09-15. This is an implementation brief, not an approved classification of the museum.

## Outcome

Extend the encyclopedia's Map Curator with a contribution view, proposed URL `/map-curator?view=contributions&sequence=primitives&map=Point_One`. A reader should be able to follow the actual spine, understand what each hall adds, inspect its current artifacts, and discover other artifacts that could do useful work there. Link to Algorithms for implementation documentation.

The central question is: **What can the visitor do with this artifact here, and what does that make possible next?** Subject tags support that question; tags alone do not answer it.

Build a working Primitives pilot with all spine rooms and all registry artifacts discoverable. Leave the rest explicitly unreviewed. Do not attempt a definitive automatic classification of the whole collection.

## Existing foundations to reuse

App repository: sibling `ada_encyclopedia`. Game/content repository: `AdaResearch_46`.

| Existing source | Use |
|---|---|
| `ada_encyclopedia/src/app/map-curator/page.tsx` | Map board, artifact deck, placement links. Its hardcoded chapter list omits parts of the current spine; do not copy it into the new view. |
| `ada_encyclopedia/src/app/algorithms/page.tsx`, `src/lib/ada-repo/algorithms.ts` | Algorithm README browser, keyed by implementation path. It currently groups by folders, not curriculum purpose. |
| `commons/maps/curriculum_spine.json` | Sequence membership and numeric order. |
| `commons/maps/sequences/<sequence>.json` | Ordered `sequences[sequence].maps`; retain empty rooms and flag missing files. Do not derive this list from artifacts. |
| `commons/maps/sequences/*.beats.json` | Existing concept/beat hypotheses. Show provenance and mismatches against current sequence membership. |
| `commons/artifacts/registry/*.json` | Artifact IDs, scene paths, descriptions, tags, dev_themes, map_sequences and spatial metadata where present. Reuse identifiers; registry hints are not verified pedagogical fit. |
| `commons/maps/<map>/map_data.json` | Actual placements and their configurations. Retain multiple instances of one artifact. |
| `commons/data/artifact_roles.json`, `tools/artifact_roles.py`, `/api/spine-roles` | Existing contextual roles, ordering and candidate search. Keep explicit decisions distinguishable from fallback/default roles. |
| `commons/data/spine_briefs.json`, `tools/spine_brief.py` | Existing room purposes, claims and uncertainties. Briefs may describe earlier map versions. |
| `commons/maps/<map>/final.md`, tutorial/technical/critical/intent documents where present | Book encounters, teaching and critical material. Show exact source references rather than silently replacing them with a summary. |
| `tools/build_spine_ontology.py`, `doc/*_concept_map.json` | Existing derived concept maps. They infer subject from current placement; use as candidates, not as proof that an artifact belongs only there. |
| `tools/build_artifact_map_index.py`, `doc/artifact_to_maps.json` | Existing reverse placement index; verify freshness against source maps. |

`/api/spine-order` is an artifact dealing-order API, with generated and hand overrides. It is not the complete list of rooms. Inspect and label museum/order drift rather than silently substituting it for curriculum order.

Check applicable repository instructions before implementing. Reuse existing data loaders and guarded write helpers where appropriate. Preserve unrelated working-tree edits.

## Model three things separately

1. **Subject:** stable ID, human label, broad subject relationships, narrower subjects and aliases. Permit multiple parents and cross-links. For example: geometry → point/line/grid; computation → sampling; motion → position/time. Avoid forcing every artifact into one branch.
2. **Artifact knowledge:** artifact ID, subject links, implemented capabilities, controls, algorithm/source links, known spatial requirements and evidence. Missing knowledge is `unknown`, not a guessed capability.
3. **Contribution to a hall:** artifact ID + sequence/map context + an optional instance/configuration reference. Store the visitor's action, observable result, technical principle, prerequisites, capability gained, possible critical/poetic question, and why this belongs at this stage. One artifact can have several distinct contributions in one or many halls.

Track bodily/application layers separately from subjects: object, player, other agents, floor/terrain, wall/material, whole room. A cellular automaton can act on a garment or on a floor without changing its algorithmic subject.

Keep these distinctions visible:

- **Placement:** already present / candidate / previously removed or deferred.
- **Role:** existing primary / secondary / decoration, as recorded by the current role system.
- **Review:** proposed / accepted / deferred / rejected, with a reason and reviewer.
- **Evidence:** documented / source inspected / runtime observed, with relevant source path, hash and optional capture/report.

Acceptance of a contribution means accepting an editorial proposal. It does not move an artifact, promote it to primary, or write the book. A source change can make evidence stale without erasing the earlier decision.

Prefer a small versioned JSON overlay for these new relationships, with stable IDs and source fingerprints. Choose its final path after checking existing schemas. Do not duplicate the registries, roles or prose into another authoritative store. Keep generated suggestions separate from reviewed decisions so regeneration cannot overwrite them.

## Interface

- Left: real sequence → hall order, including halls with no artifacts or no reviewed purpose.
- Centre: selected hall's purpose, what the visitor brings from earlier halls, what they do and learn, and what it prepares. Show original text beside any proposed summary and link to `/compose/sources?map=<map>`.
- Right: current artifacts followed by proposed candidates. Cards show image when available, subject chips, implementation links, current roles and a short **why here**. Missing images have a clear fallback.
- Select an artifact to see its other placements and possible contributions along the spine. Preserve instance configurations: the same script may behave differently in different maps.
- Filters: broad/specific subject, application layer, already placed/candidate, evidence and review state. Search includes unclassified artifacts.
- A review queue exposes missing knowledge, stale evidence, unresolved fit and disagreements. No hidden numeric score presented as pedagogical authority.
- Each proposal has an editable reason and a copyable handover containing map/artifact IDs, source references, proposed action and uncertainty. Reuse the established review-comment pattern where useful.

Critical questions may remain open. Do not require a generic paragraph about exclusion on every card. Secondary artifacts may contribute beauty, pleasure, orientation or a useful detour. No fixed quota of primary artifacts.

## Calibration examples — proposals to test, not new rulings

| Artifact | Context | Distinct contribution |
|---|---|---|
| `player_trace` | `Point_Lines` | Walk beside the straight instruction; compare the recorded route with the line. The instruction becomes something the body can relate to and deviate from. |
| `player_trace` | `Point_Trace` | Candidate: inspect how samples constitute a trace. Verify available controls before proposing any resolution interaction. |
| `interactive_point_origin_force` | `Point_One` | Move the same point watched by the coordinate frame and readout. Its additional capabilities need not all be taught here. |
| `wireframe_threshold` | `Point_Triangle_Context` | Inspect its existing use as a candidate for exposing mesh construction after triangles; preserve its deferral from Point One. |

The pilot should make these contextual differences legible. Do not silently rewrite approved Point One prose, draw the invisible point, or turn absent controls into visitor instructions.

## Delivery stages

1. Inventory existing sources and propose the minimal schema. Show one complete hall and one artifact with multiple possible contributions before expanding the tagging vocabulary.
2. Implement the read view across the actual spine and registry, with explicit provenance and unknown states. Seed a small, source-inspected Primitives sample as proposed contributions.
3. Add persistent metadata review/editing and copyable handovers. Validate IDs and use source/version guards; reject stale writes clearly. Reviewing metadata must not mutate map placements, roles or final.md.
4. Provide screenshots, a live pilot URL, a sample export and test results. Expand classification after Palle and Astra review the examples.

Actual placement changes should continue through the existing `/api/maps/cell-edit` workflow. This task does not need a second placement writer.

## Acceptance tests to write and run

Use the app's existing test stack where available. Test production loaders/routes, not a second implementation copied into the test.

1. Sequence order follows the canonical numeric order, including fractional values; map order follows sequence membership. Empty rooms remain visible and missing maps are flagged.
2. One artifact with two subjects and two contextual contributions retains all relationships after save/reload; two configured instances remain distinct placements.
3. Registry collisions and unknown referenced IDs are surfaced; a missing image, README, role ruling or contribution produces an honest fallback rather than a crash or invented content.
4. Selecting a subject finds matching unplaced candidates as well as placed artifacts. Candidate status never implies primary role or verified suitability.
5. Source changes mark affected evidence stale. Concurrent edits fail with a reviewable conflict rather than silently overwriting another decision.
6. Regenerating suggestions preserves accepted/deferred/rejected decisions. An AI suggestion cannot mark itself as a human-reviewed acceptance.
7. Metadata operations leave map_data.json, role decisions and final.md byte-for-byte unchanged. Use temporary fixtures for mutation tests.
8. Direct URL navigation, filtering, save/reload and copy-handover work in the browser. A copied proposal includes enough source context to review independently.

Report the commands, cases passed/failed and checks not run. The existing `python -X utf8 tests/museum/run.py` is a separate regression suite for Point One and Point Lines; it does not validate this new web feature. Run it if shared game/content behavior is touched, and do not weaken its expectations.

Return changed files, the pilot URL, test evidence and unresolved content questions. Do not claim to have understood or reviewed the entire registry merely because it is indexed.
