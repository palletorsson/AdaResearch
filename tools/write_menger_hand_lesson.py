"""Install this authored Menger revision only with --write; later edits remain authoritative."""
from pathlib import Path
import argparse

ROOT=Path(__file__).resolve().parents[1]
STUDY=ROOT/'doc/book/studies/fractals-through-the-hands/Fractal_MengerSponge'
def block(name):
    return '<!-- student-code:'+name+' -->\n```gdscript\n'+(STUDY/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
def write():
    text='''# Menger — a cell and a room

**Learning elements**

- Three-dimensional cell addresses
- A Boolean selection rule
- Replacing each retained cube
- Count, edge length and retained volume
- Model scale and bodily access

The nine-metre cube is still solid. Beside its desk, hold the black point and move it through the transparent hand model. A small frame finds one of twenty-seven cells; a larger frame marks the same address on the cube. Read KEEP or REMOVE. The point is inspecting the rule, not cutting a new hole wherever you put it.

Press its trigger once, or NEXT. The centre and the six face centres disappear. The corner cells and edge middles remain. Follow one of the new openings with your eyes before requesting another cut. The second cut repeats that selection **inside every retained cube**.

## What continues

Keep the museum workspace and the PointBody class from the previous halls. We already have a cube mesh, three coordinates, nested grid loops, and Cantor's pattern of making a separate `next` array. Koch used an ordered position list to connect neighbours. Here the positions locate **cube centres**; their order does not make a path.

Save the two files below together. Attach `menger.gd` to the existing empty, unit-scale `PointStudy` node in your museum workspace. Keep your Koch script separately. The museum supplies its camera, light, player and XR pickup functions. This script creates every node it needs; it does not refer to hidden scene children.

Hold the point and press its trigger, or press Enter (`ui_accept`) on desktop, to replace once. Two cuts are enough. Run the study again to reset. The complete student example makes a small transparent model and a cell reader. The full-size museum adds solid collision, the highlighted cell frames, BACK/RESET and its existing flight enclosure.

## Which cells remain?

Start with one centre at `(0, 0, 0)` and an edge length of nine represented metres. Divide each edge into three. Every child is three metres wide, and its centre is one child width left, central or right of the parent's centre along each axis.

The three nested loops try offsets `-1`, `0` and `1`: twenty-seven combinations. Zero means the middle along that axis. Count how many coordinates are zero. The centre has three; a face centre has two; an edge middle has one; a corner has none. **Keep fewer than two middles.** That keeps twelve edge middles and eight corners: twenty children.

`keep_cell()` is a Boolean function: it answers yes or no. `int(true)` contributes one to the count, and `int(false)` contributes zero. The museum's original generator lists the twenty retained indices explicitly. This predicate makes the same selection. Its addresses run from zero to two; add one to each of our offsets to compare them.

## menger.gd

Read `keep_cell()`, `replace_cells()` and `advance()` first. `redraw()` uses the familiar BoxMesh. The last functions connect the carried point to the first-level address reader.

'''+block('menger.gd')+'''
`replace_cells()` reads the old centres and returns a new list. Each new position is a parent's centre plus a scaled offset. Only after that list is complete does `advance()` replace `current` and divide `edge` by three. Every current cube has the same size, so one `edge` value describes them all. Mixed-size cells would need a size stored with each centre.

Like Cantor and Koch, one action produces one generation. This is repeated replacement, implemented with loops; a function does not need to call itself to make the finite construction.

## More cubes, less volume

Predict the count and edge length before the second cut. Twenty parents each keep twenty children: four hundred cubes, each one metre wide. Their retained volume is four hundred cubic metres. The previous stage had twenty cubes, each three metres wide: `20 × 3 × 3 × 3 = 540` cubic metres.

| Cut | Cubes | Edge of each cube | Retained volume |
| --- | ---: | ---: | ---: |
| 0 | 1 | 9 m | 729 m³ |
| 1 | 20 | 3 m | 540 m³ |
| 2 | 400 | 1 m | 400 m³ |

The general readings are `20^n` cubes and `729 × (20/27)^n` cubic metres. The outside still spans nine metres: all eight outer corners survive. Count, occupied volume and outer bounds answer different questions.

`VIEW_SCALE` fits those nine represented metres into a hand model 0.81 metres wide. The volume calculation uses the stored geometry, not the display size. Transparency lets you inspect interior addresses; it is a drawing choice. The model has no cube colliders. The large museum sponge does.

## Read a cell, then enter a space

Move the point to a corner of the small model. Its readout says KEEP. Move to the middle of a face: REMOVE. The reader divides by the display scale, then rounds to the nearest first-level cell centre and clamps each coordinate to the three available values. The point stays free in your hand; on release it returns to the near edge so it is available again.

After the second cut, the reader **still names a first-level cell**, not one of the four hundred tiny children. A kept cell now contains its own removals. KEEP describes its role in the first replacement; it does not promise that the whole selected region remains filled.

At the museum desk, GHOST reveals the removed volumes and FRAME keeps the original outer bounds visible. These views change neither the retained cubes nor their collision. Turn GHOST off, enter the ground doorway and rise toward the central opening. In VR, tilt the left controller and use its stick; release to hover. On desktop, use WASD, Space to rise and Ctrl to descend. Leave through a ground doorway to walk again.

The main passage is three metres across. The smaller axial openings after two cuts are one metre across and one metre high. Seeing through an opening does not establish that your body fits. The existing enclosure supplies flight; this lesson does not rebuild the player. The desk refuses solid changes while a visitor remains inside. Leaving does not execute a queued change: press again.

## Make a different selection

Predict what happens if `keep_cell()` returns `middles == 0`. Only the eight corners survive. One cut gives eight cubes; two give sixty-four. Their final edges are still one metre, their total volume is sixty-four cubic metres, and the outside still spans nine metres.

Make that one change in your small study. Compare the result with your prediction, then restore the Menger rule. This produces a different construction, not a more accurate sponge. Its corners preserve the bounds while its face connections disappear. Do not transfer it automatically into the occupied full-size structure.

You now have a selection function that can be stated, changed and checked independently of its display. The next hall changes the recurrence: a new number comes from the previous two. Before treating its drawing as a spiral, we will ask what the sequence itself supplies.

## The carried point

`point_body.gd` is unchanged from Cantor and Koch. It supplies pickup, release and the trigger signal inherited from XRTools. It is printed again as a complete dependency, not as a new assignment. The prepared museum still supplies XRTools and the player.

'''+block('point_body.gd')
    (ROOT/'commons/maps/Fractal_MengerSponge/tutorial.md').write_text(text,encoding='utf-8')
if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--write',action='store_true')
    if parser.parse_args().write:write()
