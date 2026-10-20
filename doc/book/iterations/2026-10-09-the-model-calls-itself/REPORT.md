# The model calls itself

**PREVIEW ONLY · built in Godot · no museum map or route placement.** This is one new controllable artifact with three model-level fault studies. The room in the images is a separate research preview, using the existing Ada desktop player and interaction controls.

**[Explore the native models in 3D](/research/model-overflow/index.html#calls)** — orbit, zoom, compare saved states, and reveal the triangle edges. Use the Godot scene for live stepping and capacity changes.

![Twenty admitted calls; the next bay is shown pink and refused.](museum/calls.png)

The earlier architectural bay becomes a procedure that does not know when to return. Each child inherits another turn, translation and small increase in scale. The result curls out of reach. Beside it, a stack of pink plates counts the pending frames. The ordinary bay remains on its plinth.

## Three failures, three different models

| Study | Operation | What changes in the model | What stops it |
|---|---|---|---|
| Calls without a base case | Each simulated call requests a child before returning | A chain of inherited transforms builds a rising curl | The next frame is refused at the selected capacity |
| Forgotten restore | Save a transform, make a sibling, omit restoration | Each sibling inherits all the previous transformations | Sixteen requested siblings, or the selected frame limit |
| Wrapped vertex writes | A second model reuses the first model's vertex addresses | Old faces stretch between newly written and retained positions | A fixed 228-slot buffer; at most 224 overwritten slots |

The first is a bounded model of call-stack exhaustion. The second is a transform-stack leak. The third is deliberate address aliasing. They can inform the same visual research, but they are not three names for the same software fault.

## 01 / A call that never returns

![Six pending calls.](museum/calls-six.png)

![Twelve pending calls.](museum/calls-twelve.png)

Start with six frames. Press STEP or PLAY. At capacity 20, twenty bays are admitted. Call 21 is refused before it can be appended; its pink bay is an explanatory preview of the rejected request. Raising CAPACITY admits more calls. Reset clears the process.

The generator stores its simulated frames in an ordinary array and runs a bounded loop. It does not recurse until Godot crashes. A real call-stack overflow commonly interrupts execution; the retained sculpture here is an explicit artistic choice. Missing base cases and excessively deep calls are documented causes of stack exhaustion. [MDN explanation](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Too_much_recursion).

![The growing assembly at eye level.](museum/calls-ground.png)

The question for this room is precise: **what should remain when the next operation cannot be admitted?** We keep the work already made, expose the refusal, and leave the source recoverable.

## 02 / A building forgets where to return

![Correct sibling arrangement.](museum/source.png)

![The same sixteen operations with restoration omitted.](museum/leak.png)

SOURCE places sixteen independent bays around one centre. LEAK saves a transform but fails to restore it before making the next sibling. Scale and rotation accumulate; intended neighbours become an overlapping, displaced group. No random values are added. The first bay agrees with the control; disagreement begins at the second.

This offers a different version of the earlier moving-pivot experiment. The changed shape comes from the bookkeeping of the construction. Returning is part of making a form.

## 03 / New data, old faces

![The tower before its addresses are reused.](museum/unwritten.png)

![Eighty-four overwritten positions pull the old skin across the gap.](museum/wrap.png)

A simpler tower makes the data relationship visible: nineteen rings of twelve stored positions, joined by 432 triangles. A second construction starts writing at logical address 228. The explicit rule `address % 228` sends it back to the first slot. The old triangles still refer to those addresses. Some corners now belong to one construction, others to another, and the mesh becomes a bridge between them.

All accesses stay inside the array. The source record is kept separately. This models address reuse, not genuine memory corruption; changing stored positions while keeping indices explains the visible deformation. Godot's indexed mesh arrays supply that position/index relationship. [Godot ArrayMesh documentation](https://docs.godotengine.org/en/stable/tutorials/3d/procedural_geometry/arraymesh.html).

![The rewritten skin viewed from the floor.](museum/wrap-ground.png)

The useful connection to the game glitches is material: a face still joins its designated corners even when their new positions make the resulting surface unreasonable. It is not evidence that any supplied game screenshot had this exact cause.

## Operate the study

![The native controls.](museum/console.png)

Run `res://commons/artifacts/model_overflow/preview.tscn` with F6. SOURCE gives the corrected sibling arrangement. CALLS, LEAK and WRAP select the studies. STEPS scrubs the operation; STEP advances once; PLAY / HOLD advances every 0.35 seconds. CAPACITY controls pending frames in CALLS and LEAK only; WRAP keeps 228 vertex slots. RESET restores the current study to its beginning. Arrow keys adjust steps/capacity; 1–4 select modes; Space plays; Enter steps; R resets.

The first two studies call the actual earlier bay constructor. The third introduces the simpler tower skin so its vertex addresses can be followed. The fixed miniature is the earlier bay, not a miniature of the tower. The model surfaces have no colliders; the fixed preview courtyard supports walking.

## Placement and evidence

![The preview courtyard from above.](museum/above.png)

**43 native checks pass.** The run verifies capacity before append, preservation after refusal, inherited transforms, the first divergent sibling, valid triangle indices, partial buffer writes, finite model coordinates, unchanged source data, exact reset, native dial values, play/hold, real desktop pointer presses and eight GLB exports. The screenshots are rendered by Godot, including eye-level and elevated views.

[Test receipt](validation/report.json) · [Engine log](validation/native.log) · [Reproduction and scope](source/README.md) · [Placement record](museum-placement.json)

An initial capture run caught a primitive-mesh vertex-count API error. It was corrected and the complete run passed again. Existing project UID/Jolt/shutdown warnings remain. No native stack exhaustion, physics collapse, physical headset test or Quest performance claim is made.

No canonical tutorial, final text, map or sequence order changed. A possible later encounter sits between recursive construction and the existing glitch studies: make a form, accumulate its pending work, reach a limit, then decide what to preserve. That is a placement proposal, not an installation.
