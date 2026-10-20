# Capacity assessment checked against current source

Checked 19 October 2026. Read-only code review and Node execution; no browser readability test, game run, or physical headset test in this assessment. No application source or saved layouts changed.

The existing `ada_encyclopedia/scripts/check-capacity-artifacts.cjs` passes: 25 sequences, 209 halls, 107 authored objects, 141 relationships, 1,031 catalogue identities and 50 authored objects with capture files. These are inventory and structural checks, not evidence that every relationship is implemented or pedagogically effective.

The scoped capacity-tree web files and Godot `commons/void/` remain untracked. That prevents an ordinary committed before/after comparison; it does not invalidate source inspection, runtime test records or screenshots. The pasted report's blanket statement about Git overstates this limitation. Its unidentified “gate M” was not verified.

Nine authored IDs match tower top-level artifact/prop entries directly; one matches the Transformation trial. These are exact-token matching counts, not a census of implemented content. `trace_area.gd:4,25` loads and instantiates `draw_dot`; `primitive_hall.gd:65` places the cube net; `polyhedra_area.gd:25` places alignment instruments. Such assembly members need their own provenance. Direct matching undercounts them.

Conversely, `src/lib/capacity-artifacts.ts:186` onward infers Void placement using hall membership, source path/name, note text and carry annotations. The trial fallback uses membership in Trans_Pre. This is not robust placement evidence: keeping a hall label after removing an object would retain its badge. This is a demonstrable logic risk, not a claim that every currently inferred object is absent. Source-backed assembly resolution is needed, including actual saved part/copy semantics.

The UI assessment is partly stale. `src/app/capacity-tree/artifacts.tsx` now has a spine-cluster layout, depth alternative, status strip, and capacity cards. Their current visual quality has not been reviewed here. The strip is not the proposed complete per-sequence evidence table.

Current grouping by an authored node's primary `sequence` gives 19 of 24 non-primitive sequences exactly three nodes, not 22. Counting authored objects encountered in a sequence gives a different figure (10). For museum occurrences, current ratios include Primitives 21/142, Tiling 6/85, Randomness 4/85 and Graph Theory 3/14. Definitions and snapshots matter; the loader includes the `wp` utility. These ratios measure representation, not curriculum quality. Eight sequences have no cross-sequence outgoing authored edge under primary ownership; terminal branches are not automatically defects.

There are currently 25 unauthored identities encountered in at least three halls. The frequently returning `dark_sphere` (58), `science_screen` (30) and `synthesis_stand` (11) counts agree with the quoted report, but `3t` (20) and `tt` (17) also appear. Frequency alone is not an authoring priority. Infrastructure and artifacts outside the tutorial are legitimate parts of the museum.

The trial review file records Transformation as ready-for-VR, states that no physical headset review has happened, and preserves a menu renderer/shutdown caveat. It must not be presented as fully VR-verified. The checker did not rerun the recorded native tests or establish their freshness.

Recommended first work: evidence/state separation and provenance, then review the existing UI, then a curated gaps view. Do not automatically invent lineage, reorder the spine, or commit unrelated work. A one-day estimate has not been validated.

Claude handoff: a matching interactive session was found, named `Capacity tree improvements and progress tracking`. A separate file-tools-only Claude review was attempted without modifying that session. It returned `Failed to authenticate: OAuth session expired and could not be refreshed` before making any model request. Claude therefore supplied no independent findings in this assessment. `CLAUDE-HANDOFF.md` is ready for the existing session; `claude-review-brief.txt` preserves the attempted review scope.
