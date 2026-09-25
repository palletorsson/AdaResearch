# Noise_Inside_Noise: revision decisions (2026-09-24)

## Verdict
Targeted revision. Three passages changed (four sentences rewritten, one clause added). No sentences added elsewhere. The chapter is otherwise source-true.

## Preserved
- The enclosure. The visitor steps through one opening into the sphere, and the museum shows through the other. It is a real room: a trimesh shell collider with two cut openings and a cylindrical floor collider (algorithms/randomness/noisesphere/enclosing_sphere.gd:31-40, 57-58, 74-81).
- All three code excerpts, verbatim (warp_study.gd:85-93, 98-99).
- The seeds paragraph (warp_study.gd:30-33), the amount-zero identity, and the four amounts (warp_study.gd:6).
- The yellow and pink point passage and the two-moments explanation.
- RELIEF kept separate from WARP. The enclosure keeps fixed geometry and collision through RELIEF: vertices are always CENTRE + d*RADIUS, and the shell collider is built once (enclosing_sphere.gd:77, 90).
- The x/z-times-three projection (warp_study.gd:115; enclosing_sphere.gd:91).
- The 65% unshaded enclosure (enclosing_sphere.gd:9, 68, 93).
- The 96x96 finite-sampling paragraph (warp_study.gd:7).
- The dark_sphere passage and the handover to Noise Space 10.
- The title, the questions, and all three `<!-- @ -->` anchors (count 3 before, 3 after).

## Changes
1. "Stay with one patch while the two bodies come to agree." became "Stay with one patch: the two bodies agree at once."
   Reason: the auditor and the re-checker agree this is overstated. zero_warp sets strength_index=0 and calls refresh(), which rebuilds both meshes, both plates and the dome in one synchronous call. Nothing animates, and the readout itself says "static until you act". Evidence: warp_study.gd:161-162, 101-122, 154.

2. "The base radius is 0.94 metres. In RELIEF, a signed sample changes it by up to 0.16 metres." became "The base radius is 0.94 in the scene's own units; they are metres only at the work's authored size, and the museum may build the whole work smaller. In RELIEF, a signed sample changes it by up to 0.16, about a sixth of that radius."
   Reason: the auditor and the re-checker agree this is overstated. The numbers are local (warp_study.gd:98-99). In the museum the enclosure's collider seals the route, and _hall_shrink_body tries scales of 0.8, 0.65, 0.5 and 0.35 (commons/scenes/endless_museum.gd:13956-13978). The one museum build on record logs "noisesphere seals 59 cell(s)" and "slid noisesphere to 80%" (ada_encyclopedia/captures/ada-run/inside-review-2026-09-13/Noise_Inside_Noise/engine.log:1391, 1413). The size is now given relative to the radius (0.16/0.94 = 0.17), which holds at any scale.

3. "Turn RELIEF off and keep WARP active. A changed colour arrangement survives on the round bodies." became "Press WARP, then turn RELIEF off. Both outlines return to round; a changed colour arrangement survives on the warped body."
   Reason: the auditor and the re-checker agree. WARP is a push button that steps strength_index, and ZERO has just set it to 0, so followed literally the old steps show two identical bodies. One press of WARP after ZERO gives 0.35 (warp_study.gd:6, 159-162). With RELIEF off, both radii are 0.94 (warp_study.gd:99). Only the warped sphere (k=1) reads at strength() (warp_study.gd:103), so only it keeps a changed colour arrangement.

## Left alone, and why
- The field-note claims ("no severing", "all original cells retained") and the local-unit sizes in technical.md are all in other files, outside this chapter and outside my write scope. The re-checker also showed the auditor quoting the wrong run for "no severing" (PID 11036 logged none), and that claim is not in final.md.
- Placed works the audit lists as ignored: the wp wedge and raised landing, and the refused an/sp/t utilities. These are utilities, not interactables, and their consequence at 80% scale comes from arithmetic, not an engine check. The legacy readout axis is unused here. Nothing verified does work the chapter should carry, so nothing was added.
- The book brief is already honoured. The chapter does not claim that random land is impossible to optimise or that a noise basis guarantees walkability.

## Limits
- I did not start Godot. The claim that the museum may shrink the body rests on the one 13 Sep build. map_data.json was edited on 14 Sep, and no later build is on record, so whether today's museum still shrinks the work to 80% is unverified. The new wording stays true either way.
- VR reach, comfort, and the 0.67 m threshold void at the east opening at 80% scale remain untested in a headset.

## Installed

`after.md` was installed to `commons/maps/Noise_Inside_Noise/final.md` on 24 September 2026, after an independent second agent checked every changed or added sentence against the code and its fixes were applied. Line endings: LF, as in the baseline. Where this record says `final.md` was not touched, it describes the candidate stage. The diff is in `text.diff`, and the hashes are in `HASHES.txt`: before `8462d0da760d…`, after `121a5664f996…`. No runtime or learner status changes, because the text changed and nothing new was walked.
