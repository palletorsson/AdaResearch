"""Continue the retained Foundry source into reflected lookup, one hall only."""
from pathlib import Path
import json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Tutorial_Pattern'
MAP=ROOT/'commons/maps/Tutorial_Pattern'
STUDY=ROOT/'doc/book/studies/tiling-lineage'
def block(name):return f'<!-- student-code:{name} -->\n```gdscript\n{(STUDY/name).read_text(encoding="utf8").rstrip()}\n```\n'
def main():
    before=OUT/'before';before.mkdir(parents=True,exist_ok=True)
    for n in ['tutorial.md','final.md','map_data.json']:
        if not (before/n).exists():shutil.copy2(MAP/n,before/n)
    plan=json.loads((ROOT/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
    if not (before/'plan-entry.json').exists():(before/'plan-entry.json').write_text(json.dumps(next(x for x in plan['lessons'] if x['id']=='Tutorial_Pattern'),indent=2)+'\n')
    carried={n:'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Foundry/learner/printed/'+n for n in ['palette.gd','grid_surface.gd','point_body.gd']}
    for n,p in carried.items():assert (STUDY/n).read_text()==(ROOT/p).read_text()
    (OUT/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
    text='''# Tutorial Pattern — change the reading

## Learning elements

- Reflected lookup on alternating copies.
- Changing an address versus changing stored data.
- Translation period and tile width.
- An asymmetric mark as a diagnostic.

## Keep the source

In the museum's side bay, find the red bend on both wall panels. The left panel repeats it with the same facing. On the right, alternate copies face back. Press PM, then P1: the floor changes, but the sixteen source buttons do not. Press FLIP X. Now the source changes, and both panels follow it.

Continue Foundry's source, cube display and held point. Last time, every copy read a row in the same direction. We will let alternate copies read it backwards. Then we will reverse the stored rows and compare the consequences. The museum's shader, quarter-turn control and undo history stay supplied; the new lesson is the address operation.

## Two actions on the carried object

Replace the Foundry entry script with `03_reflected_reader.gd`, on the same empty Node3D at floor level and unit scale in your museum learner space. Keep the three carried files beside it. The museum still supplies the player, lights, camera and XR Tools. This five-by-five display is not a walkable floor. Its two-by-three source is the same reduced motif from Foundry, rather than a replacement for the installed four-by-four editor.

Grip the black point. Over a cube, trigger still edits that cube's shared source entry. At the front, hold it just above the **READ RULE** label and trigger to switch between translation and alternating reflection. Over **FLIP SOURCE**, trigger reverses each stored row. The upper readout names the selected action before you press. Moving the point alone changes nothing.

The front labels sit 60 centimetres to either side of the starting point. Their selection regions extend 25 centimetres sideways and forwards/backwards, with the point centre between 95 and 150 centimetres above the learner floor. These bounds are part of the supplied hand adapter; changing the reader does not require changing them.

### The source and two operations

'''+block('03_reflected_reader.gd')+'''
`source_address()` first finds the column of the repeated tile, then the cell inside it. With a source three cells wide, display columns 0–2 belong to tile column zero; columns 3–5 belong to tile column one. The second tile is partly cut off by our five-column display. A copy need not fit entirely inside a receiver.

For a reflected tile, `width - 1 - column` reads columns 2, 1, 0 instead of 0, 1, 2. The stored row stays where it was. `floori()` counts tile columns correctly on the negative side too; `posmod()` supplies a non-negative local address. The condition is based on the **tile column**, not on alternate individual cells.

`toggle_reader()` changes one Boolean and repaints. `flip_source()` changes the arrays themselves: `row.reverse()` reverses each row in place. Reversing the outer `source` array would swap top and bottom rows, which is a different operation. Both functions repaint the existing cubes; neither changes their geometry.

### The carried files

These three files are unchanged from Foundry. They remain printed so the example can be reconstructed completely. Their construction is not a new obligation here. The existing `choose()` adapter gains two named actions; its old cube selection and source editing remain.

### palette.gd

'''+block('palette.gd')+'\n### grid_surface.gd\n\n'+block('grid_surface.gd')+'\n### point_body.gd\n\n'+block('point_body.gd')+'''
## Predict before pressing

Begin with the printed source and translation. Display (3, 1) reads source row one, column zero: navy. Switch READ RULE. It now reads row one, column two: pink. The source label must still read `[[0, 1, 0], [0, 0, 1]]`.

Keep reflection on and press FLIP SOURCE. The lower source row becomes `[1, 0, 0]`. Display (3, 1) becomes navy again; display (0, 1) becomes pink. Press FLIP SOURCE a second time. Every stored entry and displayed colour should return. The Boolean stays on throughout these two source edits.

Now point at display (3, 1) and trigger once. Because that copy reads backwards, you edit source column two, not column zero. Predict its other appearances before pressing. In this bounded display, (2, 1), (3, 1), (2, 3) and (3, 3) all become mint. A reflected view must also lead an edit back to the correct stored cell.

The source width is three cells. Under translation its horizontal period is three. With alternating reflection, this asymmetric motif returns to the same arrangement after six cells. Our preview is smaller than that period: call `value_at(Vector2i(6, 1))` to compare it with (0, 1), or follow the complete paired copies on the museum panel. A tile width and a pattern's translation period need not be equal.

## Make a change that hides the rule

Before running again, replace only the declaration with `var source := [[0, 1, 0], [2, 0, 2]]`. Predict both actions. Each row now reads the same backwards. READ RULE still changes the Boolean and the addresses, but no displayed colour should change. FLIP SOURCE performs its reversal, yet produces the same stored values. An unchanged image cannot tell you that no operation happened.

Break the symmetry: with reflection on, edit display (3, 1) once. This changes source column two from mint to navy, while column zero stays mint. Switch READ RULE again and locate the newly visible difference. Explain it using the source address, not just the appearance. The program assumes a non-empty rectangular source containing valid palette indices, as in Foundry.

## What travels onward

The source is data; a reader decides which entry each place receives. A mutation and a changed reader may produce similar images, so inspect the stored cells as well. The installed wall panels provide two fixed rules for comparison; our single learner display switches between those rules. It does not control the museum station.

In Array Patterns, keep this distinction and give the reading a physical frame: where it begins, which way its axes run, and how much space one cell occupies.
'''
    (MAP/'tutorial.md').write_text(text,encoding='utf8')
    old=(before/'final.md').read_text(encoding='utf8')
    start=old.index('P1 repeats by translation.');end=old.index('Choose a paint colour',start)
    replacement='''P1 repeats by translation. In this station's PM rule, alternate columns read the source from the opposite side. The field distinguishes which tile a place belongs to from where it lies inside that tile. Each new tile begins another reading. On alternate columns, the reading crosses the source in reverse.

Nothing in the painted grid has moved. The alternating facing belongs to the relation between copies.

FLIP X instead rearranges each stored row from the opposite end. You saw its result in the source buttons. Press FLIP X again. The second reversal brings every cell back. Try ROTATE, then follow the corner through four presses. UNDO takes you back one editing operation; RESET restores the starting mark and the translating floor. Reset can itself be undone.

'''
    current=(MAP/'final.md').read_text(encoding='utf8')
    if old[start:end] in current:current=current.replace(old[start:end],replacement,1)
    elif replacement not in current:raise RuntimeError('Reflective passage changed; inspect before editing.')
    (MAP/'final.md').write_text(current,encoding='utf8')
    (OUT/'spec-student.json').write_text(json.dumps({'lesson':'res://'+(OUT/'learner/printed/03_reflected_reader.gd').relative_to(ROOT).as_posix()},indent=2)+'\n')
    print('Wrote Tutorial Pattern, carrying Foundry into reflected reading.')
if __name__=='__main__':main()
