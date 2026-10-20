from pathlib import Path
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/SoftBodies_Playground_of_Joy'
S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
def code(name):return '<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
text='''# A shape kept

## Learning elements

- Vertex positions and face indices
- Copying a snapshot
- Local coordinates and display placement
- Sampling time versus simulation state

<!-- @rounded_softbody_test -->

At the rounded body, change MEASURE. The display changes; the body keeps responding. FEEDBACK is a separate action: it changes pressure using the volume of an enclosing box as its reading. That box is a proxy, not the volume inside the skin. Explore this distinction here; the code lesson follows the glass vessel beside it.

<!-- @ -->

<!-- @frozen_glass_vessel -->

Last hall you kept a number while a panel continued to fall. Now keep a surface. The installed vessel already does this: start with a sphere, pin its upper region, simulate, then build a mesh from the resulting positions. DURATION reconstructs it with another number of steps. You are choosing which state becomes the object.

We use the vessel's construction and custom particle solver for this lesson. Its `positions` array is directly readable. This is a change of implementation from the previous Jolt panel, not a claim that those two solvers have interchangeable properties. The operation carried forward is sampling a moving body. Our black PointBody also returns, unchanged, as the capture control.

## Build beside the encounter

Work in the prepared Endless Museum project. The player, camera, lighting, floor, XRTools and physics setup are already supplied. Create a Node3D named `ShapeKept` in a clear part of this hall, at floor level and unit scale. Attach `study.gd`. Put all four files below in the same folder. The downloadable `study.tscn` provides exactly that root and script attachment; it contains no hidden meshes.

`study.gd` is the new work. `point_body.gd` is the previous hall's class. `vessel_surface.gd` supplies the installed vessel's sphere, spring connections and mesh assembly. `solver.gd` is an unchanged copy of `commons/soft_body/soft_body_sim.gd`. They are printed below for a complete runnable example; writing a solver is not this lesson's task.

Two pink surfaces appear. The left one runs. At step 40, the right one keeps a copy. Hold the black point and press its trigger to replace that copy with a later state. On desktop, press **1** to capture and **2** to start again. Holding or moving the point does not deform these surfaces; here its trigger operates the sampler.

'''+code('study.gd')+'''
## Read the operation

`capture()` copies two arrays. Positions say where the vertices are. Indices say which entries form each triangle, just as in the earlier polyhedra lesson. We keep that connectivity while the positions change. The helper recalculates normals for the saved surface and returns a new ArrayMesh.

The copied positions remain in the solver's local frame, measured in the project's metre scale. The two mesh nodes place the same shape to the left and right. Their offsets stage the comparison; they do not change the saved data. Adding a world position to those vertices would apply placement twice.

Each physics callback advances the custom solver by its fixed `0.0166667` step, approximately `1/60` second. We count those steps explicitly. Step 40 means forty integrations; the caption does not promise that forty callbacks took a particular amount of wall-clock time. `SAMPLE_STEP` selects the automatic capture. A trigger can capture at any other step, including after that selection.

Only the live mesh is rebuilt each tick. The saved mesh stays until another capture or a restart. No disk file is written. This snapshot keeps positions, triangle connections and a step number. It omits the solver's previous positions, pins, spring settings and force history. A shape alone is not enough to resume this simulation. The displayed copy also has no collision body; the installed glass artifact does.

## Change when you stop

Change `SAMPLE_STEP` from `40` to `200`. Before running, predict what stays the same: the vertex count, face indices and display placement. Predict what may change: the saved positions. Run the whole example. Check the KEPT caption, then wait. The left side must continue; the right side must keep its step-200 shape. Trigger another capture and verify that the right side changes only then.

Use **2** to restart. The saved mesh and step label clear, the solver is reconstructed, and the same point object remains available. Resetting only the counter would not restart the experiment.

## Supplied files

These files expose the construction the host relies on. Keep their settings fixed for the capture-time experiment. The adapter follows the installed vessel's radius, rings, segments, upper pins, initial expansion and spring order. It uses the same local positions but displays both results in opaque pink so their contours can be compared.

<details>
<summary>vessel_surface.gd — sphere, constraints and mesh assembly</summary>

'''+code('vessel_surface.gd')+'''
</details>

<details>
<summary>point_body.gd — the unchanged grabbable point</summary>

'''+code('point_body.gd')+'''
</details>

<details>
<summary>solver.gd — the supplied particle solver</summary>

'''+code('solver.gd')+'''
</details>

## What travels onward

You can turn one state of a process into a separate object, state when you selected it, and name what you left out. In the next hall, organic-looking forms invite another inference: does looking alive tell us how something was made?

<!-- @ -->
'''
(M/'tutorial.md').write_bytes(text.encode('utf8'))
final='''# When does a body become a form?

<!-- @rounded_softbody_test -->

The rounded body continues to respond while an instrument colours its surface. MEASURE changes what is made legible: strain, collision or volume. The body has not acquired a new material because we changed its reading.

Keep the reading on volume and press FEEDBACK. Now the instrument acts back: it adjusts pressure to bring its reading toward the recorded value. Switching it off restores the selected pressure. It does not retrieve the body you had before.

What has been asked to stay the same? This instrument measures the box around the vertices, aligned with the world's axes. It does not measure the space enclosed by the skin. A fold can change the body without changing that box. A number that helped us look has become a number the body is asked to follow.

Put a hand into the body and hold the grip. The surface is pushed away from your hand. Change the strength, or turn that intervention off. Watch the silhouette as well as its colours. The instrument can bring a small difference forward; it can also make its chosen quantity seem like the whole event.

The branching study and field sculpture remain nearby. A branch recipe, a deformed surface and a sampled field may resemble one another without explaining one another.

<!-- @ -->

<!-- @frozen_glass_vessel -->

The glass vessel has already stopped. You have met it before in Form Finding, where a chosen number of steps helped produce its shape. Here DURATION lets you reconstruct it after forty, two hundred or four hundred steps. Keep gravity fixed and change only the stop. There was no final shape waiting for the clock to uncover it. There were successive states, and a decision to keep one.

Last room, a number stayed while a body continued. Here a whole surface can stay. Beside the encounter, the tutorial makes the difference visible: one shape goes on responding while its copy remains. The copy gives you time to look. Its stillness is something we have done to the record.

The connections between its vertices remain. The previous positions, the forces and the successive corrections do not travel with this copy. Its surface bears consequences of the process without supplying a complete account of it. Different histories can arrive at similar shapes. Looking more closely cannot always recover what was not kept.

Walk up to the installed glass skin. Its surface can meet your body; transparency has not made it passable. Look for a mouth. The specimen began as a closed sphere, and deforming it has not cut an opening. Calling it a vessel invites a use its construction has not provided.

A frozen result lets us look longer. It also allows the timing of a decision to disappear into the apparent permanence of a thing. The caption keeps the selected step beside the shape. What else would we need to keep if another person were to question how this object came to stand here?

Next, the room offers bodies that look alive. We carry this hesitation with us: a convincing appearance may leave its means of production out of view.

<!-- @ -->
'''
(M/'final.md').write_bytes(final.encode('utf8'))
print('Written focused tutorial with four complete files and separate reflection.')
