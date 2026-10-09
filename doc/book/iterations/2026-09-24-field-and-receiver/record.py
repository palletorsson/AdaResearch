from pathlib import Path
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-field-and-receiver'
(out/'DECISIONS.md').write_text('''# Fields and Motion: the arrow does not decide

Applied 24 September 2026. [Read the revision and compare originals](index.html#reading).

## Scope: a selective reading pass

The existing room already performs its central comparison: cyan assigns a field sample to velocity; pink adds it as acceleration to a velocity already present. Both sample the same spatial rule at their own positions. The source, placement, intent and critical companion support the chapter. This pass strengthens its reading rather than developing another artifact or changing the room.

## Keep

The opening approach and overshoot, the move from Motion's stored velocity into a spatial field, all three update equations, the receiver-supplied units, the uniform-field comparison, reversal without a reset, and the observation cutoff at the gold perimeter. All thirteen placed identities remain. VectorFieldFlow retains its primary role; the supporting collection is unchanged.

## Sharpen

The centre becomes somewhere to approach for one body and somewhere to cross for another. Pink's continued movement into a reversed field follows from retained velocity. Its apparent reluctance has a specific construction; complicated movement is not by itself evidence of freedom. This develops the critical companion's existing question about which movements a receiver makes possible.

Four stages now give the reader pauses: the encounter, what reaches the centre, changing the field, and the observation boundary. Exact gain cycles, sampling counts, display scales, numerical stepping and stall handling remain in tutorial.md and the preserved original. The units and equations stay in final.md. The closing leads directly to the following hall's air/water/honey comparison. Word count: 935 to 864, including code.

## Correct one claim about the trace

The original says a line alone cannot tell which body crossed the centre. With the coloured histories and marked origin, pink's extension beyond the centre can show that crossing. The revised passage instead follows the return drawing over an existing line: timing, repeated visits and current direction are not supplied by that static overlap alone. Both source and the existing native image support this narrower claim. It preserves the investigation of traces while giving the visible evidence its due.

## Other drafts and evidence

Read intent.md, critical.md, tutorial.md, summary.md, blurb.md, field_notes.md and the retained artifact catalogue. Their useful current distinction is between a spatial sample and how a body receives it. Historical field notes already identify the old equation of every field with force as superseded, and qualify the unrecertified weather claims. Those notes and the catalogue are preserved; this pass does not promote their old claims about wind moving the visitor.

Focused source inspection: field_receivers.gd's field_at, state-preserving parameter controls, advance, history drawing, display heights and exit cutoff; current map metadata selects that adapter. Neither receiver applies a force to the visitor or to a RigidBody3D. These are exposed numerical position/velocity updates.

The native field_receivers_inside.png is reused unchanged from doc/research/possible-bodies. It shows SINK paused at four model seconds, with the rule revealed and pink beyond the centre. Its reduced inspection preview was read in memory through the working image-reader fallback; the published PNG is an exact copy. No new runtime result or return-flight screenshot is claimed.

## Preservation and publication

Only final.md and its tutorial companion are edited in the hall. All primary/closing routing markers, source, map files, sequence order, roles, intent, critical and historical material remain. Twelve other Forces manuscripts are unchanged. Originals, after copies and exact diffs are retained; [changed-files.json](changed-files.json) lists the two manuscript files.

Only this room's core text hash and local review link change. The current thirteen-hall capture is refreshed; the exporter retains the preceding version. [Verification](verification.json) checks source preservation, original snapshots, equations, anchors, capture hashes, the image copy and served links.

No new artifact, runtime/headset, learner or performance result. No bake, frozen full-book, audio rebuild or commit. The reading page is checked through its HTML and served content; visual browser inspection remains unavailable in this session.

## Next

Vectors_Act4a_KineticForces. Begin with the three bodies slowing differently, then the visitor's optional passage and the return that cannot undo the earlier movement.
''',encoding='utf-8')
p=root/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig')
entry='''**24 September — Fields and Motion: the arrow does not decide.** [Current reading, exact comparison and existing native view](2026-09-24-field-and-receiver/index.html#reading). Selective canonical pass on Vectors_Act3_FieldsAndMotion (935→864 words). Keep the centre as approach/crossing, three update equations, receiver units, uniform comparison, reversal and observation cutoff. Corrected the trace claim: pink's crossing is visible in its extent; overlapping return travel does not by itself convey timing, repeated visits or current direction. Operating counts/scales remain in tutorial; intent, critical and already historical notes preserved. Primary/closing anchors, all maps, source, roles and twelve other Forces manuscripts unchanged. One core hash/review link and the current Forces capture refreshed. Existing native SINK image inspected and copied unchanged; no new runtime/headset or visual-browser result, artifact/bake change, frozen book/audio rebuild or commit. Next: Vectors_Act4a_KineticForces.\n\n'''
heading='# Working method for the book and museum\n\n';assert s.startswith(heading)
p.write_text(heading+entry+s[len(heading):],encoding='utf-8')
s=(root/'doc/book/iterations/2026-09-24-forces-relations/verify.py').read_text(encoding='utf-8-sig')
s=s.replace('2026-09-24-forces-relations','2026-09-24-field-and-receiver').replace("maps=['Vectors_Act1_WhatAVectorIs','VFM_02_Operations','Vectors_Act2_VectorArithmetic']","maps=['Vectors_Act3_FieldsAndMotion']").replace('six allowed fields','two allowed fields').replace("'remaining_forces_manuscripts_unchanged':10","'remaining_forces_manuscripts_unchanged':12").replace('Only three text hashes and three review links','Only one text hash and one review link')
s=s.replace('class Page(HTMLParser):',"assert sha(out/'images/field_receivers_inside.png')==sha(root/'doc/research/possible-bodies/field_receivers_inside.png')\nclass Page(HTMLParser):")
s=s.replace("'native_runtime':'not run; source and placement unchanged'","'existing_native_image':'visually inspected; unchanged PNG copy','native_runtime':'not run; source and placement unchanged'")
s=s.replace("'visual_browser':'unavailable: trusted browser Node process could not start in this session; HTTP content verified'","'visual_browser':'not performed; trusted browser unavailable in this session; HTTP content verified'")
(out/'verify.py').write_text(s,encoding='utf-8')
print('Decisions, next-step record and publication checks prepared.')
