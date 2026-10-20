"""Keep the museum reflection; replace the source survey with one reconstruction."""
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[1]
HALL=ROOT/'commons/maps/Random_Walk'
STUDY=ROOT/'doc/book/studies/randomness-lineage'
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Walk'

def main():
    tutorial='''# A point keeps its steps

## Learning elements

- A sampled heading becomes a displacement.
- Position accumulates steps.
- A boundary changes a proposed endpoint.
- A trail records accepted positions without steering the walk.
- Repeating a walk requires its start, rule and generator state.

Find the glass terrarium. Follow the red bead in 2D mode. Its direction keeps changing, yet it stays on one level. The other four beads still move. ONE changes what is easy to follow; it does not remove the rest.

Random Rotate kept adding turns. Now our familiar PointBody adds displacements. Coordinates supplies the local frame, Lines the connecting cylinder, and Trace the list of retained positions. We will build one planar walker. The cabinet's 3D and LONG STEP modes remain comparisons to visit afterwards.

## Give the point a rule

Work in your copy of Endless Museum. Add an empty `Node3D` under Random Walk and attach `07_a_point_keeps_steps.gd`. Place `point_body.gd` and `line_skin.gd` beside it. They are the existing point and Trace renderer, printed below without changes. Day Zero supplies the player, camera, lighting and XR Tools. The new script constructs its own table, boundary and labels. These display meshes add no collision.

The reconstruction was checked at hall-local position `(4, 0, 7)`, with no rotation. Leave room on its positive-Z side for your body to approach. This is a temporary work station in your copy of the museum; the installed terrarium remains beside it.

The point begins at the centre and takes one step every quarter-second. **Pick it up to pause.** Ordinary release projects your chosen starting place onto the tabletop plane, clamps that start inside the square, clears the previous trail and restarts the seeded walk. To repeat the last run from its previous start, **press the trigger while holding the point, then release it**. That combination ignores the new hand position. The label shows which release is pending.

This deliberately changes the role of the hand. In Trace, we recorded where you carried the point. Here holding pauses the generator; release supplies a start. The program then chooses the steps. The point remains the same class.

Read `step()` first. It draws, adds, folds and records.

<!-- student-code:07_a_point_keeps_steps.gd -->
```gdscript
__MAIN__
```

## Follow one step

`rng.randf() * TAU` chooses an angle around the circle. Sine and cosine return from Wavefunctions: together they turn that angle into a unit heading in XZ. Multiplying by `step_size` makes a 12-centimetre displacement. The Y component is zero.

`proposed = current + displacement` starts from the position already reached. Assigning only the displacement would instead keep placing the point near the origin. One random number chooses the new heading; the preceding heading and the drawn trail do not enter that choice.

`reflect_endpoint()` folds any overshoot back into the square. At the right boundary, `x = 0.85`, a proposal of `0.90` becomes `0.80`. Clamping it to `0.85` would be a different rule. The four tests act on X and Z independently, so a proposal can fold at a corner too. This small implementation assumes each step is shorter than the square's width; the supplied step-size range stays within that assumption.

We connect the old position to the accepted endpoint, then store that endpoint. The line does **not** include a wall-contact point. Near an edge, a displayed segment may therefore be shorter than the proposal. The bounds apply to the point's centre; this is a geometric rule, not a rigid-body collision with a glass wall.

## Keep the record separate

`positions` begins with the starting position. Every event appends one accepted position. After 64 steps it contains 65 entries, and the trail contains 64 segments. The point sits at the latest entry. Unlike the cabinet's rolling window of older samples, this small study keeps the whole run, up to 128 steps.

`current` is the state used by the next step. The `positions` list is its account. Neither the list nor the segment nodes are consulted when drawing another heading. Clear those records while retaining `current` and the generator state: the next position remains the same. A self-avoiding walk would need to read its history when choosing where it may go.

The record and all segment endpoints use the lesson root's local coordinates. Turning or moving the whole station carries the drawing with it. Ordinary release converts the point's global hand position back into that local frame before choosing a new start.

## Keep time and replay explicit

The timer comes from Random Rotate. Each complete interval produces an event; `while` lets a slow frame contain several. The finite step budget bounds the work. Holding the point consumes no steps or random draws. Release resets the timer along with the run.

The point still has the frozen physics body introduced for pickup. `_physics_process()` keeps that body at `current` while it is free, including after the run completes. It stops assigning the position while you hold the point, so the hand can carry it. This display update draws no random number and takes no new step.

Here replay rebuilds the path from the same **origin, seed, step size, boundary rule and draw order**. It does not play an already stored path, as the previous lesson played its saved angles. The seed alone is insufficient: starting near an edge changes where the same proposals are folded. This comparison uses the same Godot version; a seed is not a promise of identical results across engine versions.

The installed cabinet also uses a step timer, but accepts at most five batches per drawing frame and discards excess time. Its RESET retains a partial timer. Compare its replays by step count, not by assuming the same wall-clock history. The learner study keeps a simpler finite run and clears its timer on restart.

## The constructions you already have

Keep these two files unchanged. PointBody supplies the sphere, collision shape and inherited pickup signals. LineSkin turns two endpoints into a visible cylinder; it does not make a wall or a physical string.

<details>
<summary>Complete PointBody and LineSkin dependencies</summary>

<!-- student-code:point_body.gd -->
```gdscript
__POINT__
```

<!-- student-code:line_skin.gd -->
```gdscript
__LINE__
```

</details>

## Make a change you can explain

1. Change `step_size` from `0.12` to `0.24`, leaving the seed and start at the centre. Before either path reaches an edge, its displacement from the start doubles. After a reflection the paths need not be scaled copies. Predict the first two endpoints, then compare the runs.
2. Change `seconds_per_step` from `0.25` to `0.5`. At an equal step count the path is unchanged; reaching that count takes longer. Separate changing the rule from changing its pace.
3. In `step()`, replace the call to `reflect_endpoint(proposed)` with `Vector3(clampf(proposed.x, -HALF, HALF), HEIGHT, clampf(proposed.z, -HALF, HALF))`. A proposal at x = 0.90 now ends at 0.85. The draws have not changed; their treatment at the boundary has. Restore reflection afterwards.

For an independent check, put the start near one corner. Choose a proposed displacement that exceeds both edges. Work out the folded endpoint before running the program, and explain why the visible connecting segment does not show a bounce. The code checks exercise that corner case, source edits, replay, held time and the distinction between a record and a steering rule.

## Return to the hall

The terrarium's five walkers share a generator. One planar step consumes one draw per walker. Its 3D direction consumes two, and LONG STEP adds another to choose a bounded length. Switching modes therefore changes both the geometry and how the stream is consumed. Its trail keeps previous positions and omits the bead's current one; our list includes the current endpoint. Both conventions are explicit choices about what a trail retains.

Visit the two rails next: a new position and an accumulated displacement are given the same input. Then try the held drawing dot, where the hand carries an origin and chance moves a tip around it. Across the basin, revisited cells raise the ground. These artifacts extend the question without adding three more required programs to this lesson.

Next is Random Gaussian. Keep the sampled values long enough to ask how they are distributed. A tangle shows an order of visits; a histogram will group values and leave that order out.
'''
    for tag,name in [('MAIN','07_a_point_keeps_steps.gd'),('POINT','point_body.gd'),('LINE','line_skin.gd')]:
        tutorial=tutorial.replace('__'+tag+'__',(STUDY/name).read_text(encoding='utf8').rstrip())
    (HALL/'tutorial.md').write_text(tutorial,encoding='utf8')
    text=(OUT/'before/commons/maps/Random_Walk/final.md').read_text(encoding='utf8')
    text=re.sub(r'\n```gdscript\n.*?\n```\n','\n',text,flags=re.S)
    text=text.replace('In 2D, one number becomes a heading:', 'In 2D, one number becomes a heading around a circle.')
    text=text.replace('and for how much less often a bead returns to a patch it has already worn', 'and ask whether a bead returns less often to a patch it has already worn')
    text=text.replace('The cabinet is using this particular rule:', 'Its length comes from an inverse-square-root rule.')
    text=text.replace('A rare long step is what a walker takes to leave a well-trodden patch: the rule a forager might use, and the remedy for what the field beyond the basin will show you.', 'A longer proposal can carry it out of a patch it has repeatedly crossed. Does that change its returns? This cabinet gives you a comparison to watch; it does not establish a better search strategy.')
    text=text.replace('First the code proposes a position; then the enclosure changes it:', 'First the code adds a step to the position already reached; then the enclosure folds the proposed endpoint back inside.')
    text=text.replace('The next few lines keep another difference:\n\n\nRead the order aloud.', 'The record keeps another difference. Read the order aloud.')
    text=text.replace('A walker that keeps returning is oversampling, and this ground is a count of it; the terrarium\'s long steps are one way out.', 'This ground counts its returns. Whether returning too often is a problem depends on what we wanted the walker to do; the count alone cannot supply that purpose.')
    text=text.replace('The next step starts from the offset already reached:', 'The next step starts from the offset already reached.')
    text=re.sub(r'\[\^levy\]:.*', '[^levy]: The source retains the name Lévy flight. This particular sampler is bounded: its offset and exponent limit the proposal even before the enclosure folds it. The name does not make this an unbounded Lévy process or establish a model of animal foraging.',text)
    text=text.replace('Stay with a shape you had begun to read as a creature.', 'In the tutorial, the point leaves your hand and starts choosing its steps. You have supplied a place to begin. The trail makes those choices available to you without making them available to its next heading.\n\nStay with a shape you had begun to read as a creature.')
    text=re.sub(r'\n{3,}','\n\n',text)
    (HALL/'final.md').write_text(text,encoding='utf8')

if __name__=='__main__':main()
