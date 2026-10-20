"""Publish the Euclid teaching text from the four inspectable study files."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT / 'doc/book/studies/euclid-lineage'
OUT = ROOT / 'doc/book/iterations/2026-10-11-euclid-the-same-triangle'
MAP = ROOT / 'commons/maps/Euclid_Parallel'

OPENING = '''# The same triangle, measured

## Learning elements

- Constructing a parallel through a point.
- Measuring a triangle's interior angles.
- Assumptions, measurements and proof.
- Recognising a degenerate construction.

**Carry:** PointBody, the finite cylinder from Point Lines, three vertices and a triangle face. **New:** calculate the three angles and construct a parallel using the base direction. **Supplied:** the existing Endless Museum, its desktop/XR player, XRTools and the named push-button scene. We are working inside that project.

## Encounter

Find the postulates plaque, the three parallel line modules and the small triangle in Euclid's hall. NEXT changes the sentence; GOLD changes its emphasis. Neither changes the room's geometry. The old flat triangle's three “60°” labels are fixed text even though its corners are unequal. Our study will read the positions instead.

Return to the object you can already build: three points joined by three segments. Move a corner. Its individual angles change. What happens to their sum? Add a guide through C parallel to AB; hide it again. Does removing a drawing remove the relationship?

## Reuse the bodies

Create a folder in your museum working copy. Save the four scripts printed below together. The small `point_body.gd` is unchanged from Graph Theory and Gradient Landscape; `line_skin.gd` is unchanged from Point Lines. They are reprinted at the end for a complete reconstruction, not taught again. We reuse the class and construction; no live sphere or Machine Learning weights are transferred across hall loads.

Create one empty Node3D named `EuclidStudy`, keep its scale at `(1, 1, 1)`, and attach `euclid_study.gd`. Put it on clear floor in your working copy of the Euclid hall; allow 2.8 metres for the table and an approach on its local +Z side. The supplied `museum.tscn` launcher opens the existing hall and mounts this study at a checked position. It is room infrastructure, not a second geometry implementation. No replacement camera, light or player is part of the lesson.

## Keep positions; calculate angles

The array stores A, B and C in table coordinates. A Vector2's second coordinate becomes local Z; every measured point lies on the same plane. At each corner, subtract that position from the other two to obtain two outward vectors. `atan2(abs(cross), dot)` gives their interior angle. Sum those three measured values; do not print 180 as the answer.

`cross` here is the scalar 2D cross product. Its magnitude is twice the area. If the points coincide or nearly align, we withhold the angle reading. `EPS` is a numerical policy for this study, not a new geometric postulate. The relative area check rejects very thin triangles too.

For the parallel, copy the direction B − A and centre the visible segment on C. Equal directions in this flat coordinate model construct parallel supporting lines when C is off AB. The cylinder has finite length; the mathematical line does not end at its cap.

Save `triangle_record.gd`:

'''

HOST = '''
## Put the construction in the hand

The host creates every point, segment, label, face and control. There are no hidden scene-node references. GUIDE—or G, or a held point's trigger—only hides/shows the gold construction. RESET—or R—restores the three starting positions and keeps the guide setting. Put all points down before resetting.

The hand may move in three dimensions. We convert its world position into this study's local frame, keep X and Z and limit them to ±1 metre. While held, the sphere stays in your hand; the edges and corner label show its projected, bounded position. On release it rests at that recorded position. The tabletop is a visual guide, not a physical constraint. Moving or rotating the whole unit-scale study does not change this local construction.

Save `euclid_study.gd`:

'''

ENDING = '''
## Predict, then try

1. Move only C. Predict which angles grow and which shrink; compare their measured sum. The initial sum should be near 180°, within floating-point error, without three equal corners.
2. Hide the guide. A, B, C and their measurements must remain unchanged. Show it again: its direction should still match B − A.
3. Put C on AB, or put A on B. The study should withhold its triangle reading and face. Separate them and recover it.
4. Make your own scalene triangle. Record its three positions before running. Predict that doubling all coordinates doubles lengths and quadruples area while keeping each angle. Try this in a separate model copy: the hand interface deliberately limits its workspace. Explain any failed comparison before changing the prediction.

An assertion should compare calculated values, not a label that contains the desired answer. Test `(0,0), (1,0), (0,1)`: the three measured angles should be 90°, 45°, 45°, and the area 0.5. Test coincident and collinear positions separately. Test the full host too: three visible point bodies, initialized readout, grab/release, and the two buttons must work.

## What the test means

We chose Cartesian coordinates, straight segments and Euclidean angle measurement before running. A thousand successful drags check this implementation in that model. They do not prove the parallel postulate from the others, or establish which geometry every space must have.

Euclid's Proposition I.32 constructs a parallel through a vertex and reasons with equal angles to derive the triangle sum. Our gold segment recalls that construction; it is not a formal proof checker. Euclid's fifth postulate concerns which extended lines meet when a transversal makes particular interior angles. The familiar “one parallel through an external point” formulation is a later equivalent formulation in the usual Euclidean setting. [Postulate 5](https://mathcs.clarku.edu/~djoyce/elements/bookI/post5.html) · [Proposition I.32](https://mathcs.clarku.edu/~djoyce/elements/bookI/propI32.html).

Carry the three points, the measured result and the assumptions into **Non-Euclidean Spaces**. There we must define the surface and its straightest paths before comparing corner angles. Bending these cylinders on the same table would not, by itself, supply that geometry.

## Carried files, complete

Copy these unchanged if they are not already beside your new scripts. Their source versions are the small PointBody used in Gradient Landscape and Point Lines' LineSkin. The button dependency is `res://commons/interactables/push_button.tscn`; XRTools supplies `XRToolsPickable`. Both belong to the prepared museum project. A blank Godot project does not include them.

'''

REFLECTION = '''# Through the same point

<!-- @euclid_postulates_plaque -->
<!-- @parallel_lines -->
<!-- @angle_sum_triangle -->

The point returns to your hand. Two more points and three lines make the triangle familiar. You have used this construction to make faces and bodies. Here you stop making more of them and ask what you had already accepted when the first one appeared.

The plaque offers five postulates. NEXT moves between them; GOLD removes the fifth's special emphasis. Its sentence remains. The room has made one assumption conspicuous without changing what it assumes. You can withdraw the gold and still be standing in the same geometry.

Three line modules sit nearby. Their gaps are unequal, but their directions agree. Parallel does not mean evenly spaced. A pattern can lose one regularity while keeping another; the eye needs to decide which difference it has noticed.

At the small triangle, the three labels say sixty degrees. Those numbers were supplied; the drawn corners are not equal. The tutorial returns to those corners with a measurement. When you move its points, the separate angles change and their sum stays close to a straight angle. The result is calculated, but calculation has conditions too: the positions belong to a flat coordinate plane, and the edges are straight segments within it.

Draw the gold line through C in the direction of AB. Euclid's triangle-sum argument makes a related construction: a parallel through a vertex lets the angles be compared along a straight line. The reasoning depends on the geometry in which that comparison is allowed. A display of the construction can help us follow the argument; a collection of successful measurements cannot replace it. [Euclid, Proposition I.32](https://mathcs.clarku.edu/~djoyce/elements/bookI/propI32.html).

The visible line ends. The statement about its extension does not. Move C, hide the guide, bring it back: you have changed the example and its display without leaving the chosen model. Even the hand's upward movement is recorded as a position on the table. The construction keeps what it has been equipped to measure.

Now bring the three corners into one straight row. The face disappears and the reading is withheld. This is a useful refusal: an arrangement of three positions need not be a triangle with an interior. Our software also sets a tolerance, so an extremely thin triangle may receive the same refusal. The threshold belongs to the instrument; it is not the boundary of geometry itself.

An assumption can be useful for so long that it becomes difficult to notice. That is the question this room carries beyond mathematics: which conditions of a working arrangement have begun to feel inevitable? The parallel postulate does not answer a social question for us. It gives us a precise occasion to separate a starting condition, an example, and what follows from them.

Take the triangle into the next room as a construction to reconsider. Keep the care with which you measured it. Ask again what counts as straight, and what space the corners belong to.
'''


def block(name):
    text = (STUDY/name).read_text(encoding='utf-8').rstrip('\n')
    return '<!-- student-code:' + name + ' -->\n```gdscript\n' + text + '\n```\n'


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    tutorial = OPENING + block('triangle_record.gd') + HOST + block('euclid_study.gd') + ENDING
    for name in ['point_body.gd', 'line_skin.gd']:
        tutorial += '\n### ' + name + '\n\n' + block(name)
    (MAP/'tutorial.md').write_text(tutorial, encoding='utf-8')
    (MAP/'final.md').write_text(REFLECTION, encoding='utf-8')
    preserved = [ROOT/'commons/maps/curriculum_spine.json', ROOT/'commons/maps/sequences/foundationscrisis.json', MAP/'map_data.json', ROOT/'commons/data/museum/em_plan.json']
    preserved += [ROOT/'commons/artifacts/euclid_postulates_plaque/euclid_postulates_plaque.gd', ROOT/'commons/artifacts/angle_sum_triangle/angle_sum_triangle.gd', ROOT/'doc/book/studies/ml-gradient/point_body.gd', ROOT/'doc/book/studies/ada-xr-starter/lessons/Point_Lines/line_skin.gd']
    baseline = OUT/'preserved.json'
    if not baseline.exists():
        baseline.write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in preserved},indent=2),encoding='utf-8')
    print('Updated Euclid tutorial and reflection; four complete printed scripts.')


if __name__ == '__main__': main()
