"""Author this closing lesson deliberately; publishing never rewrites its sources."""
from pathlib import Path
import json, shutil, sys
R=Path(__file__).resolve().parents[1]
H=R/'commons/maps/Fractal_Synthesis'
S=R/'doc/book/studies/fractals-through-the-hands/Fractal_Synthesis'
P=R/'commons/artifacts/fractal_recipe_table'
assert '--write' in sys.argv
S.mkdir(parents=True,exist_ok=True)
for name in ['recipe.gd','point_body.gd']:shutil.copy2(P/name,S/name)
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```'
text='''# A rule kept

**Learning elements**

- Describe a construction with a seed, replacement rule and stopping condition.
- Pass named settings to a function; rebuild from the seed.
- Copy a recipe without linking its later edits to the original.
- Compare two results using the same scale.

## In the museum

The interval and block tree return in this last Fractals hall. Between their desks, a small black point controls a comparison table. Move it left, centre or right: each surviving interval keeps one quarter, one third or two fifths at **each end**. The middle is omitted. Both descendants are replaced again at the next cut.

The table starts with three cuts. Predict what changes before moving the point. Each choice still makes eight pieces, but their lengths and the gaps differ. KEEP, or the held trigger, holds your current recipe in the rose row. The dark row remains live. Change the fraction and compare. RESTORE returns the live row to what you kept. RESET returns only LIVE to thirds and three cuts. NEXT adds a cut, up to five; release the point before using NEXT, RESTORE or RESET.

This is a return to Cantor's replacement operation. The new work is to make its decisions explicit and keep one version while changing another. The table keeps one comparison during the current run. It does not save a file or send a drawing into another hall.

## Continue with the point and interval list

Use the prepared Endless Museum workspace. Save the two files below together and attach `recipe.gd` to an empty, unit-scale Node3D on its floor. The front is local +Z. Camera, light, player and installed XRTools are already supplied. PointBody is the unchanged small point from the preceding lessons; its complete file is included so the example has no missing dependency or named scene child.

The example makes its own point, two rows and labels. Move the point to choose a fraction; press its held trigger or Enter to keep. Run again to return to the initial recipe. The installed museum table uses this exact script with furniture and four nearby buttons; that adapter calls `advance()`, `keep_current()`, `restore()` and `reset_live()`. It ignores global Enter. You do not reconstruct the room or the block tree.

## Name what another call needs

The `recipe` dictionary groups three settings under names. `seed` is the familiar `Vector2(start, length)`, here `(0, 6)`. `fraction` says how much of each parent survives at each end. `steps` is the number of replacements. A dictionary packages these decisions; it does not prove they are valid. `build()` bounds the depth, and the replacement function requires a fraction strictly between zero and one half.

`replace_intervals()` makes a separate `next` array. For each parent it places one descendant at the original start and another at `start + length - size`. It never appends to the array it is reading. `build()` starts from the seed every time, replacing the current list once per step. Editing a setting therefore reconstructs the requested version rather than applying another cut to yesterday's result.

At three cuts, eight pieces survive. For quarters their combined length is 0.75 metres; for thirds it is about 1.778 metres; for two fifths it is 3.072 metres. The count alone cannot distinguish these constructions.

## Keep a recipe, reconstruct its result

`kept_recipe = recipe` would give two names to the same dictionary. A later edit through one name would reach the same object. `duplicate(true)` creates a separate copy. The fields used here are numbers and a Vector2; the deep-copy option also copies nested arrays or dictionaries if we add them later. It is not a universal copy of every possible resource.

KEEP copies the settings. `rebuild()` then constructs both lists independently. RESTORE also copies: after restoring, a new LIVE edit must leave KEPT alone. The rendered bars are disposable views; they are removed and drawn again without removing the point or changing the saved recipe.

Both rows use the same scale: one model metre represents 0.34 metres on this table. Neither row is stretched to fill the width. The readouts state the **model lengths**. A length written as six metres does not make this miniature six metres wide.

## Complete code

`recipe.gd` contains the replacement, copy, input and drawing. Its hand control offers the three declared fractions; the display is centred on the six-metre seed. Treat that framing as an explicit choice when developing another work.

__MAIN__

`point_body.gd` is carried unchanged. It supplies the sphere and collision shape, XRTools pickup and the museum's desktop-held query.

__POINT__

## Make another version

First KEEP the initial thirds recipe. Move the point to quarters. LIVE should retain eight pieces totalling 0.75 metres; KEPT should still show the thirds. RESTORE should recover the initial result. Explain why another edit after RESTORE must not change KEPT.

For an independent code change, change only the initial `recipe` declaration to four steps. Leave the six-metre seed, fraction and drawing untouched. Before running, predict sixteen pieces and a combined length of `6 * (2 / 3)^4`, about 1.185 metres. The supplied automated check executes that edited script as well as the printed version. It checks the calculation; your explanation is still part of the exercise.

## What goes into the next room

At the large interval desk, HISTORY and GHOST change what can be inspected without changing which intervals survive. At the tree, FORM, STRATA, REACH and ENDS give different readings of the same branches. At this table, changing the retained fraction changes the generated intervals themselves. State which kind of change you made.

Carry the **thirds rule** into the next grammar laboratory. Its Cantor preset rewrites `F` as `FfF` and `f` as `fff`: uppercase draws a step, lowercase advances without drawing. After the same number of rewrites, that reading gives the same relative intervals. The lab fits its drawing to its display; compare normalized positions, not its apparent size. Quarters and two fifths are different recipes and do not follow from those same two rewrite rules.

We will build the general rewriting process there. Here, finish by naming the seed, operation, stop and display choices clearly enough that another reader could reconstruct your version.
'''.replace('__MAIN__',code('recipe.gd')).replace('__POINT__',code('point_body.gd'))
(H/'tutorial.md').write_text(text,encoding='utf-8')
p=R/'doc/book/course/execution-plan/plan.json';plan=json.loads(p.read_text(encoding='utf-8-sig'))
row=next(r for r in plan['lessons'] if r['id']=='Fractal_Synthesis')
row.update({'object':'A PointBody choosing a retained fraction; live and kept interval recipes on one comparison table.',
 'change':'Rebuild a known interval replacement from named settings; keep an independent recipe and compare one changed decision.',
 'dependsOn':['Fractal_CantorSet','Fractal_GoldenSpiral'],
 'reuses':'Unchanged PointBody; arrays of start/length pairs; current/next separation; loops; functions; BoxMesh and shared display scale.',
 'given':'Prepared museum player/camera/light/XRTools; complete carried PointBody; common miniature scale; existing interval/tree views and held collection.',
 'later':'General symbolic rewriting belongs to LSystems_Grammar_Lab. No new tree reconstruction, disk persistence or imported cross-hall drawing.',
 'checks':['Each of three fractions gives 2^n pieces and total length 6*(2*f)^n for n=0..5.', 'KEEP and RESTORE copy settings; later live edits preserve kept recipe and reconstruction.', 'Actual XRTools supplied hand pose chooses fraction; trigger keeps; reset/next/restore refuse held edits.', 'Exact printed four-step variant produces sixteen pieces and 32/27 metres.', 'Thirds positions match the next laboratory Cantor preset after normalization.'],
 'transfer':'Change only initial depth from three to four; predict count and total, run and explain independent copies.',
 'carry':'An explicit seed, operation, stop and reader; thirds become the next hall’s F/f Cantor grammar.',
 'next':'LSystems_Grammar_Lab: rewrite a sentence before reading it as movement.',
 'notes':'One local comparison only; KEEP replaces the previous snapshot and is lost on reload. Gallery and original generators remain independent.',
 'summary':'Between the existing interval and tree desks, move the familiar point to retain a quarter, third or two fifths at each interval end. Reconstruct the known replacement from a seed, named settings and a bounded loop. KEEP copies one recipe into an independent comparison, while LIVE can change; both are rebuilt and drawn at the same scale. Predict and execute a four-cut variation. Distinguish changing a generating rule from changing a view, then carry the thirds construction into the next laboratory’s F/f rewriting rule.'})
p.write_text(json.dumps(plan,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Wrote Synthesis tutorial, exact study files and one plan row.')
