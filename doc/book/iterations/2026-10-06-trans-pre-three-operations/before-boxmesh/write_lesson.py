from pathlib import Path
import re, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def put(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding='utf-8', newline='\n')

def main():
    for relative in ['commons/maps/Trans_Pre/tutorial.md', 'commons/maps/Trans_Pre/final.md', 'commons/maps/Trans_Pre/map_data.json',
                     'doc/book/course/execution-plan/plan.json', 'doc/book/course/execution-plan/authorized-revisions.json',
                     'doc/book/course/hall-cards/lineage-opening.json', 'doc/book/course/hall-cards/state.json',
                     'doc/book/course/storyboards/opening.json', 'doc/book/course/storyboards/CONTEXT.md']:
        source = ROOT / relative
        target = HERE / 'before' / relative
        if source.exists() and not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)
    predecessor = (ROOT / 'commons/maps/Point_Animatedcube/tutorial.md').read_text(encoding='utf-8')
    for name in ['cube_body.gd', 'face_body.gd', 'line_skin.gd']:
        blocks = re.findall(r'<!-- student-code:' + re.escape(name) + r' -->\s*```gdscript\n(.*?)^```', predecessor, re.M | re.S)
        assert len(blocks) == 1, name
        put(HERE / name, blocks[0])
    def code(name):
        return '<!-- student-code:' + name + ' -->\n```gdscript\n' + (HERE/name).read_text(encoding='utf-8') + '```\n'
    text = '''# Move, turn, change size

**Learning elements**

- Translation: position
- Rotation: orientation and an axis
- Uniform scale: size and proportion
- Node origin: where a change is anchored
- Animation: a transform changing over time

Walk past the four cubes in Trans_Pre. One stays still, one rises, another adds a turn, and the last changes size as well. Follow a corner. Which changes belong to its journey, and which change the body itself?

Bring **CubeBody** from the Cube lesson: the same eight corners, twelve faces and dark edges. In Melencolia, you placed instances of it. Here you will change one instance's position, orientation and size while keeping its construction. Begin with a still pose. A transformation does not need an animation.

## The study beside the encounter

The existing Endless Museum supplies the room, player, camera and lighting. In your working museum scene, add one empty `Node3D` named `TransformStudy` in a clear floor space beside the row. Give that study root zero rotation and unit scale; its origin sits at floor level. Attach `lesson.gd` below. Its positions are local metres relative to that root, as in Coordinates.

Keep `cube_body.gd`, `face_body.gd` and `line_skin.gd` beside it. They are unchanged from [Cube](../Point_Animatedcube/tutorial.md); their complete listings are retained below. The main script creates its own cube. It does not look up or modify an installed exhibit. This study has visible geometry; the hall's pickup and collision behaviour remain supplied.

## One cube, three changes

Save this complete main script as `lesson.gd`.

'''+code('lesson.gd')+'''
Initially the cube stays still. `rise` is zero, so the running clock makes no change to its position. `_ready()` attaches the cube and sets its starting pose; `_process()` will let us animate its position later. The assertion requires a positive duration and size.

Our cube's corners run from −0.5 to 0.5 along X and Z, and from 0 to 1 along Y. Its origin is therefore the **bottom centre**, not the middle of its volume. At the starting pose, its bottom is one metre above the study root and its top is two metres above it.

Change one value and run again. Restore the starting values before each comparison.

| Change this value | Look for this result | What stays the same |
| --- | --- | --- |
| `start = Vector3(1, 1, 0)` | The whole cube is one metre farther along X. This is **translation**. | Every corner receives the same displacement. Facing and edge lengths remain fixed. |
| `turn_degrees = 45.0` | The cube turns around its upright Y axis through its origin. This is **rotation**. | The origin and distances between corners remain fixed. |
| `size_factor = 1.5` | The edges become 1.5 metres long. This is **uniform scaling**. | All dimensions receive the same factor, so proportions remain fixed. |

Edit the values on their existing `var` lines; do not add new declarations. Each assignment changes a property of the cube node. Its surface and edges follow that node. Its stored corner list still describes the original one-metre cube.

During scaling, the bottom centre stays at `start`; the top rises. That follows from our chosen origin. Rotation around Y also passes through the cube's middle, because the bottom centre lies on the same upright axis. We will move the pivot in the Rotation hall.

## Give translation a duration

Restore `start`, `turn_degrees` and `size_factor`, then change `rise` to `1.0`. The cube now travels one metre upward in two seconds and stops.

`elapsed += delta` adds the seconds since the previous frame. Dividing elapsed time by `duration` gives the fraction of the journey completed. `minf(..., 1.0)` keeps that fraction at one after arrival. Half a second gives `t = 0.25`; one second gives `t = 0.5`.

The last line adds an upward displacement to the starting position. At the halfway point it adds half a metre; at the end it adds one metre. This is linear interpolation written as **start + displacement × fraction**. Each frame assigns a position measured from the same start. It does not add that entire position to the previous one.

Set `duration` to `4.0`. The destination stays fixed and the journey takes twice as long. Turning and size have not changed. More rendered frames give more intermediate poses; they do not shorten the journey.

The hall combines rising, turning and pulsing. Our first animation isolates translation. With `rise` still at one, set `turn_degrees` to 45 and `size_factor` to 1.5: the enlarged, turned cube now rises without changing its facing or size during the journey. A fixed turn and a continuously turning body are different choices. The later halls develop those choices separately.

## Make another pose

Return to a still cube. Choose a different angle around Y. Before running it, name one corner that should move and one distance that should stay fixed. Then try the change. A quarter-turn can recover the cube's outline even though a particular corner has moved; an angle such as −30 degrees makes the change easier to see.

Carry the three properties onward: **position, orientation, scale**. The construction can stay the same while its relation to the surrounding room changes. In the next hall, those changes make different kinds of crossing.

## Returning code

These three files return unchanged from Cube. You need them beside `lesson.gd`; their geometry is already part of the student's code corpus. Read the main script for this lesson's new operations.

### cube_body.gd

'''+code('cube_body.gd')+'''
### face_body.gd

'''+code('face_body.gd')+'''
### line_skin.gd

The face renderer sets each edge's material to dark gray; the helper's earlier pink default is not used by this cube.

'''+code('line_skin.gd')+'''
## Executable check

The [lesson files and review](../../../doc/book/iterations/2026-10-06-trans-pre-three-operations/index.html) include the exact printed program, edited variants and native Godot evidence. Checks compare corner positions, distances, construction data and elapsed time. They do not establish that a reader can yet explain the changes or verify headset comfort.
'''
    put(ROOT/'commons/maps/Trans_Pre/tutorial.md', text)
    put(HERE/'tutorial.md', text)

if __name__ == '__main__':
    main()
