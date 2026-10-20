# Following a part — ghost eye-view playtest

16 October 2026. [Open the paired hall review](index.html). Run the prefab `preview.tscn` with F6, or use WATCH at the installed Random_Entropy prefab bench. This work remains local; this request did not ask for a commit or publication.

## Experiment and findings

The old nine-action rehearsal tested controls but mostly looked at the right table. This revision keeps those actions and changes their observation: inspect both copies at stage 0.5 without changing the arrangement, then follow the CRT screen continuously as the right-hand parts join. The joining movement takes six seconds at ordinary playback speed. KEEP retains stage 0.82 after a seed change; ORIGINAL and another seed change precede REPLAY.

The first renders exposed a small part easily lost among other pieces, cropped head text and a standing position too close to the entrance wall. The resulting changes are FOLLOW PART (optional gold frame and source/destination label), held comparison pauses, a slower joining action, a standing position 20 cm farther from the wall, and revised outside framing. The screen's materials, geometry and saved assembly remain unchanged. Annotation labels render over occluders so a wall does not erase half a quotation; the eye camera omits that layer entirely. Source excerpts and authored questions are also printed beside every pair in the review.

At the hybrid endpoint the marked screen can be thin or edge-on, and other geometry can obscure it. The marker establishes retained identity, not successful recognition or a functioning monitor. This is a useful next question: compare the same route with the marker off and record where the relation becomes unclear. The tutorial now specifies that comparison, reversal, intermediate KEEP, altered conditions, REPLAY and a versioned rule change after reconstruction. The 48-value seed bench remains the first research pilot. The main six-stop room/final order stays intact.

## Continuing to the next encounter

After completion, the ghost restores the starting prefab state and walks to the Shannon ledger, about 5.86 metres in the tested room. This is the main route's first instrument. A bounded A* grid uses five nearby floor probes and a 0.22 m clearance capsule; each connecting segment and each movement is checked. Exact tile-edge ray normals initially made seams appear impassable. Requiring three supported nearby samples fixes that case while rejecting absent floor and obstacles. The method uses Godot's [AStarGrid2D](https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html) and [PhysicsDirectSpaceState3D queries](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate3d.html).

Arrival shows the next actual view and question. It does not press the ledger's controls; that adapter is a next task. Missing destination, changed obstruction, manual cancellation and scene exit stop the continuation. There is no teleport fallback. Starting WATCH explicitly begins another prefab rehearsal. The standalone scene reports that it has no next artifact.

## What is recorded

Eleven paired eye/outside checkpoints cover the prefab; the twelfth records the ledger arrival. Each pair includes the same-frame artifact state, head/camera transforms, settings, image hashes, gaze target, source part key, current transforms/group, text excerpts and source checksums. A projected centre inside the frustum is a numerical check only; occlusion and readability were inspected in the native images. All preview snapshots reconstruct in a fresh instrument. The arrival's artifact record is the restored prefab baseline, explicitly labelled as such; it is not a saved ledger experiment.

The text stream contains authored questions and literal excerpts from tutorial.md/final.md. It does not expose an AI's private reasoning or claim to report a learner's consciousness. Missing excerpts display a review notice; the existing required procedural guards still block a rehearsal when their source text disappears. The ghost's pointer/collection remain separate from the visitor's. Visitor control input ends the demonstration immediately without rolling back their change.

## Verification

- `run.py` / `verify.gd`: isolated apparatus, identity cue invariance, both-table comparison, tracked-part frustum checks, source excerpts, saved replay, fresh-instance reconstruction and visitor takeover.
- `museum_probe.gd`: the actual Random_Entropy room, all nine controls, twelve paired checkpoints, completed route, floor seams, absent floor, blocked destination and cancellation. **49/49**, native exit 0.
- `regression.py`: the earlier rehearsal suite is copied here and run without overwriting its historical receipts. It covers human save isolation, failed control, stale text, manual stop, native pointer takeover and cleanup.
- `route_probe.gd`: retained diagnostic for the initial floor-support issue. The route has also passed as part of the complete hall test.

Run:

```powershell
python -X utf8 doc/book/iterations/2026-10-16-ghost-prefab-playtest/run.py
python -X utf8 doc/book/iterations/2026-10-16-ghost-prefab-playtest/regression.py
python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag ghost-prefab-playtest --probe doc/book/iterations/2026-10-16-ghost-prefab-playtest/museum_probe.gd
python -X utf8 doc/book/iterations/2026-10-16-ghost-prefab-playtest/publish.py
```

Native scripted observation is evidence of these state changes, images and route checks. Independent human reconstruction, headset tracking/contact/haptics, comfort and Quest performance remain untested. A more readable demonstration can still prescribe too much. Next trial: let a person interrupt, hide the marker, and choose a different part or refuse the proposed continuation. Retain that difference before extending the ghost to another apparatus.
