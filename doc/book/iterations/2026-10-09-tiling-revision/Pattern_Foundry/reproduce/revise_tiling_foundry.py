"""Write one continuation from the addressed Disco display into an editable motif."""
from pathlib import Path
import json,shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Foundry'
MAP=ROOT/'commons/maps/Pattern_Foundry'
STUDY=ROOT/'doc/book/studies/tiling-lineage'
def block(name):return f'<!-- student-code:{name} -->\n```gdscript\n{(STUDY/name).read_text(encoding="utf8").rstrip()}\n```\n'
def main():
    before=OUT/'before';before.mkdir(parents=True,exist_ok=True)
    for n in ['tutorial.md','final.md','map_data.json']:
        if not (before/n).exists():shutil.copy2(MAP/n,before/n)
    plan=json.loads((ROOT/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'))
    if not (before/'plan-entry.json').exists():(before/'plan-entry.json').write_text(json.dumps(next(x for x in plan['lessons'] if x['id']=='Pattern_Foundry'),indent=2)+'\n')
    carried={n:'doc/book/iterations/2026-10-09-tiling-revision/Pattern_Disco/learner/printed/'+n for n in ['palette.gd','grid_surface.gd','point_body.gd']}
    for n,p in carried.items():assert (STUDY/n).read_text()==(ROOT/p).read_text()
    (OUT/'carried-files.json').write_text(json.dumps(carried,indent=2)+'\n')
    text='''# Pattern Foundry — one mark, several places

## Learning elements

- A source array: rows containing columns.
- Wrapped addresses and the repeat period.
- Palette indices stored separately from colours.
- One source edit reaching several displayed cells.

## Find the source

At the museum's small four-by-four tile station, take a coloured cube and release it over an off-centre cell. Find that mark in the repeated preview. Add another beside it. Follow the pair before moving to the mirror station or the larger machines.

Disco calculated zero or one from an address and a phase. Here we replace that calculation with a small arrangement we can edit and keep. The cube grid, Palette class and grabbable point return. Their construction is already available; the new work is a source and the rule that reads it.

The installed small tile has sixteen cells. Our reduced motif has two rows and three columns, so every entry is easy to inspect and the two directions have visibly different repeat lengths. The same five-by-five preview from Disco shows several returns and cuts through the last repeat. It does not stretch the source to fit.

## Continue the same display

Use `02_source_motif.gd` on an empty Node3D at floor level and unit scale in your existing museum learner space. Put the three carried files beside it. Replace the previous lesson's entry script rather than running both on the same object. The museum supplies the player, camera, lights and XR Tools input; this small cube grid remains a display, not a walkable floor.

Hold the black point above a tile. Its centre must be between 12 and 65 centimetres above the display. A ring and the label show the selected preview address and the source cell it reads. Press the held trigger: that source value advances through navy, pink and mint. All preview cells reading it change together. Moving without pressing selects but does not paint. Moving outside the grid or height range prevents an edit.

### The source and its reader

'''+block('02_source_motif.gd')+'''
Read `source[0][1]` as row zero, column one. It begins at 1, which selects pink from the palette. The rows run along the grid's local Z direction; columns run along X. `Vector2i.y` is the row address here, not a height.

The reader wraps the column by three and the row by two. Preview addresses (1, 0), (4, 0), (1, 2), (4, 2), (1, 4) and (4, 4) all read source row zero, column one. These six places share one decision. `posmod` also gives a valid wrapped address for negative inputs; it returns a non-negative remainder.

`edit()` changes one stored number, then `paint()` visits the existing cube addresses and updates their colours. No cube is created or moved. The preview is refreshed explicitly: assigning an array entry alone does not notify a mesh. The image repeats the source; it does not contain a separately editable source array for each copy.

The hand adapter transforms the point into the grid's local frame before selecting a cell. The carried renderer spaces centres 32 centimetres apart. Adding half that pitch before rounding down selects the nearest cell, including the small visible gaps. The height check makes this a shallow interaction region. The selection stays meaningful if the whole learner object is turned in the room.

### The carried files

These files are unchanged from Disco. `Palette` owns its colour list. `GridSurface` owns the addressed cube instances; we reuse its marker and hide its old readout. `PointBody` supplies grip and the action signal. They are printed for reconstruction, not introduced again as new subjects.

### palette.gd

'''+block('palette.gd')+'\n### grid_surface.gd\n\n'+block('grid_surface.gd')+'\n### point_body.gd\n\n'+block('point_body.gd')+'''
## Predict a shared change

Begin with source row zero, column one: it is pink. Select preview (4, 2) and press once. Predict the six addresses listed above before you inspect the result. They should become mint; the other nineteen colours and all twenty-five cube transforms should stay unchanged. Press twice more over the same source address to return to pink. Moving to another copy does not give it an independent value.

## Give the source another row

Before rerunning, replace the source declaration with `var source := [[0, 1, 0], [0, 0, 1], [2, 0, 0]]`. Predict the result. The width stays three; the row period becomes three. Preview (0, 2) should now be mint. The next occurrence of source row zero is at preview row three, not row two. The preview keeps five rows and five columns; it ends partway through a repeat.

Run the changed program, locate the new row, and explain why the receiver did not need to grow. Then choose one other source entry, list every preview address that will read it, and test your prediction with the held point. Keep every row the same length and every value a valid palette index. This example assumes that rectangular, non-empty source; it is not an importer for arbitrary data.

## Return to the larger room

The small tile, the loom's five-by-five card and the fabric studio are separate sources. Editing this learner array does not edit those installations. At the loom, MARK changes the same source image received by the flat and curved specimens. Holding the curve makes it decline later images. It does not give one repeated mark its own editable source.

A reference to a nested array, an independent copy of its rows and a held rendered image have different consequences. This first construction has one source and no copy or save control. Keep that distinction for a later return, rather than treating the held museum texture as a demonstration of array copying. The studio's save, receiver and architectural controls remain available in the encounter and the technical reference.

In Tutorial Pattern, keep an asymmetric source and change how copies read it. One mark near an edge, with a differently coloured neighbour, will make a reflected lookup easier to see.
'''
    (MAP/'tutorial.md').write_text(text,encoding='utf8')
    old=(before/'final.md').read_text(encoding='utf8')
    start=old.index('The current specimen is assembled one pixel at a time.')
    end=old.index('With CURVE selected',start)
    replacement='The current specimen is assembled one pixel at a time. At each address, the repetition rule reads the source card and returns a colour index. The palette supplies its colour. The receiving sheet supplies its shape. They meet in the visible pattern, but you can change them separately.\n\n'
    # Preserve any concurrent change outside the exact original passage.
    current=(MAP/'final.md').read_text(encoding='utf8')
    if old[start:end] in current:current=current.replace(old[start:end],replacement,1)
    elif replacement not in current:raise RuntimeError('Reflective passage changed; inspect before editing.')
    (MAP/'final.md').write_text(current,encoding='utf8')
    (OUT/'spec-student.json').write_text(json.dumps({'lesson':'res://'+(OUT/'learner/printed/02_source_motif.gd').relative_to(ROOT).as_posix()},indent=2)+'\n')
    print('Wrote Pattern Foundry tutorial and preserved its wider reflection.')
if __name__=='__main__':main()
