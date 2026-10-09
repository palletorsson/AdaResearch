from pathlib import Path
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-launch-and-motion'
(out/'DECISIONS.md').write_text('''# Launch and Motion: after the first instruction

Applied 24 September 2026. [Read both chapters and compare originals](index.html#reading).

## Scope: targeted improvement

These halls already have working comparisons and a distinct critical question. Keep their encounters and strongest passages. The gap addressed here is reading pace: button inventories and display bookkeeping interrupted the flight and the persistence of motion. There is no evidence from this reading pass that these encounters should be removed or replaced.

## Launch

**Keep:** the visitor between the two lanes; a straight initial arrow producing a curve; equal range with unequal time aloft; zero vertical velocity with continuing acceleration; the different powers of a local model and the museum around it. The first paragraph and central observations are retained.

**Revise:** bring the ideal-flight assumptions beside the equality they support. Let walking beside the two paths raise the question of clearance before the equation arrives. Two pauses separate the flight, its construction and another beginning. The landing remains a deliberately unanswered impact question. 919 to 722 words, including code.

**Retain beside the chapter:** exact angle and speed steps, quarter-speed playback, reset switches, vector display scales, 64-segment prediction and analytic live sampling. These details remain in the existing tutorial and the complete preserved original. Both mathematical code blocks remain in final.md. No claim that an archway, obstacle or collision simulation has been added.

## Motion

**Keep:** the push ends while movement persists; COAST, BRAKE and RESET have different effects; mass changes response without changing silhouette; successive pushes meet a current velocity; the amber boundary recognises the cube but not the visitor; the trace does not retain the full past.

**Revise:** use the continuing body to connect the actions rather than enumerate controls. Give the collision boundary its own pause. Keep the small friction ramp's abrupt STATIC transition beside the larger chamber's gradual brake: this is a useful contrast and a possible development lead, not a prose error to hide. 1,087 to 943 words.

**Other drafts:** intent and critical.md already support this direction and are preserved. The old walked.md values the inquiry into causes but ends by attributing motion to what forces most recently decided. That would obscure inertia in the current encounter. A historical note now identifies it as an earlier draft; its original text remains intact. Exact force, damping, bounds, arrow scales, sampling and ramp travel factor remain in tutorial.md. Both mathematical code blocks remain in final.md.

## Source and images

Focused source checks: launch_chamber.gd supplies analytic positions, complementary angles, local time and a frozen landing state; motion_chamber.gd retains rigid-body velocity, applies requested force, restricts contacts, and distinguishes coast, brake and damping; friction_ramp.gd directly clears velocity in STATIC. Existing map metadata selects the chamber variants described in the chapters.

The page reuses launch_chamber_inside.png and motion_chamber_inside.png from doc/research/possible-bodies. Both were visually inspected through reduced in-memory previews after the normal image viewer failed its filesystem sandbox helper. Published image files are unchanged copies of the original PNGs. They show existing chambers with their explanations revealed; the Motion image shows a push in progress. They are not before/after images of this writing pass or new runtime evidence.

## Preservation and publication

All three primary encounter tokens, including the empty closing marker, retain their order. Maps, sequence order, artifact source, roles, intents and critical companions are preserved. The other eleven Forces chapters remain unchanged. [changed-files.json](changed-files.json) lists the five edited manuscript/companion files; originals, after copies and exact diffs are retained.

Only two core records' text hashes and local review links change. The current thirteen-hall Forces capture has been refreshed; the exporter preserves its previous version. [Verification](verification.json) checks versions, original snapshots, code and marker retention, the historical draft, image copies and served links.

No new runtime, headset, learner or performance test. No new artifact, placement, bake, frozen whole-book or audio export. The reading page is checked through its HTML and served content; visual browser inspection remains unavailable in this session.

## Next

Vectors_Act3_FieldsAndMotion. The body reaches each part of a field with a state already under way. Begin with its movement and distinguish an assigned velocity from an influence that changes it.
''',encoding='utf-8')
p=root/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig')
entry='''**24 September — Launch and Motion: after the first instruction.** [Revised readings, exact comparisons and existing native views](2026-09-24-launch-and-motion/index.html#reading). Selective canonical pass: VFM_05_Launch (919→722 words) keeps equal range/unequal time, the visitor inside the diagram and the unfinished landing; VFM_03_Motion (1,087→943) keeps the ended push, continuing velocity, body-specific boundary and friction ramp's abrupt STATIC cut. Four mathematical sketches remain. Exact controls, scales, sampling and reset details stay in tutorial companions. Intents/critical notes preserved; the earlier walked draft is retained with a historical note distinguishing its closing force claim from inertia. All three encounter tokens/order, maps, source, roles and eleven other Forces chapters preserved. Two core text hashes/review links and the Forces capture refreshed. Original native chamber PNGs inspected and reused unchanged; no new runtime/headset or visual-browser result, scene/bake change, frozen book/audio rebuild or commit. Next: Vectors_Act3_FieldsAndMotion.\n\n'''
heading='# Working method for the book and museum\n\n';assert s.startswith(heading)
p.write_text(heading+entry+s[len(heading):],encoding='utf-8')
print('Decisions and next-step record saved.')
