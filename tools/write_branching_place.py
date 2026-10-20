from pathlib import Path
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/PG_Branching_Growth';S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Branching_Growth';O=R/'doc/book/iterations/2026-10-09-branching-record-and-place'
def code(name):return f'<!-- student-code:{name} -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
text='''# Branching Growth — a record and a place

## Learning elements

- Search for one nearest unreached target
- Retain the chosen target and parent indices
- Separate a record count from a position count
- Change whether a parent may act again

Keep the eight-point field from Space Colonization. There, each request chose a site, and that site combined its assigned directions. Here each active site chooses one nearest target. The relation has changed before a single branch appears.

## Look before pressing STEP

At the existing museum desk, RESET turns variation off. The root is at (0, 0, 0). Its nearest target is entry 0: (−2, 1.5, 0), 2.5 metres away. Normalize that displacement and take a half-metre step. The first child should be (−0.4, 0.3, 0). Press STEP and check the leftward lean.

Press STEP again. The root is still active. It creates another child at (−0.4, 0.3, 0), while the first child advances to (−0.8, 0.6, 0). We now have four records, including the root, but only three distinct positions. A second record need not add a new place.

## Rebuild the operation

Use the prepared Endless Museum. Save the three complete files below together and attach `branches.gd` to an empty Node3D at unit scale in your working copy. The test installation uses the gap before the old rear structure: hall-local (8.5, 0, 21), yaw 180 degrees. The existing player, camera, floor and XRTools remain our host.

The point is the same one we held in the previous hall. Its held trigger, or SPACE, advances once. T advances ten times. H keeps a specimen; R resets growth while retaining it. Moving the point alone does not grow a branch. The drawing remains a 0.4-scale miniature; a numerical half-metre edge appears as 0.2 metres. It supplies no floor or branch collision.

### Keep the choice in the record

The eight coordinates are unchanged. `reached` has one Boolean for each target; the target list itself stays in place, so its indices remain meaningful. A node keeps its position and parent, as before. We add `target`, the index chosen when this node was made, and `active`, whether the node may respond on another step. The root has no parent or chosen target, so both indices are −1.

`nearest()` scans the unreached points. It starts with a maximum distance of eight metres and replaces the choice only when it finds a closer one. A point exactly eight metres away is excluded. Equal distances keep the earlier entry in the list. A result of −1 means no eligible target was found; it is not a target index to draw.

`step()` reads the existing nodes, collects children separately, then appends them. A new child waits until the following generation before it can choose a target. The chosen index is written into the child, alongside its parent index. We can now ask both where a branch began and what it was answering.

'''+code('growth.gd')+'''
This follows the installed opening with jitter and pulsing off. Notice its order: it proposes a child first, then tests the parent's old distance from the target. If that distance is strictly less than 0.32 metres, it retires the parent and marks the target reached after the pass. It does not snap the child to the target or remove the target before other sites have read it. At an exact match, the normalized displacement is zero and a coincident child can still be recorded. Those are properties of this implementation, not requirements for every growth algorithm.

Most parents remain active after making a child. That is why the same parent and target may produce the same position again. `distinct_count()` uses positions as dictionary keys, matching the desk's exact-coordinate count. It does not merge approximately equal positions or certify visibly separate branches.

The 192-record budget includes duplicates. Once it is reached, another step changes nothing. The learner model omits the installed jitter, pulse and random colour draws to isolate the nearest-target operation; it does not reproduce those optional variations.

### Draw what the record can tell us

These are the same sphere, cylinder and label helpers from Space Colonization. A line from the first active site to its selected target shows one current decision. The white segment previews its next step. The caption also names the parent and target of the last stored child. A preview and a historical record describe different moments.

HOLD deep-copies the node records and draws a smaller witness. It keeps the selected target indices, but this witness is not a saved simulation: it does not carry the current reached flags or a clock. The installed desk keeps a mesh witness instead. Both let us compare an earlier form; their records are different.

'''+code('branches.gd')+'''
### The carried point

`point_body.gd` is unchanged from Space Colonization. The host connects its action to STEP. Reuse it without adding a new grab system.

'''+code('point_body.gd')+'''
## Retire a parent after it grows

Run two steps first. Read four records and three positions; inspect the parent and target indices of the coincident children. HOLD, then RESET.

Now add `branch.active = false` immediately after the `additions.append(...)` line in `growth.gd`, at the same indentation. Keep the existing near-target check. Predict the second step before running again: the root no longer answers twice. There will be three records and three positions, with the new child attached to the previous child.

Request ten steps in both versions. Compare the counts and the retained specimen. From this single root, the edit makes a chain, since each site retires after its first child. It does not establish a general rule that no two sites may occupy the same position. The change is permission to act again, not geometric deduplication.

Explain the relation to the previous hall. Space Colonization changed which sites could receive several requests. Here we changed the lifetime of a site that selects one request. The same word, branching, was insufficient to tell us either rule.

## Return to the installed comparison

The museum's VARIATION button enables jitter and pulsing and resets the field. These can separate paths and vary edge length. They remain supplied behaviour in this lesson; they are not hidden prerequisites for the printed program. RESET turns them off again, while the held mesh stays.

Look at Organic Space nearby. Its shells and tunnels offer another account of an organic appearance. Keep that encounter alongside the tutorial without mistaking resemblance for a shared construction.

Carry the parent and target records, and the habit of checking what a count actually counts. In Percolation, the next hall, connectivity becomes the question: under a stated rule of contact, what can reach what?
'''
(M/'tutorial.md').write_bytes(text.encode('utf-8'))
final=(O/'before/commons/maps/PG_Branching_Growth/final.md').read_text(encoding='utf-8')
start=final.index('The running program searches');end=final.index('That direction receives')
final=final[:start]+'''Each active site answers one nearest unreached point. Other invitations remain in view without entering this particular direction. In the previous room, requests met in a sum. Here selection lets one of them lead.

'''+final[end:]
(M/'final.md').write_bytes(final.encode('utf-8'))
print('Three complete files printed; one code excerpt moved from reflection into tutorial.')
