# Lambda — the recommendation can move

20 September 2026. Fourth bounded laboratory pass.

## Findings and decisions

The mature main manuscript already made the useful distinction: the green route is a curatorial recommendation, not a discovered interval in which life occurs. Its opening and argument are preserved exactly. The proposed experiment at its end is now something the visitor can do.

Previously lambda_value simultaneously moved the light, displaced rows to clear it and changed their colour/emission emphasis. The new optional recommendation_control:on adds a LIT STRIP slider and RETURN button. They move only a parent containing the luminous floor strip, edge strips and inscriptions. The surrounding forms, their colours, random seed and ongoing animation are independent of this action. RETURN restores the initial suggestion without rebuilding the hall. Floor labels now say SUGGESTED rather than “life walks here.”

The rail ranges from 0.20 to 0.80 to keep the 1.4 m strip inside the hall's kerbs. Those limits are authored, too. The light can slide beneath a visible cube; it does not clear a route or calculate walkability. The cube rows have no individual solid colliders, while the floor and side kerbs do. The technical note makes that implementation limit explicit.

The main manuscript now asks the visitor to compare two invitations: the one the hand can move and the one still built into the rows. That gives the QFEP question of revisable terms a specific action without making the text a technical checklist.

## Spatial restoration and retained work

The former hall anchor at (11,11) put part of the 7 by 14 m structure outside a 13-cell-wide map. The gallery is now 17 by 24, with the full-size artifact centred at (8,12), a clear entrance and side bays for the existing secondary works.

A runtime check exposed a second problem: an older stamped necklace overrode the current map and omitted the main artifact. museum.artifact_placement:map now makes the reviewed placements authoritative. A central sculpture-clear rectangle prevents automatically added sculptures from entering the experiment.

All ten artifact families remain in the map. Nine instantiate in the museum. bifurcation_walkway is still marked map_ready:false in its registry; it remains a named restoration task. Its physical and pedagogical relation to the current hall needs a focused follow-up rather than changing that global flag without review.

The retained dissolving_form failed shader compilation because its hash constructed a vec3 with four arguments and called fmod with one. The hash now uses fract of the three-coordinate dot product, and its interpolation uses fract(p) for the fractional cell coordinate. The final rendered run reports no shader compilation error.

Earlier technical and critical manuscripts describe unimplemented player-position coupling and treat a green band as evidence of life. They are retained verbatim in the map's historical design-proposals.md, with their status marked. Current supporting notes describe the actual controls and preserve the questions about orientation and architecture as persuasion.

## Evidence and limits

- [Exact main manuscript diff](final.diff), [technical diff](technical.diff), [critical diff](critical.diff).
- [Rendered museum report](QFEP_Lambda_Spectrum-runtime.json): 28 checks and six walks pass. Tests compare actual MultiMesh transforms/colours, materials, drifter state, control identity, labels, clamp bounds, RETURN, default placements and a selected standing reach point.
- [Final-source headless report](QFEP_Lambda_Spectrum-headless-runtime.json): the same 28 checks and six walks pass; [Godot exits 0](headless-process-result.json).
- [71 integration/preservation checks](content-checks.json): all ten map families retained, seven other maps and manuscripts byte-preserved, unchanged sequence order and other plan rows, book/core/trunk speech aligned.
- Five actual Godot captures: [left recommendation](recommendation-left.png), [right recommendation](recommendation-right.png), [return](recommendation-return.png), [entrance console](lambda-console.png), [gallery](lambda-gallery.png).

![Entrance console and full-size Lambda hall](lambda-console.png)

The rendered process saved a passing report and all images, then terminated with Windows code 3221225477 (0xC0000005). An earlier run timed out after writing its passing report. The shutdown cause is unresolved; these captures do not establish stable rendered lifecycle or continuous gameplay. Final source also defers control construction until the configured instance is in the scene tree and avoids rebuilding on identical settings. The independent headless process exits cleanly. Capture images precede that lifecycle-only guard; the visual construction and interaction behaviour are the same.

The rendered pair holds the primary artifact's animation at the same instant for a controlled comparison. Normal animation independence is checked separately. These are desktop signals and controlled collision walks, not tracked-hand use or a study of visitor preference. Headset reach, reading comfort and learner understanding remain pending.

Known UID/certificate/renderer warnings remain. The route generators repeat six unrelated map-layer dimension warnings. No live museum restart, live bake replacement or commit was performed.

## Next

QFEP_Phi_Term: giving change a sign. Inspect what crossing zero actually changes in its controls and text, while carrying the question of who defines and weights the change being counted. The disabled bifurcation walkway and rendered-process shutdown are separate follow-ups; Sandbox remains the laboratory's missing authored hall.
