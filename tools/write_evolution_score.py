from pathlib import Path
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Genetic_Evolution'
M=R/'commons/maps/PG_Genetic_Evolution'
O=R/'doc/book/iterations/2026-10-09-evolution-what-the-score-reads'
def block(name):return '\n<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
t='''# Genetic Evolution — what the score reads

## Learning elements

- A candidate record and its visible body
- An evaluation function with a declared criterion
- Ranking without changing the candidates
- Stable identity and changing rank
- A held copy and an omitted feature

Living kept a design record. Shape Grammars built a family without ranking it. Assemblage separated a record from its interpretation. Here one reader builds a body and another assigns its score. Our new operation is evaluation: what does this particular function notice?

## Begin with the existing six

At the museum desk, press RESET. Choose a box you want to keep before reading its score. HOLD keeps the numerical leader, which may be different from your choice. TARGET changes 8 to 16. The six descriptions remain; their ranking changes. The generation is still zero.

At target 8, the scale-1 box leads. At target 16, the scale-1.25 box leads, with estimate15.625 and score about72.73. RING adds a visible loop without changing the score. The builder knows this part; the estimator omits it. RULE exposes that difference.

## Reconstruct the comparison

Keep the prepared Endless Museum, floor, camera, player and XRTools. Put these three files together; attach `selection.gd` to a unit-scale Node3D in your working copy. The small study fits in the gap after the large candidates at hall-local(9.5,0,16.8), yaw180 degrees. It is a temporary learner installation. Its figures are miniatures at0.38 scale; the data and estimates retain the original candidate units. They add no collision or support surface.

The familiar point's held trigger changes TARGET. Moving it alone edits nothing. Keyboard T changes target, G toggles the leader's ring, H holds the leader and R restores the opening candidates. The installed desk remains available for the same comparison and for STEP; this compact program does not reproduce offspring.

### Describe, evaluate, order

`evaluator.gd` starts with six independent records. An ID names a candidate within this comparison. Its genes describe shapes in local coordinates. Position, rotation and scale are the same fields we have used before.

`estimate()` deliberately reproduces the installed estimator, including its factor eight for boxes and absent torus. It sums contributions; it does not measure the union of overlapping solids. The extra sphere and cylinder branches show what else the source counts. Only boxes and rings enter our bounded reconstruction.

`score()` compares the estimate with a target. Absolute difference treats one above and one below alike. Dividing100 by one plus that difference gives100 for a match and50 at distance one. The function returns a number; it neither constructs geometry nor edits a candidate.

`rank()` makes a new list of references and sorts that list. A shallow copy is enough here: sorting changes the list order, and the function does not mutate the records. For equal scores we choose the lower ID first; the installed kernel does not declare that tie-break. A saved witness needs a deep copy instead, because later edits can change its nested genes.
'''+block('evaluator.gd')+'''
### Keep the bodies while their places change

`selection.gd` builds each candidate once and keeps its node in a dictionary keyed by ID. TARGET calls `arrange()`: the existing nodes move to rank positions and their captions change. It does not rebuild their meshes. The pink finish identifies the current leader; it contributes nothing to the score.

RING changes one genome, so only that body's geometry is rebuilt. HOLD deep-copies the leader and builds a separate witness. RESET restores the six candidates and target8 but leaves that witness alone. IDs stay attached to our fixed candidates; a rank is a temporary position in an ordered list. The installed reproduction routine assigns new IDs each generation, so those IDs are not a record of ancestry.

Every new mesh, label, event and data operation is below. The museum supplies the surrounding world. The display scale is applied to each visual parent, outside the genome; changing it would change the miniature, not its score.
'''+block('selection.gd')+'''
### Carry the point

This is the unchanged point from the preceding halls. Its body, collision and pickup behaviour are already familiar. Here the connected action means TARGET. The host parks it after release; no new grab system is hidden in the example.
'''+block('point_body.gd')+'''
## Predict, then change one line

1. Start at target8. ID1 leads: its scale is1, estimate8, score100. Press T. ID2 now leads at target16. Check that all six gene records and mesh instances are unchanged.
2. Hold that leader. Add its ring. The visible part count changes, but its estimate and score do not. Change target and reset: the held record stays independent.
3. In `estimate()`, change only the box contribution from `s.x*s.y*s.z*8.0` to `s.x*s.y*s.z`. Run the complete edited program from its opening. Which candidate should lead now?

The answer is ID5, scale2: its product is8, matching target8 for a score of100. The original scale-1 box now estimates1 and scores12.5. No candidate needed new geometry for that reversal. Try target16 too: all six corrected box estimates are below16, so the largest still leads.

For these isolated unit boxes, the new term is their volume before display miniaturisation. It does not repair every estimate: spheres and cylinders still use their original coefficients, rings remain omitted, and overlapping contributions would still be added. Name the exact correction you made.

## Return to the installed generation

Leave the learner code and use the large desk. RESET, RING, then STEP. The source copies two elites and fills four places from parent tournaments, possible crossover and mutation. A tournament picks the best of three random draws with replacement. At the same target, elitism preserves a best score; it does not guarantee improvement. An elite can carry an uncounted ring onward. Survival does not show that every surviving feature earned points.

This reproduction kernel is supplied museum material in this lesson, not an unexplained call in your program. Its random offspring need not replay after RESET;50 generations is its limit. Your reconstructed operation is the evaluator and comparison which reproduction uses. Building a different selection or mutation mechanism would be another lesson.

Walk to the retained raised deck. Its collision supports you; the generated candidates do not. A good score says nothing about whether you can stand on a body unless the representation and evaluator include that test. The separate science screen is not a live genome readout.

Carry the distinction between a generated description, its visible body and a chosen criterion. In Space Colonization, targets become spatial points: we will inspect which growing site responds and how its requested directions combine.
'''
for a,b in [('estimate15.625','estimate 15.625'),('about72.73','about 72.73'),('hall-local(9.5','hall-local (9.5'),('yaw180','yaw 180'),('at0.38','at 0.38'),('Dividing100','Dividing 100'),('gives100','gives 100'),('and50','and 50'),('target8','target 8'),('target16','target 16'),('ID1 ','ID 1 '),('ID2 ','ID 2 '),('ID5,','ID 5,'),('is1,','is 1,'),('estimate8,','estimate 8,'),('score100','score 100'),('scale2:','scale 2:'),('is8,','is 8,'),('of100','of 100'),('estimates1','estimates 1'),('scores12.5','scores 12.5'),('below16','below 16'),(';50 generations','; 50 generations')]:
    t=t.replace(a,b)
(M/'tutorial.md').write_bytes(t.encode('utf-8'))
f=(O/'before/commons/maps/PG_Genetic_Evolution/final.md').read_text(encoding='utf-8')
a='''Here is the comparison in the running source:

```gdscript
var volume = estimate_volume(genome)
fitness = 100.0 / (1.0 + abs(volume - target_volume))
```

Subtract the target from the estimate. `abs` keeps the distance without its sign: being one unit above or below incurs the same difference. Adding one prevents division by zero. An exact match scores100; a difference of one scores50.'''
# Preserve the surrounding reflection; move its code explanation into the tutorial.
start=f.index('Here is the comparison in the running source:')
end=f.index(' This is what fitness means in this room.',start)
f=f[:start]+"The score reads distance from the chosen target. Being one unit above or below incurs the same difference. An exact match scores100; a difference of one scores50."+f[end:]
start=f.index('Even the counted box asks for another look:')
end=f.index('The renderer starts from a unit box',start)
f=f[:start]+'Even the counted box asks for another look. '+f[end:]
f=f.replace('scores100','scores 100').replace('scores50','scores 50')
(M/'final.md').write_bytes(f.encode('utf-8'))
print('Wrote complete tutorial and moved two code excerpts out of reflection.')
