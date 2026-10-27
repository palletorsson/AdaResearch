# Animated Futures / body as a room

26 October 2026. Palle approved the five-version modular body score, then asked for space inside bodies large enough to walk into. The other five sketches and the main tower are retained.

## Inspect now

http://localhost:3003/lab-editor?mode=void&trial=chains_studies&floor=2

The Body futures panel opens on floor 2. It renders actual shared grammar geometry through the existing Three.js Builder. Use Look from inside, replay a version, select a named part, or offer a new placement as a branch. Return to floor resumes normal floor arrangement. The floor view replaces Lumen's static snapshot with the current recipe; other snapshots await re-export.

The six authored versions live in `commons/artifacts/chains_studies/futures.json`. The first five are a deliberate score, not discoveries made by an autonomous agent. The sixth is `room-within`, with a hollow beaded shell, a clear doorway, a flush interior floor and a light. It fits below the six-metre storey at the worker's existing 1.42 scale. A real player enters, stands inside and leaves it in both desktop and synthetic XR.

The request dock moves left on this floor to leave the entrance clear. Splice stands separately beside Lumen. Room poses are reset before the colliders enter physics and stay stationary. This avoids Jolt receiving a stretched sphere shape from an earlier animated pose. The room floor was made flush after the first native run found its raised lip blocked walking. Save comparison normalizes JSON numbers (Godot reloads integers as floats); native persistence writes full precision. These fixes were verified in a fresh passing run.

## One graph, two renderers

- `futures_graph.gd` validates named assemblages and resolves each connection's stable part IDs to the numeric ties that ModularBuilder currently consumes. Reordering/inserting a part therefore cannot silently connect a different limb. The shared builder/terms files are not edited.
- The matching bounded web interpreter is `ada_encyclopedia/src/lib/chains-futures.ts`. Both consume the same recipe document. Recipes use existing compose, assemblage, associate, mesh, body, collider and connect operators. This is a third body history; the tutorial track/lineage is not overwritten.
- The source grammar's ring layout rotates coincident copies. The body score uses explicit petal positions instead; the shared operator is preserved. Three.js torus tessellation/materials differ from Godot; the web view is a geometry preview, not a pixel or physics match.
- Parent recipe, grammar version, seed, proposer, recipient, approvals, result and outcome are recorded. A new Splice offer creates no body until accepted; declining logs the decision and leaves the recipe alone. Replaying another version while an offer waits does not move its parent.
- Local Windows desktop and web API share `D:/AdaGenerated/AdaResearch_46/state/chains-futures.json`, configured by `futures_storage.json`. A directory lock and atomic replace serialize writes; web writes additionally require a matching revision. A stale/crashed lock is not removed automatically. Tests override the path with `ADA_CHAINS_STATE_PATH`.
- Android/exported non-Windows builds use `user://chains-futures.json`; headset synchronization and a new Quest APK are not done. Existing game assets stay in Godot. Generated GLBs remain on D:.

## Evidence and remaining work

Completed: 175 native checks with mouse and synthetic XR input, including actual doorway entry and exit; 19 independent editor copy/move/turn/validate/save/reload checks; 13 actual Three.js geometry/history checks, including stable endpoints after reordering, an eye-height ray through the entrance and comparison with native persisted history; 5 local history API checks. Four GDScripts compile and shared room validation passes. The refreshed export contains 39 editable members and 88 actual GLBs on D:.

The first native queue timed out while Palle was playing. After he closed the game, native acceptance, export, a focused screenshot capture and mutable editor-save checks ran serially under the OS slot. The probe uses isolated history files; the real shared history is not its fixture. Initial failures and their logs remain under `evidence/failures/`.

The original main-tower rooms hash changed while another main floor-3 task was active. The trial never replaces that file: the main tower retains 209 floors and this trial eight. Historical and start/end main-room hashes are retained in `editor-checks.json`; global main-room preservation is not claimed. Model B, Point Zero, original Dream Bodies and the main layout match the editor run's baseline. Main-tower arrangements were not restored from an old snapshot.

Reproduce serially, when the human play slot is free:

```powershell
$env:PYTHONIOENCODING='utf-8'
python tools/test_transfer_native.py chains_studies
node tools/test_chains_futures.cjs --native
$env:VOID_EXPORT_RENDERER='mobile'
python tools/export_void_trial.py chains_studies
node tools/test_chains_editor.cjs
```

The passing receipts and real renderer screenshots were inspected. A concurrent authoring cleanup moved the top-level evidence outside Godot to `../ada_encyclopedia/public/void-trial-evidence/chains_studies`; the newest editor receipt and native front/interior views are published there too. The gallery is http://localhost:3003/void-trial-evidence/chains_studies/index.html. `body-front.png` avoids the pillar obstructing the older overview; `body-inside.png` looks out from inside. Local diagnostic originals remain in the ignored evidence/debug folder. Synthetic XR does not establish physical-headset comfort/performance. No new Quest APK or headset synchronization was done.
