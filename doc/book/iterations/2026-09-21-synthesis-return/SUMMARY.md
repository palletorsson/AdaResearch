# Synthesis — the body that returned

21 September 2026. [Read the chapter with actual museum views and the original text](index.html). [Exact chapter diff](final.md.diff).

## What changed and why

The final hall now receives a change made in Assembly Laboratory. Releasing a moved joint keeps one latest local pose. The final hall reconstructs the starting pose in blue and the released pose in amber at standing scale, with room to walk between and around them. The existing ledger stands to one side and reports that same record. With no saved pose, the amber place remains empty.

This gives the ending an encountered difference to investigate. The new chapter begins with the returned hand, follows what the record keeps and omits, and asks what another act of remembering would make possible. It retains the earlier paragraph about a form one wanted to enter and the closing clock. One continuity paragraph in Assembly now leads into the kept pose; the rest of that chapter is preserved.

All six existing Synthesis artifact families and the authored floor remain. A seventh family, `assembly_return`, is added as a primary before `accountability_ledger`. Primary roles, book ordering, both trunk files, core encounter hashes and derived museum/necklace data agree. Only Synthesis's row in the museum placement plan changes. The live bake is not replaced.

## Implementation

- `AssemblyPoseRecord.gd`: a bounded, validated record of thirteen named joints, twelve connections, radii, starting/released coordinates, source hash, release count and save time. Normal path: `user://ada_research/assembly_pose.json`. Temporary write then rename; session cache survives hall unload. A failed write is labelled session-only.
- `AssemblyBodyStudy.gd`: records changed releases and restores a matching saved pose on revisiting. With two joints held, one released joint does not commit the other's unfinished movement.
- `assembly_return.gd` / `.tscn`: reconstruct both bodies from the record; honest empty state on a fresh installation. Visual geometry, no supporting collision or new control panel.
- `accountability_ledger.gd`: opt-in actual-record mode, retaining illustrative mode elsewhere. No progress is fabricated by waiting. Opaque backing fixes transparent sorting that obscured lower text rows; static record fields retain contrast.
- `PostCrisis_Synthesis/map_data.json`: gallery at (7,12), side ledger at (11,10). The floor and six earlier families are preserved. Clear approach and selected exit route remain.

The record keeps a single latest pose, not a hand trajectory, author identity, undo history or all visits. Editing positions does not change adjacency. Re-entering Assembly restores only a pose matching its current source and joint identities. The final comparison includes enough saved geometry to reconstruct an older record if the source later changes.

## Evidence

The final private rendered Godot run exits **0**. **27 behaviour checks** and **10 continuous selected walking segments** pass. These cover actual record production, simultaneous held joints, atomic replacement, invalid data, producer teardown and disk reload, exact reconstruction, revisiting, explicit write failure, corrupt-file handling, no time-based progress, attachment preservation and the unchanged illustrative ledger mode. [Runtime report](museum-runtime.json).

The probe uses a unique workspace-local record path. It does not read or replace the visitor's save. The before/after images show empty and kept states of the same new implementation. Four controlled joint releases produced the pictured amber pose; they are not evidence of a human visitor's choices. The path uses the museum's desktop body. Earlier Assembly grab evidence remains linked from its own review; this pass adds persistence and reconstruction checks.

The published source/content checks cover primary alignment, preserved floor and families, other plan rows, real source excerpts, current hashes and registry resolution. [Checks](content-checks.json). [Current input hashes](current-inputs.json).

No script errors occur. Existing engine diagnostics include an unresolved UID, root certificate-store warning and null-resource warnings. The derived long-museum report retains six unrelated layer-size disagreements; the necklace tool still reports earlier lookup/bake coverage gaps. They do not invalidate these direct instantiated checks and are not silently marked repaired.

Headset reach, comfort, text readability, Quest performance and learner understanding remain unverified. No live restart, live bake replacement or commit.

## Next reading and encounter

Read and eventually walk Rhizome → Assembly → Synthesis together. The passage, the changed body and its return should carry the investigation. Before adding a further control, decide which missing permission matters most: another connection in the body, two retained alternatives, or the hand's path. Each would create a different next encounter.
