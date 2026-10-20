from pathlib import Path
R=Path(__file__).resolve().parents[1]
M=R/'commons/maps/SoftBodies_Affect_Theory_Visualization'
S=R/'doc/book/studies/soft-bodies-through-the-hands'/M.name
def code(name):return '\n<!-- student-code:'+name+' -->\n```gdscript\n'+(S/name).read_text(encoding='utf8').rstrip()+'\n```\n'
t='''# One shape, one cue

## Learning elements

- A controlled comparison
- Shared geometry, separate materials
- Node motion versus vertex deformation
- Resetting the previous condition
- Appearance and the mechanism it suggests

<!-- @radiolaria -->

Walk between the radiolaria forms. Stop ROTATION, then turn EFFECTS off. The specimens remain. Their spikes, rings and repeated parts were constructed; the surrounding particles and the turning were additional cues.

This court begins with a fixed construction seed. SEED selects another repeatable draw. COLOUR rebuilds the forms with another palette; keeping the seed helps you compare the same construction. SPIKES can change the geometry and later random choices, so it is a different experiment. A setting called “spikiness” is a generator parameter, not a measured capacity to defend a living body.

Last hall you kept positions and face indices while their source continued. Here we keep that shape fixed and vary its presentation. Two identical copies make the comparison clear: the left stays still and neutral; the right receives one cue. The forms in this room prompted the question. Your captured surface supplies the material for testing it.

## Continue with your captured shape

Work inside the prepared Endless Museum project, where the player, camera, lighting and XRTools already run. Create a Node3D named `OneCue` in a clear place at floor level and unit scale. Attach the following `study.gd`. Keep `vessel_surface.gd`, `solver.gd` and `point_body.gd` beside it: they are unchanged from the previous lesson and printed at the end. The supplied `study.tscn` contains just this root and script attachment.

For a repeatable starting point, this script reconstructs the previous lesson's step-40 snapshot from the same recipe. It does not load a drawing from disk or resume your previous play session. The solver runs those forty steps once. After that, only the display changes.

Hold the black point and press its trigger, or press **1** on desktop. Cycle through three conditions: both copies neutral and still; only the right copy turns; only the right copy changes colour. Press **2** to return to the first condition.

## Complete study.gd
'''+code('study.gd')+'''
## Read the comparison

Both MeshInstance3D nodes refer to `saved_mesh`. This shared resource is useful because neither copy edits it. Their positions put the same local geometry in two places.

Each loop iteration creates a separate material. Changing the right material therefore leaves the left material alone. If both nodes shared one material, the colour comparison would change both copies.

`_process` turns the right node only in condition 1. `delta` makes `TURN_SPEED` a rate in radians per second. The node's transform changes; its stored vertices do not. This is the transformation you learned earlier, applied to a shape whose deformation has already stopped.

`set_condition` first resets the right node's orientation and colour. Moving from rotation to colour therefore removes the previous cue. Without that reset, the coloured copy could keep a different orientation and you would be comparing more than one change.

No soft-body simulation runs in `_process`. Nothing senses the visitor, grows or decides where to turn. The point's trigger chooses a condition; it does not give the displayed surface a new physical behaviour.

## Make one comparison of your own

Change `TURN_SPEED` from `0.7` to `0.35`. Before running, predict what should differ after one second and what must stay unchanged. The turn angle should halve. The left copy, both vertex arrays and both colours should stay the same. Then return to the still condition before testing a different `ACCENT` colour.

Say what you saw before giving it a biological name. “The right copy turns while the left stays” can be checked against the program. “The right one feels more alive to me” records your response. An assertion can protect the first distinction; it cannot establish the second for every visitor.

The next hall changes the underlying state again: values spread and react across a field. We will be able to ask which visible differences come from those exchanges and which come from how the field is shown.

<!-- @ -->

## Carried files — unchanged

These are the complete files from **A shape kept**. Reuse your copies if they match; no new solver or point class is being introduced here.

### vessel_surface.gd
'''+code('vessel_surface.gd')+'\n### point_body.gd\n'+code('point_body.gd')+'\n### solver.gd\n'+code('solver.gd')
f='''# What makes this look alive?

<!-- @radiolaria -->

Something bristles. A pale body seems delicate; another looks as though it might catch on your skin. The forms invite recognition before explanation. Their rings and spines recall the visual repertoire of Haeckel's plates, although this program builds its own specimens from geometric recipes.[^haeckel]

Walk between them before touching the controls. There are nine specimens drawn from six families. Repetition can make them look related. It does not mean that one descended from another, or that any of them developed by growing.

Stop ROTATION. The bodies hold their orientations. Turn EFFECTS off and let the particles clear. What remains of the impression that something was happening here? A body need not move to draw a response from you. A static spike may be enough to change how closely you want to approach.

Bring your hand to one. The form does not yield or resist; its visible skin has no contact surface. Earlier, the jelly moved away from your hand. Here your hand passes through. What you expected to feel and what the program supplies come apart.

Place the surface you kept in the previous hall beside this encounter. Give it a second copy with the same saved positions. Let one turn, then change its colour with the turn removed. We have given it a different presence without changing the record from which it was made. Does knowing this settle what it feels like to stand beside it?

The fixed seed makes a construction available again. It lets us ask which difference belongs to a palette and which to another draw. But a repeatable recipe cannot repeat the visitor's response. You bring other encounters with shells, ornaments, infections, toys, bodies you wanted to touch and bodies you were warned against.

A feeling can be real without confirming the explanation that arrived with it. The form has affected you; that does not tell us that it feels. Nor does learning its construction require you to stop caring about it. We can remain attached while becoming more exact about what we have encountered.

This matters when resemblance begins to decide which bodies deserve attention. Familiar signs can make recognition easy; they can also make an unfamiliar body harder to meet. The generator offers a repertoire. We can change that repertoire, and we can notice where our willingness to attend has already narrowed it.

Next, a field changes through local exchanges. A pattern will persist while its values move. Carry both questions into that room: what process maintains the difference, and what have we learned to see in it?

<!-- @ -->

[^haeckel]: Ernst Haeckel, *Kunstformen der Natur*, [plate 1, Radiolaria](https://www-archiv.fdm.uni-hamburg.de/b-online/haeckel/Tafel_001.html), reproduced by the University of Hamburg. The project's generator identifies Haeckel's illustrations as an inspiration. The resemblance discussed here concerns a visual vocabulary; these specimens are not biological reconstructions.
'''
for name,body in [('tutorial.md',t),('final.md',f)]: (M/name).write_bytes(body.encode())
print('One new host; three unchanged carried files; tutorial and reflection separated.')
