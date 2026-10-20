from pathlib import Path
R=Path(__file__).resolve().parents[1];S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Shape_Grammars';M=R/'commons/maps/LSystems_Shape_Grammars';O=R/'doc/book/iterations/2026-10-09-shape-grammar-a-face-continues'
def code(n):return '\n<!-- student-code:'+n+' -->\n```gdscript\n'+(S/n).read_text(encoding='utf-8').rstrip()+'\n```\n'
t='''# Shape Grammars — a face continues

## Learning elements

- Seed-face indices and descendant tags
- Inset towards a centroid
- Extrusion along a face normal
- Selecting once, then replacing in reverse index order
- A saved recipe, repeated operations and their limits

Living separated a design record from the instructions and body made from it. Here the cube returns. We change its face list directly. The point, coordinates, triangles, arrays and loops are already ours; the new question is which faces receive the next operation.

## Read the six existing specimens

Start at 01. The top looks square, but the diagonal separates two triangles. At 02, each triangle has drawn towards its own centre. At 03, those smaller triangles have risen 0.4 metres; walls connect them to the edges they left. These are two tips, not one square lid.

At 04, the same pair of operations has run three times. Only the new tips continue. The mint shoulders stay behind. Specimen 05 uses a smaller inset amount. Specimen 06 changes the initial selection from the top pair to all twelve triangles. The museum keeps all six forms so that you can walk back and compare them. They are fixed constructions, not a growing simulation.

## Reconstruct the operation

Put these three files together. Attach `family.gd` to an empty, unit-scale Node3D in your working copy of the prepared museum. A clear bay between the two collections is available at hall-local (10.5,0,21.5), rotated 180 degrees around Y. Keep the existing camera, floor, player and XRTools. The example creates its mesh, readout and familiar point in code. It displays one recipe at a time; the gallery retains the comparisons nearby. The example's surface and edge overlay have no colliders. Its lowest point sits 0.56 metres above the floor, matching the gallery's display height, without adding another plinth.

### The seed and its descendants

`faces.gd` starts with eight cube positions and twelve index triples, as in Primitives. This is the vertex order used by the museum's cube factory. Seed faces 8 and 9 are the upward pair. An index tells us where a record is now; it is not a permanent identity.

We tag the chosen seed faces `growing`. Every operation selects that tag before changing the list. The selected indices are processed backwards: removing a high index leaves all lower selected indices in place. Then the new inner triangle or raised cap receives `growing`; its six connecting triangles receive `shoulder` or `wall`. Selecting the old indices again would act on different records after the list changes.

### Two ways to place three new corners

Inset averages the three corners to find their centroid. Each corner moves a fraction of the way towards it. Extrusion moves each corner along the face's outward normal. Both replace one triangle with seven: one new tip and two triangles along each of its three edges. Each successful replacement therefore adds six face records.

The extrusion keeps the museum's checks for tiny or very elongated triangles. The small builder accepts zero to three rounds and distinct seed indices. It retains the input recipe independently. It does not implement the factory's other metadata, zone inheritance or arbitrary mesh operations.
'''+code('faces.gd')+'''
The surface builder reads each index triple as three positions. The cross product supplies the same normal used by extrusion. Pink marks `growing`, mint marks `shoulder`, and pale faces include the original body and extrusion walls. The material below shows both sides, like the installed family; two-sided rendering is not a test of watertightness. The thin dark overlay makes the triangle edges visible without changing the faces.

### A recipe you can return to

`family.gd` names the same six comparisons as the gallery. Every selection rebuilds from the cube, so changing the displayed recipe does not accidentally operate on the last result. The inset-only recipe isolates the first operation. The next adds extrusion; the fourth repeats the pair three times. A held trigger or Space advances to the next recipe. R returns to the first. Moving the point does not move vertices or change a recipe; release parks it again.
'''+code('family.gd')+'''
### Keep the same point

Use the point from Living unchanged. It supplies pickup, release and the held action signal. That interaction does not need another sphere construction or a new grab system.
'''+code('point_body.gd')+'''
## Predict, then inspect

1. The cube has 12 faces. Insetting two selected triangles replaces each with seven: predict 24 faces. Adding one extrusion on the two new tips gives 36. Confirm these counts at the readout.
2. Three inset/extrude rounds on those two tips give 84 faces. There are still only two `growing` records. Why do the shoulders not begin growing too?
3. Compare recipes 04 and 05. Both take three steps of 0.4 metres. Their top height is the same, but their tip widths differ. With inset 28%, each tip's linear dimensions shrink by 0.72 per round. Its area shrinks by the square of that factor.
4. Change only recipe 04's `"faces":[8,9]` to `"faces":[8]`. Predict one projection, one continuing tip and 48 total faces after three rounds. Run the complete edited program. The other top triangle stays at the seed height. Return to recipe 01, then 04: the edited recipe should reconstruct the same result.

The selected index list belongs to the seed. The `growing` tag carries selection through replacement. This is the useful lineage: a face gives way to a new face without making every surface eligible for the next step.

## What needs another operation?

At the extreme inset value 0.99, the tip can become too small for the extrusion guard. A requested round need not produce another 0.4-metre rise. Counts describe what ran, not only what was requested. Our tested three-round gallery recipes stay above that guard.

Further on, the petal study and the large canopy add a different builder. More inset/extrude rounds alone do not create those curved strips, a hole through the cube or a bridge joining its tips. Keep those companion works available to reflection without adding their full construction to this lesson.

The current rule acts on faces. Next, Assemblage returns to a field of separate marks and asks what connections we perceive between results the rule made independently.
'''
(M/'tutorial.md').write_bytes(t.encode('utf-8'))
f=(O/'before/commons/maps/LSystems_Shape_Grammars/final.md').read_text(encoding='utf-8')
old='Only the new tips continue. The shoulders stay behind.'
new='Only the new tips continue. The shoulders stay behind. The program keeps a tag on those tips as their positions in the face list change; being next in the list is not what makes a face next in the construction.'
assert old in f;f=f.replace(old,new)
(M/'final.md').write_bytes(f.encode('utf-8'))
