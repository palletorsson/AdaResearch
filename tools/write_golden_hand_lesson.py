"""Install this authored lesson only with --write; subsequent publishing is read-only."""
from pathlib import Path
import sys,shutil,json
R=Path(__file__).resolve().parents[1]
H=R/'commons/maps/Fractal_GoldenSpiral'
S=R/'doc/book/studies/fractals-through-the-hands/Fractal_GoldenSpiral'
P=R/'commons/artifacts/golden_mapping_lesson'
assert '--write' in sys.argv
S.mkdir(parents=True,exist_ok=True)
for n in ['sum_points.gd','point_body.gd']:shutil.copy2(P/n,S/n)
def code(n):return '<!-- student-code:'+n+' -->\n```gdscript\n'+(S/n).read_text(encoding='utf-8').rstrip()+'\n```'
text='''# Two values, two views

**Learning elements**

- Numerical recurrence: add the previous two values.
- Append to an ordered array; retain its earlier entries.
- Pass the same record to two height functions.
- Detect one contact; release before accepting another.

## In the museum

Menger replaced each cube with a new generation. Here a new entry joins a record whose earlier values remain. At the first desk, two points carry the last two numbers. They begin at one and one. Predict the sum, then move one point against the other. Two appears in the row. Holding them together adds only once. Release both before asking for another sum; one hand can move a point to its resting partner. The held trigger also requests one step. NEXT, BACK and RESET stay beside you.

The points have the same size. Their labels carry quantities; their distance is only an interaction threshold. The new row on the left gives height a fixed unit. The row on the right compresses the larger values. Both read the same list. The large towers retain HEIGHT, SUM and RULE: SUM provides a fixed-unit witness of the last addition.

## Continue with the point and the cube

Use the prepared Endless Museum workspace. Save the two files below together and attach `sum_points.gd` to an empty, unit-scale Node3D on the floor of the workspace. Its front is local +Z. The museum supplies the camera, lighting, player and installed XRTools. This example creates its own points, labels and two rows; it needs no named scene children or dollar references. Keep your existing PointBody file if it is identical to the included version.

The installed artifact uses this same construction through a small adapter. Its values come from the existing Fibonacci desk, and adding calls that desk's NEXT. Your small script owns its list and computes each new value itself. The museum supplies the plinth and nearby buttons. You do not rebuild the surrounding helix, rectangle or player.

## Read two entries, append one

`values` begins as `[1, 1]`. Negative indices count backwards: `values[-1]` is the last entry; `values[-2]` is the preceding one. `advance()` reads both **before** appending their sum. The first request gives `[1, 1, 2]`; the next reads 1 and 2, giving `[1, 1, 2, 3]`. No earlier entry is replaced.

This is a recurrence: the next value depends on earlier values. The function does not call itself. Each gesture or Enter press asks for one more entry, up to ten. The interaction's `latched` Boolean keeps a contact lasting many physics frames from producing many sums. Releasing both points returns them to their places and clears the latch. This reuses the threshold and state reasoning from Trace and the interaction lessons.

`redraw()` loops over this record twice. `height_for(value, true)` gives each unit 0.05 metres. The other call uses the supplied natural logarithm `log`: `0.5 * log(value) + 0.5`. For 1, 2 and 55, those unscaled heights are approximately 0.500, 0.847 and 2.504 metres, compared with 0.050, 0.100 and 2.750 in the linear view. Logarithms need no derivation in this lesson; inspect what this declared mapping does.

Both rows then use the same `DISPLAY_SCALE = 0.2` to fit the hand table. The small linear row therefore gives one unit **one centimetre**. This common display reduction is separate from the choice of height rule. Neither mapping writes into `values`. A BoxMesh gives each entry a body; moving its centre by half its height keeps every base at the same level.

## The complete small construction

Hold a point and bring it to its partner, press its trigger, or use Enter. Release both points between held requests. Run the small study again to reset; the museum installation also has the nearby BACK and RESET buttons. A value is revealed by either request method, never by an automatic timer.

### sum_points.gd

__MAIN__

### point_body.gd — carried unchanged

This is the same small, frozen pickable point used in the preceding hand models. It supplies pickup, release, the action signal and desktop grab hooks. We reuse that interaction so the new lesson can concern the record and its representations.

__POINT__

## Check what stays the same

After eight requests beyond the two seeds, read:

`1, 1, 2, 3, 5, 8, 13, 21, 34, 55`

There should be ten bars in each row and the same labels in both. A ninth request changes nothing. The last small linear bar is 0.55 metres high; the corresponding logarithmic bar is about 0.501 metres. Joining the points and keeping them together must append only once. After release, their labels become the new last pair.

At the large display, reveal ten terms and turn on SUM. The 21-unit and 34-unit pieces together match 55 units at a common scale. Switching HEIGHT leaves the values and this witness unchanged. Logarithmic tower heights do not add this way: the mapping changes the relation between height and addition.

**Make one independent change.** Change only the starting array to `[1, 2]`. Predict the first five entries and the tenth before running it. The same addition should produce `1, 2, 3, 5, 8, …, 89`. Both views must receive that new record. You changed the initial conditions, while retaining the operation. Keep positive seeds for this supplied logarithmic mapping.

## A separate geometric comparison

Continue to the upright golden rectangle. NEXT removes a square from the remaining rectangle; MEASURE names actual side lengths. Its five-metre width starts with a height of `5 / phi`, where `phi = (1 + sqrt(5)) / 2`. The remainder turns and keeps the long-side/short-side ratio. The squares get smaller while their cut indices increase. They are not the increasing values from your array.

ARC adds quarter circles through those squares. Turning it off leaves the partition. The joined circular pieces are not an exact logarithmic spiral. The nearby helix, seed pattern and shell-like objects also need their own position and turn rules. Keep their differences visible; this lesson's required construction is the pair, record and two readers.

Carry this distinction into Synthesis: a procedure makes data, and another procedure gives that data a form. Name both when composing the next work.
'''.replace('__MAIN__',code('sum_points.gd')).replace('__POINT__',code('point_body.gd'))
(H/'tutorial.md').write_text(text,encoding='utf-8')
qpath=R/'doc/book/course/execution-plan/plan.json';q=json.loads(qpath.read_text(encoding='utf-8-sig'))
r=next(r for r in q['lessons'] if r['id']=='Fractal_GoldenSpiral')
r.update({'object':'Two familiar PointBody values and one ordered record in two height views.',
 'change':'Join the last pair once, append their sum; compare linear and logarithmic readers of the same record.',
 'dependsOn':['Point_Trace','Fractal_MengerSponge'],
 'reuses':'PointBody pickup/release; typed arrays, indices, append, loops, BoxMesh, a Boolean interaction latch; separation of data and displayed scale.',
 'given':'Prepared museum camera/light/player/XRTools; unchanged PointBody printed; logarithmic height function supplied explicitly; rectangle and unit-sum witnesses remain installed.',
 'later':'No botanical explanation, universal beauty claim, complete logarithm derivation or rebuilding of every exhibit. Numerical recurrence is not automatically a fractal.',
 'checks':['Two seeds plus eight requests give 1,1,2,3,5,8,13,21,34,55; cap ten.', 'Same list and labels feed both height functions; miniature uses common factor0.2.', 'Held contact adds once; both released rearms. Trigger uses same request.','Executed seed variation [1,2] ends89; source recurrence unchanged.','Rectangle ratio and area preserved; ARC changes view rather than data.'],
 'transfer':'Change only seeds to [1,2]; predict first five and tenth; keep operation and compare both readers.',
 'carry':'A retained numerical history and two explicitly different interpretations of its height.',
 'next':'Fractal_Synthesis: name the seed, operation, limit and display before composing a work.',
 'notes':'One required complete two-file reconstruction. Installed adapter reads the existing desk; all seven artifacts and order retained. Native verification is distinct from headset feel.',
 'summary':'At the Fibonacci desk, the learner joins two familiar points carrying the last two values. One contact appends one sum; release rearms it. Reconstruct a positive integer list from [1,1], retain earlier entries and feed it to adjacent linear and supplied logarithmic height functions. Compare both with the museum’s fixed-unit SUM witness; neither reader changes the record. Predict and execute [1,2] as different seeds. Visit the separate rectangle cut and arc as comparisons, then carry seed, recurrence, limit and display choices into Synthesis.'})
qpath.write_text(json.dumps(q,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Wrote focused tutorial and one plan row.')
