from pathlib import Path
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-forces-relations'
(out/'DECISIONS.md').write_text('''# Forces: what the relation can carry

Applied 24 September 2026 to the first three canonical Forces chapters. [Read and compare](index.html#reading).

## Reading decisions

- **Vectors_Act1_WhatAVectorIs:** begin with both pins moving while the wall arrows stay fixed. Let relocation, direction and length become separate discoveries. Keep the world frame, the zero-vector convention, normalisation and its implementation threshold. The closing prepares two displacements meeting instead of repeating a general conclusion about information loss. 705 to 645 words, including code.
- **VFM_02_Operations:** preserve the cube, exchanged journey and out-and-back passage. Destination, displacement and travelled distance remain different accounts. Trim the button inventory and coordinate-conversion detour; keep the counter's reset because it directly changes what the journey means. 751 to 601 words.
- **Vectors_Act2_VectorArithmetic:** follow reversal, angular agreement, projection and leverage as distinct encounters. FRIEND is an actual angular classification; the critical question concerns the story attached to that number. Retain the possibility of another use for the pink remainder. Give the longer chapter three pauses. The final wheel remains a static geometric diagram, with a clear transition to time and initial velocity in Launch. 1,205 to 961 words.

## What stays available

All eight primary encounters and every routing marker remain in the same order. No artifact was removed or demoted. Their maps, artifact source, roles and sequence order are unchanged. The ten later Forces manuscripts are preserved.

Seven mathematical code blocks remain in the reading. The carriage's floor-to-scene conversion moves into its tutorial companion, where the full control steps, scales, speed, bounds and reset rules remain. The three tutorials also link to the complete original chapters. Existing field notes and older drafts are preserved.

The exact canonical edits are listed in [changed-files.json](changed-files.json). Before sources, after copies and exact diffs are retained in this folder. The reading page supplies a side-by-side comparison and the live comment link for each chapter.

## Source correction

The arithmetic intent, tutorial and critical note still described rpm. Current torque_crank.gd explicitly reports sin(theta), the chosen angle and a static wheel pose. Corrected those three stale descriptions; no torque code or behaviour changed. The normalization and preset thresholds are distinct (0.001 versus 0.0001); the companion now states both.

The relevant existing source was checked for common pin translation, subtraction/projection binding, route reset and prescribed travel, FRIEND's threshold, and the crank's unit-direction cross product. This was a focused source check for the wording, not another runtime audit.

## Publication and limits

Only the three affected core records' text hashes and local review links were updated. The current Forces capture was exported from all thirteen canonical chapters; the previous capture is retained by the exporter. A served copy lives in [capture/forces-book.md](capture/forces-book.md).

Preservation, marker order, mathematical-code retention, capture hashes, rendered HTML anchors and HTTP links are checked in [verification.json](verification.json). No new Godot image, runtime run or headset result is claimed. Browser visual inspection was unavailable because the trusted browser Node process could not start; HTTP checks establish served content and links, not visual acceptance. No frozen full-book, audio, live scene or bake rebuild.

## Next

Continue with VFM_05_Launch and VFM_03_Motion. Keep the distinction between assigning a velocity and applying a force, but begin with the body travelling and what happens after the initial instruction.
''',encoding='utf-8')
p=root/'doc/book/iterations/WORKING.md'
s=p.read_text(encoding='utf-8-sig')
entry='''**24 September — Forces: what the relation can carry.** [Three revised chapters and exact comparisons](2026-09-24-forces-relations/index.html#reading). Revised canonical Vectors_Act1_WhatAVectorIs (705→645), VFM_02_Operations (751→601), and Vectors_Act2_VectorArithmetic (1,205→961). Begin with the two pins moving while their wall relation stays; preserve the cube's journey despite zero displacement; distinguish reversal, FRIEND's angular threshold, the projection remainder and static leverage. Seven mathematical sketches remain in the reading; the floor-coordinate conversion and operating detail stay in companions. Corrected three stale rpm descriptions to the actual sin(theta)/static-pose display. All eight encounter tokens/order, maps, roles, source and the ten later Forces manuscripts preserved. Three core hashes/review links and the current Forces capture refreshed; before/after files retained. No new runtime/headset or visual-browser claim, scene change, frozen book/audio rebuild or commit. Next: Launch and Motion.\n\n'''
assert s.startswith('# Working method for the book and museum\n\n')
s=s.replace('# Working method for the book and museum\n\n','# Working method for the book and museum\n\n'+entry,1)
p.write_text(s,encoding='utf-8')
print('Decisions and work record saved.')
