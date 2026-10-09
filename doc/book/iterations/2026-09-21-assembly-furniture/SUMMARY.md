# Assembly: a chair has legs too

Added three independently grabbable physics studies alongside the previous human ragdoll and gold editable body. They use the existing Chair, Table and Lamp names, node positions, masses and connection lists from assemblies.json. Explicitly fitted panel orientation, thickness, leg lengths and colliders make these furniture rather than scaled clusters of catalogue markers. The existing catalogue and assembly source file are unchanged.

AssemblyFurnitureStudy.gd inherits the unchanged ragdoll grab targets, bounded spring force, elastic tether and reset path. Fifteen new rigid parts have twelve structural pin joints. Initial support pins hold each part's centre in an authored pose, shown by thin wires. First grab removes every staging support for that object; structural connections remain free to turn. Release leaves gravity and contacts to settle it. Each REASSEMBLE control acts locally and refuses while held. The lamp's bulb carries its light after collapse. Furniture does not write to the saved gold-body pose.

## Checked in the actual museum

70 interaction/physics checks pass, including the human ragdoll regression, source graph counts, desktop ray selection and carry, movement transmitted to a neighbouring part, free physical bodies, bounded joint separation at the sampled drag states, reset refusal, falling/settling, reset recovery, synthetic two-controller XRTools grabs and unchanged gold/save state.

| Object | Physical parts | Structural joints | Neighbour moved during checked pull |
|---|---:|---:|---:|
| Chair | 6 | 5 | 0.460 m |
| Lamp | 4 | 3 | 0.933 m |
| Table | 5 | 4 | 0.330 m |

Nine selected continuous walking segments pass: entrance, chair approach, table approach, central passage, lamp approach and exit. The new stations are at map coordinates Chair (3,2.3), Table (8.7,2.3), Lamp (9.2,9.8). The automatic sculpture exclusion covers their work area. No hall expansion or removal of an existing primary was needed.

Godot exits 0 with no script errors. The existing unrelated UID/environment/dressing warnings remain in the log. Nine state captures and a hall overview are saved; the main before/after states were visually inspected. Captures show controlled states of the same new implementation, not a human session. No headset, comfort, haptic or Quest-performance claim is made. These pin-jointed props are not ordinary welded furniture or promised player seating.

The entire preceding manuscript encounter is preserved. A short addition follows the human ragdoll into the chair, table and lamp: the distinction between an outline, a connection and a familiar use. The lamp's continued light makes one omitted consequence visible. Exact diffs, baseline copies, source manifest and current input hashes are saved here. Map description/notes were clarified after capture without changing the tested placement, structure or flags.

No live game restart, live bake replacement, visitor-save write or commit. The frozen full-book packet for Claude remains unchanged. Collective Knowledge is still separately parked; see ../2026-09-21-commons-restoration/PENDING.md.
