"""Author the Koch lesson from complete scripts; explicit --write replaces tutorial.md."""
from pathlib import Path
import argparse
import shutil

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT/'doc/book/studies/fractals-through-the-hands/Fractal_KochSierpinski'

def block(name):
    return '<!-- student-code:'+name+' -->\n```gdscript\n'+(STUDY/name).read_text(encoding='utf-8').rstrip()+'\n```\n'

def write():
    shutil.copy2(STUDY.parent/'Fractal_CantorSet/point_body.gd', STUDY/'point_body.gd')
    shutil.copy2(STUDY.parent/'Fractal_Recursion/line_skin.gd', STUDY/'line_skin.gd')
    text = '''# Koch / Sierpinski — the distance between

**Learning elements**

- An ordered path of positions
- Replacing one segment with four
- Current and next arrays
- A turn in a declared plane
- Endpoint distance and path length

Hold the black point on the small line beside the Koch desk. Move it along the drawing. Its partner follows the larger line on the floor. Press the trigger once: the line takes a detour. Find the two ends again. They are still four represented metres apart.

NEXT beside your hand makes the same replacement. BACK and RESET let you compare stages; the original desk also offers TURN and FORM. Each step replaces **every current segment**, including those already climbing or descending. The readout gives the distance between the ends, the complete path length, and your point's place along that path.

## What continues

Keep the museum workspace. We bring `PointBody` from Cantor and `LineSkin` from Recursion. Trace taught us to keep positions in order and connect neighbouring entries. Cantor taught us to read `current`, construct a separate `next`, then change which record is current. Here that pattern adds a detour instead of removing a middle.

Save the three files below together. Put `koch.gd` on your existing empty, unit-scale `PointStudy` node, facing its positive Z side. Keep the previous lesson's script. The museum already supplies the light, camera, player and XR pickup functions. This script creates its own drawing and point, with no scene-node references.

Hold the point and press its trigger to replace once. On desktop, press Enter (`ui_accept`); use the existing pickup/drop interaction to move the point. The complete small study stops after four steps. Run it again to return to the seed. Its purpose is the open Koch path; the production hall adds the table, floor receiver, BACK/RESET controls and closed-triangle comparison.

## Four segments from two ends

The seed is `(-2, 0, 0)` to `(2, 0, 0)`. These are positions in a **local XY construction plane**. `third = (end - a) / 3` is a displacement, with both direction and length.

Place `b` one third from `a`, and `d` two thirds from `a`. From `b`, turn that displacement sixty degrees about positive Z (`Vector3.BACK`) to find `c`. The path goes **a → b → c → d → end**. Its middle makes two sides of an equilateral triangle. Each of the four new segments has a third of the old length.

`replace_path()` appends `a`, `b`, `c` and `d` for every old segment. The next segment supplies the shared endpoint; only the very last endpoint needs a separate append. One segment therefore needs two positions, four segments need five, and 256 segments need 257. This list describes connections through order.

## koch.gd

Read `replace_path()`, `advance()` and `path_length()` first. The remaining functions connect the known point to the drawing. The closest-point reader is supplied in full below those operations.

'''+block('koch.gd')+'''
The loop finishes before `current` is replaced. The original seed stays intact. Like Cantor, this implementation makes one generation per action rather than calling itself to complete every generation at once.

`path_length()` adds the distance between **each neighbouring pair**. Endpoint distance uses only the first and last positions. After one replacement those readings are 16/3 metres and 4 metres. After four they are about 12.642 metres and 4 metres. The arithmetic is `4 × (4/3)^n`; it belongs to this particular sixty-degree, thirds rule.

## Reading is another operation

`display()` lays the XY construction onto a horizontal XZ drawing. `VIEW_SCALE` makes four represented metres fit into 1.2 physical metres. It does not change the stored positions or the length calculation. The supplied LineSkin gives each connection a thin visible cylinder; it supplies no collision.

The hand remains free while held. The reader finds the nearest point on any segment, then adds the lengths of the preceding segments. On release the ball parks at that reading. It does not drag you or force your hand to follow the path. If you skip from one fold to another, the reading jumps. **“At 3 metres along” is an address on this path, not proof that your hand travelled 3 metres.**

Small folds may become hard to select with this sphere or distinguish in the headset. The exact finite record and the useful size of a gesture have different limits. The larger floor drawing gives the same route another scale; it remains a drawing supported by the existing floor, not a narrow balance beam.

## Predict, then change

Before the second step, predict sixteen segments and seventeen positions. Each segment should be 4/9 metre; their total should be 64/9 metres. Neither endpoint should move. After the fourth step, another trigger should leave the record unchanged.

For your own variation, change the call to `replace_path(current, -1.0)` and run again. Predict which coordinates will change sign. The first peak moves below the starting line. Count, segment lengths and endpoint distance stay the same. This reverses the sixty-degree turn; changing the angle itself would require a new length calculation rather than borrowing the same formula.

Now try a sloping seed in the XY plane, for example `(-1, -1, 0)` to `(1, 1, 0)`. Predict its starting length and its first replacement length. The rule uses each segment's displacement, so the peaks turn with the segment. Arbitrary out-of-plane endpoints need another declared construction plane; this lesson does not supply one.

## Across the aisle

At the existing Sierpinski triangle, press NEXT and find the missing middle. Three midpoint pairs give three corner triangles. Each corner has half the side length and a quarter of the area, so three quarters of the parent's area remain. The next generation applies that same replacement to every retained triangle.

Compare the two operations: Koch keeps the connection and increases length; Sierpinski keeps three corners and reduces area. VIEW changes whether retained corners or removed middles receive meshes, without changing the replacement rule. These are distinct constructions using a familiar current/next pattern. Rebuilding every artifact in this hall is not another assignment.

The optional box-counting desk changes its measurement grid over a held sample. Leave it for a separate investigation if needed. The next main construction is Menger: carry the replacement pattern from a segment and a triangle into cells of a cube.

## The carried files

These are unchanged from the earlier lessons. `PointBody` supplies pickup, release and the trigger signal inherited from XRTools. `LineSkin` places a cylinder between two ends. They are printed here so the example has no missing code dependency; the prepared museum still supplies XRTools and the player.

### point_body.gd

'''+block('point_body.gd')+'''
### line_skin.gd

'''+block('line_skin.gd')
    (ROOT/'commons/maps/Fractal_KochSierpinski/tutorial.md').write_text(text, encoding='utf-8')

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write', action='store_true')
    if parser.parse_args().write: write()
