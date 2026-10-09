"""Separate the reflective reading from the complete learner implementation."""
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
STUDENT = ROOT / "doc/book/iterations/2026-10-05-lines-relation-and-rule/student"
previous = (HERE / "before/tutorial.md").read_text(encoding="utf-8-sig")
exercise = previous.split("## What can two lines do?", 1)[1]
code = (STUDENT / "assembled.gd").read_text(encoding="utf-8")
code = code[code.index("extends Node3D"):].strip()
skin = (STUDENT / "line_skin.gd").read_text(encoding="utf-8").strip()

intro = '''# Point Lines — what can two lines do?

**Learning elements**

- Endpoints and a segment
- Displacement and distance
- Reusing an object
- Parallel, cross and X
- Position in depth

Take one end of the line in the black room. The other stays. The span turns and changes length. In this tutorial, we will make that relation using the point from Coordinates, then arrange two lines into parallel marks, a plus and an X.

## What we continue

The point already has a surface, a collider and pickup behaviour. We keep that construction. The new work gives it another end and reads the relation between them each frame. The museum's player, lighting and configured XR hands remain supplied.

Work in the same unit-scale `Node3D` student station as the [Coordinates reconstruction](../../../doc/book/iterations/2026-10-05-lesson-state-chain/tutorial.md). The two complete files are printed below. Save them together as `line.gd` and `line_skin.gd`; use `line.gd` in place of the station's preceding point script. They require the XR Tools setup already provided by the working museum.

The station may move or turn, but keep its scale at one. Here one unit represents one metre. Nothing is fetched through an unnamed scene path: the script creates its points and keeps references to them.

## The complete student script — line.gd

The sphere, collision shape, material and pickup settings continue from Coordinates. The additions are the two endpoint references, a copy of the point, the visible segment and `_process()`.

<!-- student-code:line.gd -->
'''

explanation = '''
## Read what changed

`point_a = solid` keeps the point we already made. `duplicate()` copies its body and children for B, including the visible surface and collider. The copy has its own position and can be held independently. Mesh and material resources are shared; this lesson changes positions.

The endpoint references belong to the script, so both `_ready()` and `_process()` can use them. The types after `:` say what kind of node each reference holds.

In `_process()`, `to_local` expresses both world positions in this station's frame. We can now subtract like from like. `b - a` is the displacement from A to B: initially `(1, 0, 0)`. Its `.length()` returns `1.0`. The displacement retains direction and length; the distance gives length alone.

The helper receives a start, that displacement and its length. It draws a thin cylinder between the ends. The next frame reads their positions again. Release an endpoint and it stays; the line continues to meet it.

Change B's starting offset to `Vector3(0, 1.0, 0)`. Predict what will happen. The span stands upright but keeps its length. Try `a - b` in the subtraction: the length remains, but the drawing points the other way from A. Restore `b - a`.

## The supplied drawing code — line_skin.gd

A mathematical line has no thickness. This helper gives our finite segment a surface we can see. It positions the cylinder halfway along the displacement and aligns its long axis with it. It supplies no collider or pickup behaviour.

The full helper is here so the example can be reconstructed. Its orientation calculation is supplied for now; understanding basis vectors is not a prerequisite of this lesson.

<!-- student-code:line_skin.gd -->
'''

text = intro + "\n~~~gdscript\n" + code + "\n~~~\n" + explanation + "\n~~~gdscript\n" + skin + "\n~~~\n\n## What can two lines do?" + exercise
(ROOT / "commons/maps/Point_Lines/tutorial.md").write_text(text, encoding="utf-8")
print("Published complete student code and helper in Point Lines tutorial.md.")
