"""Write the rotation pair from preserved source and the tested learner listing."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
HALL=ROOT/'commons/maps/Random_Rotate_Random_XYZ'
STUDY=ROOT/'doc/book/studies/randomness-lineage'
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Rotate_Random_XYZ'

def main():
    code=(STUDY/'06_turns_kept.gd').read_text(encoding='utf8').rstrip()
    point=(STUDY/'point_body.gd').read_text(encoding='utf8').rstrip()
    tutorial='''# Keep the turn

## Learning elements

- Assigning an angle and accumulating a turn.
- Signed increments: a later turn can undo an earlier one.
- One recorded input, two interpretations.
- A timed step, independent of the drawing frame.
- Replaying a record without drawing again.

Find the two upright stacks. Wait after RESET. Their pieces keep their places while small turns build on previous turns. The shapes have not become different meshes. Their orientations carry a history.

In Random Cubes, each result added to a total. Here the cube returns, but the contribution is a signed angle. Transformation taught us to turn a whole body. We will give two identical cubes the same list of angles: one takes the latest value, and the other keeps the sum. The PointBody you already made operates the comparison.

## Build the comparison in the hall

Work in your copy of the prepared Endless Museum. Add an empty `Node3D` under Random Rotate and attach `06_turns_kept.gd`. Keep the unchanged `point_body.gd` beside it. Day Zero supplies the player, camera, light and XR Tools. The script creates both cubes, their marks, plinths and labels; these display meshes have no collision. A tested temporary position is hall-local `(3, 0, 7.5)`, Y rotation **90 degrees**, facing into the room.

Hold the point above **STEP** and press the trigger. Both cubes receive the next recorded angle. Over **PLAY / PAUSE**, the same action starts or pauses timed stepping. **REPLAY** returns both cubes to zero and the cursor to the start; STEP then reads the same turns again. At the end, PLAY starts that record again. These controls read the point's position relative to the lesson root.

Read `step()` first. The remaining functions make that short operation visible and repeatable.

<!-- student-code:06_turns_kept.gd -->
```gdscript
__CODE__
```

## One value, two operations

`make_record()` prepares a finite list of 24 angles. Each draw lies between −20 and +20 degrees; `deg_to_rad()` converts it to the radians the rotation uses. The list is already complete before either cube turns. The seed identifies this generator procedure; it is not a promise of the same numbers in every future engine version.

`cursor` is the next unread address. In `step()`, `latest = turns[cursor]` replaces one value. `total += latest` retains the preceding total and adds the new value. Both operations use the **same** entry; a second draw would make the comparison harder to interpret.

Suppose the list begins **+10°, +10°, −5°**. The left cube takes orientations **10°, 10°, −5°**. The right reaches **10°, 20°, 15°**. A bounded increment does not impose the same bound on the sum. Negative increments can cancel positive ones, so accumulated turning need not move steadily farther from zero.

`Basis(TURN_AXIS, angle)` gives the whole cube an orientation around one unit axis. `Vector3.BACK` is local positive Z: the cube turns in the plane facing you. Its position and mesh stay unchanged. The off-centre pink mark lets you distinguish orientations that an unmarked cube's symmetry could conceal. [Godot: Basis](https://docs.godotengine.org/en/stable/classes/class_basis.html)

The sum is retained separately from the rendered orientation. After a full turn the cube can look unchanged while the stored total has increased by 360°. The displayed body alone cannot recover all the turns that led to it.

## Time reads the record

`_process(delta)` receives elapsed seconds. It accumulates that time, then uses `while` to consume every complete 0.8-second interval. A slow drawing frame may contain several lesson steps. A faster monitor does not create extra random draws: playback only reads the saved list.

Pause keeps a partly completed interval. REPLAY clears it. Manual STEP also clears it and pauses playback, so your press is the next event rather than an extra step immediately before a timed one. The last entry stops playback. The guard at the start of `step()` prevents reading past the list.

REPLAY never calls the generator. `make_record()` does: it resets the seed, replaces the list, then resets playback. This distinction matters in the installed stack, whose RESET aligns the pieces but does **not** rewind its generator.

## The point is still your point

This is the existing PointBody dependency. Keep your copy; it is printed here so the complete example can be reconstructed without a prepared mesh child. Its inherited pickup behaviour stays the same. What its action does belongs to this lesson.

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

## Change one thing and predict it

1. Step once. Predict why the orientations agree. Step again and explain why they can separate even though their inputs remain identical.
2. Change `limit_degrees` from `20.0` to `40.0`, leaving the seed and entry count alone. In this generator implementation the signed entries double. At the same cursor, both numeric angles double; the visible pose can wrap around a full turn. Compare the labels as well as the cubes.
3. Change `TURN_AXIS` from `Vector3.BACK` to `Vector3.RIGHT`. Keep the original angle record. The same values now pitch the cubes around local X. What changed is the axis of interpretation, not the random numbers. This does not sample all spatial orientations: that is a different problem.
4. Before running it, predict a record containing **+10°, +10°, −5°**. For a controlled exercise, replace the drawing loop in `make_record()` with `turns.assign([deg_to_rad(10.0), deg_to_rad(10.0), deg_to_rad(-5.0)])`. Keep its final `replay()` call. Explain both labels after the third step, then replay and check again.

The code checks reconstruct the printed files, compare the amplitude and axis edits, test this supplied record, and deliberately break accumulation, replay and timing. Passing those checks establishes what the program does. Your own explanation of a new record is the further test of understanding.

## Return to the larger stack

Our two cubes isolate addition. The installed display also keeps angular velocity and an authored wear value; random kicks alter that state before it updates the angle. It currently updates per rendered frame, so a seed alone does not make its timing or trajectory match across frame rates. The learner comparison deliberately uses fixed record-reading intervals. It is a reconstruction of the central relation, not a replacement implementation of the full exhibit.

The nearby weathering rig reacts to movement without drawing random numbers. Neither that input nor mixing values from a software clock establishes a hardware random source. Keep the source of a change separate from how the change looks.

Carry the distinction into Random Walk. The cube has kept a sum of turns; the point will keep a sum of displacements. Trace's list returns so you can see where those steps have taken it.
'''
    (HALL/'tutorial.md').write_text(tutorial.replace('__CODE__',code).replace('__POINT__',point),encoding='utf8')
    final=(OUT/'before/commons/maps/Random_Rotate_Random_XYZ/final.md').read_text(encoding='utf8')
    final=final.replace('Which part of an arrangement can change while its pieces remain?', 'The last room kept adding the results of a throw. Here a contribution can also take something back. Which part of an arrangement can change while its pieces remain?')
    final=final.replace('without any piece moving, shrinking, disappearing', 'without any piece changing place, shrinking, disappearing')
    final=final.replace('Give it minutes. Half a minute after a RESET the average piece has turned by about a degree, after five minutes by several, and exactly how many depends on the machine drawing the room.', 'Give it time. The implementation takes a new update on each drawn frame, so how far it turns also depends on the machine drawing the room. Its apparent patience is partly a setting and partly a condition of its execution.')
    final=final.replace('At its defaults the display runs the cubes three times as fast as the prisms, and the cubes turn several times as far. That difference is mostly the setting, not the shape.', 'Outside this room’s comparison, the default settings give the cubes a higher rate than the prisms. A difference produced by that setting would not establish a difference caused by shape.')
    final=final.replace('Here each piece shows only where its turns have added up to;', 'The tutorial holds two cubes beside one another and gives them the same recorded turns. One takes the latest value; the other adds it to what came before. On the first step they agree. Later, the difference belongs to what each cube retains. To give two things the same input is not yet to give them the same history.\n\nHere each piece shows only where its turns have added up to;')
    (HALL/'final.md').write_text(final,encoding='utf8')

if __name__=='__main__': main()
