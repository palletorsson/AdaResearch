from pathlib import Path
import shutil
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/LSystems_Grammars_And_Curves'
S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Grammars_And_Curves'
O=R/'doc/book/iterations/2026-10-09-curves-one-sentence-three-readers'
for name in ['point_body.gd','line_skin.gd']:shutil.copyfile(S.parent/'LSystems_Growth'/name,S/name)
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
text='''# One sentence, three readers

<!-- @the_believing_turtle -->

## Learning elements

- Separate a symbol from the operation that interprets it.
- Separate stored heading from drawing direction.
- Compare readers with the sentence and stride held fixed.
- Exchange vector components: reflection and its preserved relations.
- Use a return value without changing the state passed to a function.

Growth gave our reader a memory. Here we reuse its stack, the replacement function, PointBody and LineSkin. One small function now stands between a heading and the next movement. The subject is interpretation: the same F can have another consequence.

## Begin inside the museum

The believing turtle presents three readers of one sentence. All begin after the first F, taking 0.32 metres upward. The green reference stays at 25 degrees. The middle reader can change its turn angle. The blue reader can exchange x and y when it draws.

Take the familiar dark sphere and press its trigger, or press READ F on the desk. The blue line goes sideways. Its gold direction marker still points up; its white marker points across. Gold shows the stored heading. White shows the direction of the next drawing step. You changed the interpretation, not the heading or the sentence.

Move the held sphere to 45; the nearby ANGLE button makes the same choice. The middle reader's first F stays upright. The new angle has not reached a turn yet. Press STEP five times. At symbol six, the first branch segment makes the changed turns visible. The same cursor follows all three readings.

Finish the twenty symbols, then choose TREE. Its second generation has 172 symbols and 64 drawn segments per reader. Find a blue fork and its green counterpart. Every segment retains its length. No drawing is fitted to its case. The map's original lectern, curve gallery and later tube bay have their own conditions; they are not extra copies of this controlled comparison.

## Carry the code, name the changes

Keep Growth's study intact. Make a sibling folder containing the four complete files below. In the prepared Endless Museum project, attach `readers.gd` to an empty Node3D on a clear floor patch, at unit scale with local +Z facing the visitor. Allow about fifteen metres of width and six metres of height for the full-size comparison. The museum supplies its existing player, camera, lighting and XRTools. The script creates its point, drawings and labels, without named scene-child references.

The dark sphere still controls the reader. Its **trigger now means READ F**, exchanging the blue direction; its X position selects the **middle angle**. The installed desk retains STEP, READ F, ANGLE, TREE, RESET and RULE. The compact reconstruction uses Enter for STEP, Space for READ F, T for TREE and R for RESET. It creates no replacement VR button system. STEP wraps from the last frame to START; RESET returns to the first F and the original readers.

Three decisions differ from Growth because we are reconstructing this artifact:

| Decision | Growth | This comparison |
|---|---|---|
| Stride | 0.8 m, multiplied on branch entry | 0.32 m everywhere |
| Turn | `+` turns about negative Z; branch angle shrinks | `+` turns about positive Z; each reader keeps its chosen angle |
| Saved state | Position, heading, length, angle and depth | Position and heading; stride and angle are fixed for that reading |

Here the alphabet is F, +, −, [ and ]. Growth's optional G/f handlers are not used. Other symbols survive rewriting but have no drawing action in this reader. These are declared interpreter choices, not changes to what the symbols universally mean.

The stack still saves a separate dictionary and restores the last one first. The bracket preflight stays. The replacement function is unchanged. PointBody and LineSkin are the same carried files, printed at the end.

## Put the decision in a function

`direction()` receives a heading and returns a vector. In forward mode it returns that heading. In sideways mode it constructs (y, x, 0). Calling it does not assign a new value to `state.heading`. F uses the returned direction to advance; the next turn still changes the stored heading.

The production artifact stores heading as an angle, initially PI/2, and computes (cos heading, sin heading). Our reduced reader keeps Growth's unit vector. Turning that vector about positive Z gives the same directions for this planar lesson. The comparison tests both against the actual artifact.

The swap preserves a planar vector's squared length: x² + y² becomes y² + x². Applied to every step from the same origin, it reflects every endpoint across x=y. Branch returns preserve that correspondence. This does not add joints wherever lines happen to cross. It also does not make a colliding surface.

### grammar.gd

'''+code('grammar.gd')+'''
## Three results from one input

`reinterpret()` sends one stored sentence to the three readers. Changing the middle angle or the blue mapping does not rewrite it. `set_tree()` is the separate operation that builds one or two generations, checks the result, then commits it.

Each reading records a frame after every symbol. The shared cursor selects the same symbol in all three. As in Growth, STEP replays stored results; it is not a paused interpreter. The marker positions are calculated in local coordinates before adding three display origins. Those offsets separate the views; they are not part of the reflection.

The pale tip marks position. The gold and white short rods show heading and next drawing direction, with small Z offsets so both remain visible. The installed museum uses arrowheads; the reduced view reuses LineSkin. Rod length is a display choice; it does not change the 0.32-metre stride. All three origins sit 2.2 metres above the study floor so the reflected downward branches remain visible.

### readers.gd

'''+code('readers.gd')+'''
## Predict a different reader

At RESET, all first endpoints are (0, 0.32, 0) relative to their origins. READ F moves only the blue one to (0.32, 0, 0). Its heading remains (0, 1, 0). Change the middle angle: its first endpoint stays fixed. Advance to the first branch at symbol six to see that angle take effect. Return READ F to forward: the blue and reference endpoints must agree again.

For your own reader, change only the sideways expression in `direction()` from `Vector3(heading.y, heading.x, 0)` to `Vector3(-heading.y, heading.x, 0)`. Predict the first blue step before running: it should go left. The new rule rotates every planar direction a quarter turn. Check an off-axis branch too; an upright line alone cannot distinguish every mapping.

Keep the sentence, stride and stored headings. Compare lengths and the order of endpoints. A reflection reverses the orientation of a pair of directions; this quarter turn preserves it. Applying the original swap twice returns a vector to itself. Applying your new mapping twice points it backwards; four applications return it. Execute the edited file, then explain why changing `state.heading` instead would mix two decisions that this lesson keeps separate.

Repository tests extract these exact files, execute that altered mapping as a separate program, and compare the base reader's valid states and endpoints with the existing artifact. They also exercise the actual XRTools pickup/action/release with supplied poses. This tests the program and the interaction binding; it does not replace a student's explanation or physical headset review.

## Carried files

### point_body.gd

'''+code('point_body.gd')+'\n### line_skin.gd\n\n'+code('line_skin.gd')+'''
## From a read path to a surface

Carry the sentence, the copied stack and the distinction between heading and displacement. Architecture will ask what an interpreted plan needs before a body can occupy it.

The existing tube bay offers an optional return to Trace, rings and mesh faces. Its making notes follow, intact. That larger workbench supplies its own construction and interface; it is not secretly a dependency of the four-file reader above. The code reconstruction and new tests in this pass cover the three readers. Sweeping, frame transport, patching sound and the canopy remain distinct applications with their own existing sources and checks. No automatic transfer of this generated path into the tube workbench is claimed.

<!-- @ -->

## Optional applications — existing tube-bay notes

'''
previous=(O/'before/commons/maps/LSystems_Grammars_And_Curves/tutorial.md').read_text(encoding='utf-8')
application=previous[previous.index('<!-- study-spine:tube_painting -->'):]
text+=application
(M/'tutorial.md').write_bytes(text.encode('utf-8'))
final=(O/'before/commons/maps/LSystems_Grammars_And_Curves/final.md').read_text(encoding='utf-8')
a=final.index('Here is the direction calculation in the believing turtle:')
b=final.index('Try to match every blue fork to a green one.')
final=final[:a]+'''The stored heading supplies two components of a direction. One reading follows them; another exchanges them before taking its next step. The instruction has stayed in place while its consequence has moved. These drawings remain planar inside the three-dimensional room.

'''+final[b:]
final=final.replace('Press READ F. The blue line goes sideways.', 'The familiar dark point waits in front of the controls. Move it to change the middle reader’s angle; its held trigger exchanges the blue reader’s direction. The same two decisions are available on the nearby buttons.\n\nPress READ F. The blue line goes sideways.')
(M/'final.md').write_bytes(final.encode('utf-8'))
assert (M/'tutorial.md').read_text(encoding='utf-8').endswith(application)
print('Complete reader tutorial; optional tube notes preserved; reflection updated.')
