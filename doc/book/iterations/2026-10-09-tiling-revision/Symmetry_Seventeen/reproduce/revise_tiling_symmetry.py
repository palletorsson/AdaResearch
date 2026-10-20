"""Write the symmetry lesson from the carried, complete learner files."""
from pathlib import Path
import json,re,shutil
R=Path(__file__).resolve().parents[1];M=R/'commons/maps/Symmetry_Seventeen'
O=R/'doc/book/iterations/2026-10-09-tiling-revision/Symmetry_Seventeen';S=R/'doc/book/studies/tiling-lineage'
O.mkdir(parents=True,exist_ok=True);(O/'before').mkdir(exist_ok=True)
for n in ['tutorial.md','final.md','map_data.json']:
 if not (O/'before'/n).exists():shutil.copy2(M/n,O/'before'/n)
plan=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
if not (O/'before/plan-entry.json').exists():(O/'before/plan-entry.json').write_text(json.dumps(next(x for x in plan['lessons'] if x['id']=='Symmetry_Seventeen'),ensure_ascii=False,indent=2)+'\n',encoding='utf8')
carried={n:'doc/book/iterations/2026-10-09-tiling-revision/Array_Patterns/learner/printed/'+n for n in ['04_surface_frame.gd','palette.gd','grid_surface.gd','point_body.gd']}
for n,p in carried.items():assert (S/n).read_text(encoding='utf8')==(R/p).read_text(encoding='utf8')
(O/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
def block(n):return f'<!-- student-code:{n} -->\n```gdscript\n{(S/n).read_text(encoding="utf8").rstrip()}\n```\n'
text='''# Symmetry Seventeen — a reflection that slips

## Learning elements

- Reflection followed by a half-height shift.
- Composing address operations.
- A source block and a translation period.
- Marks that expose or conceal a rule.

## Compare the installed fields

At the side-bay console, keep the asymmetric four-by-four source. The left panel holds its initial P1 image; the right panel and carpet follow your edits. Choose PM, then PG. Follow the corner colour: a reflection becomes a reflection with a shift of two source rows. HOLD keeps an image for comparison. A later paint edit changes the live field while the held pixels stay still; UNDO recovers the previous state.

Our smaller construction keeps the two-row, three-column source, twenty-five cubes and black point from Array Patterns. We already know how to reflect alternate blocks and place a receiver. Add one operation: on those reflected blocks, move the source row halfway around its cycle. Half of our two rows is **one row**. The installed four-row source shifts by two.

## Extend the receiver

Keep `04_surface_frame.gd`, `palette.gd`, `grid_surface.gd` and `point_body.gd` unchanged beside the new file. Attach **05_glide_reader.gd instead of 04_surface_frame.gd** to the same learner Node3D in the museum. Keep that root at unit scale. There is one running display.

`extends` keeps the previous construction and specializes its address lookup and actions. `super._ready()` builds that receiver once. The new `_ready()` adds only the central RULE label. The complete carried files are printed below; their camera, player and XR Tools still come from the museum.

Hold the point above RULE and press the trigger to cycle P1 → PM → PG → P1. FACE and CELL WIDTH still work at the sides. While comparing rules, keep the receiver and width fixed. The point can paint again: trigger over a selected cube cycles the source entry it reads through the three palette colours. Hovering only selects.

### 05_glide_reader.gd

'''+block('05_glide_reader.gd')+'''
The inherited lookup wraps the column and row. When `reflected` is true, it also reverses the column in alternate source blocks. The new `source_address()` starts with that answer, then shifts its row only in PG's reflected blocks. `super.source_address()` calls the earlier method; `return cell` passes the resulting address back to the existing colour reader.

The rule number selects the operation, not a colour. Cycling synchronizes the inherited reflection flag and repaints the existing cubes. It does not change the stored source, the cube positions, or the receiver frame. Painting takes a different path: it uses that same lookup to find the original source entry, changes it, then repaints every copy that reads it.

The half-height shift requires an even number of discrete source rows. The assertion names that condition. Rounding half an odd height would define a different operation, so we do not silently substitute it. The museum's square four-by-four source and our rectangular two-by-three source both satisfy the condition.

## Predict three readings

Use **surface row 0, column 3**, the first column of the second source block. Addresses below are written `[row, column]`.

| Rule | Source address | Stored value | Colour |
| --- | --- | --- | --- |
| P1 | [0, 0] | 0 | Navy |
| PM | [0, 2] | 0 | Navy |
| PG | [1, 2] | 1 | Pink |

P1 and PM read different entries that happen to contain the same value. One equal-looking cell does not show that the operations agree. Follow the other row and the rest of the mark before drawing that conclusion.

On PG, trigger over this surface cell. Source `[1,2]` changes from 1 to 2: mint. The visible copies at surface `[0,3]`, `[1,2]`, `[2,3]`, `[3,2]` and `[4,3]` change together. You edit one stored entry through five displayed occurrences. The source is still two rows by three columns.

For this asymmetric source, moving six cells across restores the PG reading; moving three does not generally do so. Vertically it repeats after two rows. Applying the glide twice gives a full-height translation. It does not erase the journey through the intermediate reflected mark.

The five-column display cannot show a whole six-column horizontal period. Inspect its visible part, then use the lookup to compare an address six columns farther on. The installed panels show eight source blocks in each direction and make that repeated relation easier to see.

## Change the source height

Before `assert(...)` in the new `_ready()`, add `source = [[0, 1, 0], [0, 0, 1], [2, 0, 0], [0, 2, 0]]`. This replaces only the stored source before the inherited receiver is built. Predict the result before running:

- PG now moves two source rows. Surface `[0,3]` reads source `[2,2]`, value 0.
- Surface `[2,4]` reads source `[0,1]`, value 1.
- The vertical period becomes four cells. The horizontal translation period remains six for this source.

Change FACE or CELL WIDTH after finding those cells. Their positions change; their source addresses do not. This checks that the new reading composes with the receiver frame from Array Patterns.

As a separate comparison, make every source entry zero and cycle the rules. The image becomes uniform although the address operations still differ. Add one mark again. Which difference can that mark reveal?

## Return to the gallery

The console's P1, PM and PG names identify construction rules. Extra symmetries in a chosen source can give the resulting field more symmetry than that button alone suggests. These examples do not classify the entire field automatically.

The [IUCr tables](https://it.iucr.org/Ab/) describe seventeen plane-group types. Our three constructions and the cage's rotational diagram are ways into that subject; they do not prove the classification. A finite, coloured, sampled display also has edges and a viewing situation.

Carry the source, the operation that reads it, and the surface that receives it into **Pattern Temple**. There we will distinguish changing a shared source from choosing which architectural surface receives it. The later ribbon halls extend the reading through layers.

## Complete carried files

These four files are unchanged from Array Patterns. Use them beside the new script; do not attach a second copy of the previous entry to another node. The new subclass reuses their construction.

'''
for n in carried:text+='### '+n+'\n\n'+block(n)+'\n'
(M/'tutorial.md').write_text(text,encoding='utf8')
final=(O/'before/final.md').read_text(encoding='utf8')
start=final.index("The three buttons select translation")
end=final.index("An odd block reverses",start)
final=final[:start]+"The three buttons select translation, reflection and glide reflection. In this editor, the glide adds a half-height shift to the reflected source lookup.\n\n"+final[end:]
final=final.replace('What could this classification tell you about a garment? What would it leave unasked about its cut, its wearer, or the way a seam interrupts the repeat? Carry the small mark forward. In the next hall, the question is what happens when the source gains another index and supplies a volume.','What could this classification tell you about a garment? What would it leave unasked about its cut, its wearer, or the way a seam interrupts the repeat? Carry the small mark forward. In Pattern Temple, one source meets several architectural receivers. The later ribbon halls ask what happens when the source gains another index and supplies a volume.')
(M/'final.md').write_text(final,encoding='utf8')
print('Symmetry lesson written; four previous files retained, one specialized reader added.')
