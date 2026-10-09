"""Publish the two bounded Fractals lessons from their runnable source files."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STUDIES = ROOT / 'doc/book/studies/fractals-through-the-hands'

def code(hall, name):
    return f'<!-- student-code:{name} -->\n```gdscript\n{(STUDIES / hall / name).read_text(encoding="utf-8").rstrip()}\n```'

recursion = '''# Recursion — one more frame

**Learning elements**

- A function calling itself
- A smaller argument and a stopping condition
- A finite construction budget

In the museum, press MORE at the frame study. Another frame appears, smaller than the last. Change its arrangement and try the doorway version. A frame your eye can follow may be too small for your body. We will reconstruct the repeated frame; the room's doors and controls already exist.

## Continue with the line

You bring positions, lists, loops and functions from earlier halls. Keep the `LineSkin` supplied in Point Lines. Four segments make one square. The new operation is to call the square-making function again with a smaller size and one fewer step available.

Keep your previous study as a working version. Save `frames.gd` and `line_skin.gd` together and attach `frames.gd` to your existing, empty `PointStudy` Node3D in the prepared museum workspace. Use unit scale; position and rotate the station to face you. The museum supplies the camera, lights and player. This script creates only the study. Do not attach it to the museum's generator or remove the room's existing artifact.

## frames.gd

Run it with `depth = 3`. Predict the sizes before counting the visible frames.

{frames}

`repeat_frame()` receives the centre, the current size and the steps remaining. Its first `if` is the base case: when no step remains, or the square is smaller than our chosen limit, return without drawing.

Otherwise it draws one frame. The last line calls the same function with the same centre, a smaller size and `remaining - 1`. With the default values, the sizes are 1.8, 1.17 and 0.7605 metres. The next call receives zero remaining steps and returns. Each earlier call then finishes.

The loop in `draw_frame()` constructs four sides. Recursion repeats the whole construction. `(i + 1) % 4` returns to the first corner after the fourth; the last line closes the square.

`depth` controls how many frames may be made. `ratio` controls their relative sizes. They are separate choices. The small-size cutoff is another stopping condition: raising the depth does not guarantee that every allowed frame will be drawn. `clampi()` also caps scripted depth requests at seven; the limit applies beyond the Inspector slider.

## Supplied line skin — line_skin.gd

This is the same finite cylinder renderer from Point Lines, printed here so the example has no missing helper. Its thickness makes an abstract segment visible. Keep it unchanged for this lesson.

{line}

## Make a prediction of your own

Change `ratio` to 0.5 and keep `depth` at 3. Before running, write down the three sizes. They should be 1.8, 0.9 and 0.45. Explain why there are still three frames. Now set depth to zero: no frame should be created. Restore depth to three.

You should be able to change the reduction and predict the result without replacing the drawing function. The next hall keeps the stopping condition but lets a call make two children. Shorter pieces can then produce many more pieces.
'''.format(frames=code('Fractal_Recursion', 'frames.gd'), line=code('Fractal_Recursion', 'line_skin.gd'))

trees = '''# Recursive Trees — turn one fork

**Learning elements**

- Two recursive calls from one branch
- Parent and child transforms
- Inherited direction and length
- A local edit that preserves the other subtree

Press GROW beside the small tree. Hold one of its two points and turn the first branch. Its descendants follow. The other side stays. Look up: the large canopy receives the same edit. Release the point, then add another generation. Its new branches begin at the tips you moved.

The sphere still acts as a point you can hold. The line still gives two positions a visible span. We now arrange those spans in a hierarchy, so you can change a family of branches without dragging every endpoint.

## What continues

Keep the museum workspace, XR hands and the `LineSkin` from the previous lesson. Save `tree.gd`, `point_body.gd` and `line_skin.gd` together. On your empty `PointStudy` node, replace `frames.gd` with `tree.gd`; keep the frame script as your previous working version. Use unit scale and place the station with clear space in front of you. The script creates a small tree and two grips inside the existing museum environment.

This is the minimal reconstruction of the fork interaction. The museum artifact additionally supplies the growth buttons, readout, large solid canopy and alternative branching settings. Our study uses two children and a fixed 35-degree turn. Its `generations` Inspector value sets the whole tree before running. Re-run to rebuild; the study does not add another set of museum controls.

## tree.gd

{tree}

`branch()` makes a joint and draws one line upwards from it. It returns that joint, including anything attached below it. When `remaining` is zero, the visible branch is the last one: it gets no children. Here `generations` counts the generations **after the trunk**. Three gives 1 + 2 + 4 + 8 = 15 segments; four gives 31.

The two loop values give opposite turns. Each loop iteration calls `branch()` again with a shorter length and one fewer generation. The returned child is placed at the parent's tip, turned, then attached to that parent. Its children have already been made by the same rule. This is a depth-first construction: finish one subtree, then make its sibling.

Earlier, local and world coordinates described a point relative to a room. Here every child has a local position relative to its parent branch. `child.position = Vector3.UP * length` puts its origin at that parent's end. Moving or turning the parent carries the children through their existing attachments. The scene tree performs that inheritance; we do not recalculate every descendant in `_process()`.

The two grips control only the first fork. While one is held, we convert its world position into its branch parent's coordinates, subtract the attachment position and obtain a direction. `turn_fork()` aligns the branch's local Y axis to that direction. The quaternion line is a supplied alignment operation: it turns one axis towards another. Length is unchanged. The 12–65-degree limit keeps this particular hand study within a manageable arc; it is an interface choice, not a law of recursion. Pulling farther does not lengthen a branch.

On release, `park_point()` places the grip back at the represented endpoint. Its handle is an editing tool; it is not a free endpoint that stretches the branch. The other first fork has a different parented subtree, so turning one does not turn both.

## The familiar point — point_body.gd

This keeps the sphere, matching collider and frozen XRTools pickup construction from Point Lines. The radius is reduced to 8.5 cm for this small model. A material distinguishes the two grips. The small `held()` adapter also recognises the museum's existing desktop pickup and drop hooks. XR Tools still supplies the actual hand attachment; the tutorial does not rebuild the player.

{point}

## The same line skin — line_skin.gd

Keep this supplied renderer unchanged. The new work is the relationship between branches.

{line}

## Test a different tree

Set `generations` to 4. Predict 31 segments, then run. Turn the rose point out of the original plane. Follow one of its terminal twigs and compare it with a twig on the black side. The first must move; the second must stay. Release the point and check that no branch has gained length or lost its attachment.

Change `ratio` from 0.7 to 0.5 and run again. Predict which property changes and which stays: the tree reaches less far but still has 31 segments. This is the independent test of the lesson: distinguish a change in geometry from a change in the number of branches.

## Back at the large canopy

The museum source evaluates its branching rule through a queue of unfinished tips. GROW advances a complete generation; it does not use the depth-first call order of our small study. It also stores branch positions in one shared local frame. Its hand editor explicitly turns the selected branch records, their descendants and their pending tips. Our nested nodes make the same inheritance visible with less machinery. These are two implementations of the relation, not identical scripts or an exact geometric copy.

The small museum model and large canopy, however, really do share the source's branch records. Their scale differs; their branching decisions do not. ANGLE and LENGTH on the original desk change the whole rule and rebuild the specimen. The point grips make a local edit. Release both before using those controls or RESET.

Carry the bounded self-call onward. In Cantor Set, the next decision will be which part of an interval is retained, removed and passed to another call.
'''.format(tree=code('Fractal_RecursiveTrees', 'tree.gd'), point=code('Fractal_RecursiveTrees', 'point_body.gd'), line=code('Fractal_RecursiveTrees', 'line_skin.gd'))

for hall, text in [('Fractal_Recursion', recursion), ('Fractal_RecursiveTrees', trees)]:
    (ROOT / 'commons/maps' / hall / 'tutorial.md').write_text(text, encoding='utf-8')
    print(hall, 'published')
