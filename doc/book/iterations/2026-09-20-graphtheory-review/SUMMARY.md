# Graph Theory: what an early choice makes possible

20 September 2026. A bounded continuation after Machine Learning. The eight-hall order holds. Six chapters remain byte-for-byte unchanged; Matching and Flow receive focused revisions. No artifact family or role is removed.

The sequence moves from visiting a graph, to drawing it, changing a route, measuring importance, finding a return, removing redundant connections, managing limited capacity, and choosing partners. Each step changes the question asked of a connection. The final comparison now makes one of the book's arguments available to the visitor: a valid local choice can still close off a better arrangement.

## Decisions by hall

| Hall | Decision and reason |
| --- | --- |
| Foundations | Preserve the chapter and its two travellers. Different traversal orders on the same graph give the sequence a concrete beginning. Delaying the algorithm names is a later reveal-timing task. |
| Layout | Preserve the chapter's distinction between a connection and its drawn position. A repeatable SAME GRAPH / NEW START control remains a useful development task. |
| Pathfinding | Preserve the stone-removal encounter and prose. Follow up on the spark's jump/restart behaviour separately; this pass does not certify its continuous journey. |
| Network Analysis | Preserve the chapter's question about evidence for importance. Its displayed measures still require implementation work; a computed-degree comparison is the clearest next addition. |
| Connectivity | Preserve the directed return-path question and Tarjan encounter. It provides the reason that removing a cycle in the next hall may also remove something valuable. |
| Spanning Trees | Restore the missing authored hall and place the existing graph above the floor, facing the entrance. Fix the startup reset that disabled computation. Suppress the desktop overlay/base/axes only for this museum placement. Preserve the manuscript. |
| Flow | Keep the funnel and every existing artifact. Refresh the stale museum placement, raise the primary graph to 1.2 m, and make the forward-only study's stopping condition visible. Revise two paragraphs around the blocked junction and the possibility of undoing an earlier allocation. |
| Matching | Restore the missing authored hall. Use the existing five-cycle with five outer spokes; add ORDER, RESET, RUN / PAUSE and STEP controls. The same connections yield three pairs when cycle edges come first and five when spokes come first. Replace the proposed experiment with an encounter the visitor can perform. |

## Encounter changes

Matching begins paused. RESET repeats the selected scan order without moving vertices or changing connections. ORDER clears the previous matching and selects the other order. It is still a greedy matching study: it does not implement Edmonds' augmenting paths or blossom contraction. The registry and display stop calling every result a maximum. An independent exhaustive search confirms five as the maximum for this particular ten-vertex example. The manuscript preserves the distinction between pair count and consent, suitability or fairness.

Flow now stops at a junction with excess and no outgoing capacity instead of repeatedly attempting the same impossible forward step. The blocked excess remains visible. The readout reports receipt at the sink; it does not certify maximum flow. Restart clears preflow state instead of accumulating it. A full reverse-residual comparison remains a development task. This is a partial allocation study, not a completed maximum-flow implementation.

Spanning Trees reset its algorithm state after setting `is_computing`, which immediately switched computation off. Reversing that initialization order restores timed decisions. The placement is now scaled to 0.4, lifted 3.6 m, and turned towards the approach so vertex and weight labels face the visitor. All vertex spheres clear the floor. Its existing label density still deserves a later readability pass; VR hand controls for it are not added here.

Spanning Trees and Matching now have bounded 15 by 17 m galleries, central primary encounters, entry/exit openings and clear perimeter routes. Flow retains its existing 13 by 12 m floor plan and supporting artifacts. A runtime capture exposed obsolete wall speech claiming maximum flow; the Graph Theory speech and heroes were synchronized from the book into both authoring and shipped trunk data, preserving other chapters and the existing token/routing edits.

## Evidence and limits

- [26 controlled model checks](model-checks.json): real Matching button signals, three-versus-five comparison, unchanged graph, reset/repeat, initialization ordering and no duplicate controls; MST timer progression and Prim/Kruskal total-weight agreement on one graph; Flow restart, blocked state and quiet stopped callbacks.
- [26 navigation checks](navigation.json): the production selector visits all eight halls in declared order and advances correctly. This does not simulate walking through every portal.
- Actual museum captures and collision-body probes: [Matching](GT_Matching-runtime.json), [Spanning Trees](GT_Spanning_Trees-runtime.json), [Flow](GT_Flow-runtime.json). Both restored halls load their primaries; selected approach/perimeter paths pass. Matching control centres are at approximately 0.93 and 1.2 m. Spanning Trees and Flow include explicit above-floor vertex checks.
- [Preservation and integration checks](content-checks.json): six manuscripts and five maps byte-preserved, all original artifact families and roles retained, eight-hall authored/derived order, current book/core references, scoped registry changes, synchronized wall speech, and unchanged unrelated plan/trunk entries.
- [Exact manuscript diff](final.diff), [frozen input hashes](before-sha256.json), [before/current hashes](current-inputs.json). The before files preserve this pass's starting working copy, not an assumed Git baseline.

The paired Matching pictures show two states of the revised artifact from the same museum camera. They are not before/after software versions. Spanning Trees and Flow pictures show current museum placement. No headset use, tracked-hand reach, continuous portal traversal or learner understanding is claimed. The live museum was not restarted or rebaked, and no headset deployment or Git commit was made.

Godot reports existing UID/certificate-store messages and render-cache write warnings in this environment; selected probes complete successfully. Derived whole-museum builders also report existing grid-size discrepancies in six Wavefunctions, Randomness and Noise maps, including five placements outside Random_Space_Geometry's floor. Those maps are unchanged by this pass. These reports remain separate from the successful Graph Theory checks.

## Next

Continue to Foundations Crisis. Matching leaves a useful distinction at its door: satisfying a local rule does not prove the strongest conclusion someone attaches to it. Read what is already there before adding explanation. The Graph Theory follow-ups above remain encounter tasks; they are not reasons to cut the preserved chapters or repeat this whole pass.
