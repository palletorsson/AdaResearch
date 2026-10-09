# The body that returned — implementation and encounter

Two primary artifacts share a real record: `assembly_return` reconstructs a starting and released pose at standing scale; `accountability_ledger` names the source and reports the same record. The six earlier artifact families and the authored floor remain. The body comparison occupies cell (7,12); the ledger stands to one side at (11,10), height 0.65 m and scale 1.8. Both face the approach. The comparison bodies have visual connections and no supporting collision.

## From a released joint to another hall

[AssemblyBodyStudy.gd](../../../algorithms/computationalbiology/molecular_framework/AssemblyBodyStudy.gd) uses the existing VRBody: thirteen named joints and twelve connections. A release more than 0.01 m from the position at pickup increments its edit count and calls [AssemblyPoseRecord.gd](../../../algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd). Merely viewing or holding a joint does not create a record. When two joints are held, releasing one saves the other at its previous released position.

The record includes the source map, assembly identity and source hash, joint radii, starting and released coordinates, connections, completed edit count and last-save time. The normal destination is `user://ada_research/assembly_pose.json`. It holds one latest pose, not a sequence of gestures or a visitor identity.

```gdscript
file.store_string(JSON.stringify(record,"\t"))
```

Validated data is written to a temporary file and renamed over the earlier record. A SceneTree cache carries the pose through hall unloads; the disk file carries it through application restarts. If writing fails, the cache remains available and the captions say `this session only`. Missing or malformed files produce the empty state. Private probes override the destination with a workspace-local file and never replace the visitor's save.

The [return gallery](../../../commons/artifacts/assembly_return/assembly_return.gd) reads the same record once per second and rebuilds only when its revision changes. Blue uses the recorded starting coordinates; amber uses the released coordinates. Without a record, only the current catalogue's blue starting pose appears. The second place is visibly empty. The comparison does not invent a visitor history.

## What the ledger counts

This placement opts into `visitor_record:true`. Its fields give the Assembly Laboratory, UTC save time, joints displaced by more than 0.01 m from their starting positions, twelve retained connections and persistence state. Its counter counts completed changed releases. Moving a joint away and back can increase released edits while decreasing the number of displaced joints. Standing still adds neither. All fields retain their text contrast; they are parts of one record, not ageing entries.

Other ledger placements retain their existing illustrative, timed examples. Reconfiguration preserves externally attached museum children.

Revisiting Assembly restores the released pose when its source hash and joint names match the current assembly, ready to edit again. The final gallery can reconstruct an older saved comparison using its included geometry even if the catalogue later changes. No undo history, path recording, identity attribution, new-joint operation or connection editor is supplied by this pass.

## Verification and next question

The private rendered museum run checks real record production, producer teardown, cache clearing and disk reload, reconstruction, revisiting, simultaneous held joints, invalid data, failed writes, empty state, legacy ledger behaviour and a selected continuous walking route. [Evidence and current chapter](../../../doc/book/iterations/2026-09-21-synthesis-return/index.html).

Headset readability, comfort, Quest performance and learner understanding remain unverified. A useful next experiment is to retain two alternatives or the hand's path: what questions become answerable when the record changes?
