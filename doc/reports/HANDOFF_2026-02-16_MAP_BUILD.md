# Handoff - 2026-02-16 (Map Build Focus)

## Purpose
Give the second AI a clear, non-overlapping scope for today so map-building can continue fast.

## Current Decisions (Do Not Re-open)
- Sequence membership is explicit from sequence JSON `maps[]`.
- Map name prefixes do **not** assign sequence membership.
- Artifact folder location (`commons` vs `algorithms`) does **not** decide map inclusion by itself.
- Missing/unresolved artifact scenes should degrade to placeholder, not hard-fail map generation.

## Current Local Change Set
- Modified:
  - `commons/grid/GridInteractablesComponent.gd`
  - `commons/artifacts/catalog/ArtifactCatalogDataProvider.gd`
  - `commons/artifacts/catalog/ArtifactCatalogDesktop3D.gd`
  - `commons/maps/curriculum_spine.json`
  - `doc/HOW_TO_ADD_MAP_SEQUENCE.md`
  - `doc/TAXONOMY.md`
  - `commons/maps/Structure_Examples/map_data.json` (pre-existing local edit, leave untouched unless requested)
- Added:
  - `commons/artifacts/placeholders/ArtifactPlaceholder.gd`
  - `commons/artifacts/placeholders/ArtifactPlaceholder.tscn`
  - `tools/spine_map_workbench.py`
  - `doc/reports/SPINE_MAP_BUILD_STATUS.md`

## Best Work for AI #2

### Work Package 1 - Registry Curation (High Priority)
Curate artifact eligibility for map placement using registry metadata (not folder heuristics).

Target files:
- `commons/artifacts/grid_artifacts.json`
- `commons/artifacts/registry/*.json` (start with randomness/noise/transforms/wavefunctions/cellular_automata)

Tasks:
- Add/normalize metadata for map curation:
  - `include_in_map_data` (`true`/`false`)
  - `map_ready` (`true`/`false`)
  - `map_sequences` (explicit sequence IDs list when relevant)
- Mark WIP or unstable artifacts as `map_ready: false` instead of removing them.
- Keep reusable cross-sequence artifacts explicit through `map_sequences`.

Acceptance checks:
- `python tools/spine_map_workbench.py suggest --sequence randomness --limit 12`
- `python tools/spine_map_workbench.py suggest --sequence noise --limit 12`
- `python tools/spine_map_workbench.py audit-artifacts --report doc/reports/ARTIFACT_REGISTRY_AUDIT.md --json doc/reports/ARTIFACT_REGISTRY_AUDIT.json`
- Suggestions should reflect intentional curation, not broad leakage.

### Work Package 2 - Sequence Map List Audit (High Priority)
Ensure sequence JSONs are intentionally curated and not relying on naming conventions.

Target files:
- `commons/maps/sequences/*.json`
- `commons/maps/map_progression.json` (where applicable)

Tasks:
- Audit each sequence `maps[]` against intended pedagogy.
- Remove maps that only match by name/theme but are not pedagogically part of that sequence.
- Add missing maps only when sequence intent requires them.

Acceptance checks:
- `python tools/spine_map_workbench.py status --report doc/reports/SPINE_MAP_BUILD_STATUS.md --update-taxonomy doc/TAXONOMY.md`
- Review `doc/reports/SPINE_MAP_BUILD_STATUS.md` for correctness.

### Work Package 3 - Runtime QA Sweep (Medium Priority)
Validate that curated data still runs without breaking map flow.

Focus areas:
- Placeholder fallback behavior in map load + artifact catalog preview.
- TestPlus sequence flow after map/sequence curation changes.

Acceptance checks:
- No hard fail when a referenced artifact scene is missing.
- Sequence transitions still follow explicit `maps[]`.

## Recommended Split
- AI #1 (current thread): engine/runtime behavior + tooling.
- AI #2: registry + sequence content curation and validation.

## Guardrails
- Do not commit `openxr_action_map.tres`.
- Do not revert unrelated local changes.
- Keep sequence inclusion explicit and intentional.
