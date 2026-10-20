from pathlib import Path
import json,re,shutil
R=Path(__file__).resolve().parents[1]
S=R/'doc/book/studies/lsystems-through-the-hands/LSystems_Growth'
M=R/'commons/maps/LSystems_Growth'
O=R/'doc/book/iterations/2026-10-09-growth-what-a-branch-keeps'
for name in ['point_body.gd','line_skin.gd']:
    shutil.copyfile(S.parent/'LSystems_Grammar_Lab'/name,S/name)
text='''# What a branch keeps

<!-- @parametric_lsystem -->

## Learning elements

- State stored in a dictionary.
- Copies rather than shared mutable records.
- A stack: last saved, first restored.
- Nested branches and balanced brackets.
- Replaying recorded states without rewriting the sentence.

In Grammar Lab we rewrote a sentence and read it as a path. Here the path forks. We keep the same point, cylinder renderer and replacement function. The reader gains a memory: it can leave a position, draw a branch, and return with its earlier direction and stride.

## Follow the existing drawing

At the desk in Growth, the first F has already drawn 0.8 metres. Its pale tip is the reader's position; the dark sphere in front of the controls is your handle. These have different jobs. The eleven-symbol sentence is `F[+F]F[-F]F`.

Press STEP, or hold the dark point and press its trigger. `[` saves a state. The tip stays where it is. The stack count becomes one; the next length becomes 0.576 metres. Step through `+` and F: turn, then draw. HOLD this reading before the closing bracket. Predict where `]` will put the live tip. It returns to the fork, while the branch remains visible. The next F resumes the trunk.

Finish the sentence and HOLD it. Move the dark point across the four ratios: 0.45, 0.72, 1.00, 1.15. At one, a branch has its parent's stride. Above one, it is longer. You are re-reading the same sentence. Both views use metres; neither fits itself to its plinth. The nearby RATIO button offers the same choices.

## Continue the student's code

Use the prepared Endless Museum project from Day Zero, with its player, camera, light and XRTools already running. Keep the Grammar Lab study in its own folder. Make a sibling folder for Growth containing these four files, and attach `growth.gd` to a new, empty Node3D on a clear museum floor patch. Keep the host at unit scale, its local +Z facing the visitor; allow about eleven metres of width and eight metres of height for the two full-size readings. The script builds its objects and labels itself. It has no named scene-child dependencies.

This is your reconstruction of the existing desk, not another hall. Keep the original artifact available for comparison. PointBody and LineSkin are unchanged carried files, printed at the end for completeness. The new code is the saved-state reader and its view. The drawings have no collision shapes; the small dark PointBody does.

The installed desk has six nearby VR buttons. The compact reconstruction uses the same held-point trigger for STEP, point movement for RATIO, and desktop Enter/H/T/R for STEP/HOLD/TREE/RESET. It does not recreate those six button scenes. Both versions begin after the first F; RESET restores that opening and its held copy. STEP reveals an already computed trace. TREE switches between one and two complete rewrites, showing the whole result.

## Save before changing

The reader's dictionary holds position, heading, length, turning angle and branch depth. `stack.append(state.duplicate(true))` stores a separate record. Appending `state` itself would retain a reference to the dictionary we are about to change: the supposed memory would change with it.

On entering a branch, length is multiplied by the chosen ratio and angle by 0.95. Here, 0.8 × 0.72 = 0.576 metres and 40 × 0.95 = 38 degrees. These are this artifact's choices, not requirements of every L-system. The fixed rotation axis keeps this reader planar. The production reader also carries orientation axes for its broader implementation; they reduce to this fixed plane in the zero-variation lesson.

`pop_back()` retrieves the most recent saved dictionary. That restores all its fields at once. A branch inside a branch returns to the inner fork first. Restoring the turtle does not remove endpoints already stored in `ends`.

The bracket check runs before drawing: a closing bracket needs a saved state, and every opening needs a return. This is an explicit learner-edit check. The production interpreter is more permissive with malformed strings; we compare their valid sentences, not their error policy. Unrecognized symbols pass through rewriting and draw nothing, as before.

### grammar.gd

`rewrite()` is unchanged from Grammar Lab. `read()` now returns endpoint data and independent frames, including START. Each frame records the state after one symbol and how many segments have been drawn. The endpoint array stores each segment's two ends; the return jump adds no segment.

'''
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf-8').rstrip()+'\n```\n'
text+=code('grammar.gd')
text+='''
## Read the same record in the room

`cursor` chooses a recorded frame. `snapshot()` copies that frame and the endpoints up to its segment count. HOLD saves this small reading, including its sentence, ratio and generation. Moving the point recomputes the live frames; it leaves the held copy intact. The hand is read in the study's local coordinates, so turning the study does not reverse its controls.

`set_tree()` first builds and checks a candidate. Only an accepted result replaces the live sentence and reading. The generation bound is two here; the inherited replacement function also refuses a whole rewrite above 4096 symbols. Neither limit measures biological growth.

The view uses the old cylinder renderer without fitting. Its pale tip is a visual marker, not another grabbable object. The short text window is labelled by symbol index; ellipses mean the display is abbreviated, not that the stored sentence has been cut.

### growth.gd

'''+code('growth.gd')
text+='''
## Check the return

From RESET, take three steps, then HOLD. You have read `[`, `+`, F. The live tip is at the branch end, the stack has one record and the next length is 0.576. One more step restores position (0, 0.8, 0), heading up, length 0.8, angle 40 and depth zero. There are still two drawn segments. One further step ends at (0, 1.6, 0). A diagonal connector between the branch tip and fork would be a bug.

Complete the sentence: eleven symbols make five segments. At ratio 1.15, a child stride is 0.92 metres. T requests generation two: sixty-one symbols, twenty-five segments, a trunk reaching 7.2 metres above its start. A twice-nested stride is 1.058 metres. Rewriting generation and stack depth are different counts.

Now edit only RULE in your copy to `{"F": "F[+F[-F]F]F"}`. Before running it, mark the two returns. The inner `]` must recover the outer branch's heading and 0.576-metre stride; the outer `]` recovers the trunk's 0.8-metre stride. In generation one, predict five segments and a final tip at (0, 1.6, 0). Run it, step through the returns, and explain why restoring position alone would fail. Then remove a closing bracket: the reader must report the unmatched opening instead of presenting a partial drawing as complete.

The repository's native Godot checks extract these exact printed files, run the nested-rule edit as a separate program, compare valid states and endpoints to the installed generator, and exercise the actual XRTools pickup/action/release with supplied poses. Those checks establish executable behavior; a student explaining the return and a physical headset session remain separate evidence.

## Carried files

These files keep their previous jobs. PointBody is the hand-sized grabbable sphere. LineSkin gives two endpoints a visible cylinder. They are included unchanged so the complete reconstruction has no missing helper code.

### point_body.gd

'''+code('point_body.gd')+'\n### line_skin.gd\n\n'+code('line_skin.gd')
text+='''
## What travels onward

Keep the rewritten sentence, the reader and the saved-state operation. The other growth studies remain available in the hall; they are not prerequisites for reconstructing this branch. In Grammars and Curves, the question changes: how much of a form comes from its sentence, and how much from the way we read forward and turn?

<!-- @ -->
'''
(M/'tutorial.md').write_text(text,encoding='utf-8')
final=(O/'before/commons/maps/LSystems_Growth/final.md').read_text(encoding='utf-8')
start=final.index('After saving, the source changes two values')
end=final.index('Position returns, the orientation axes return')
final=final[:start]+'''After saving, the branch takes a shorter stride: 0.8 × 0.72 gives 0.576 metres. Its turn narrows from forty degrees to thirty-eight. F still means draw forward, but how far forward now depends on the state in which the turtle reads it.

At the closing bracket, the most recently saved record becomes the present again.

'''+final[end:]
final=final.replace('Press STEP once. Nothing extends.', 'The dark sphere in front of the desk has come with us. Its held trigger steps through the reading; moving it across the marked ratios changes the branch length. The pale tip belongs to the drawing. One point is in the hand, the other records where the sentence has arrived.\n\nPress STEP once. Nothing extends.')
(M/'final.md').write_text(final,encoding='utf-8')
p=M/'map_data.json';d=json.loads(p.read_text(encoding='utf-8'))
assert d['layers']['utilities'][26][9] in ['', 't']
d['layers']['utilities'][26][9]='t'
p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Growth: full tutorial, carried files, reflection and onward token written.')
