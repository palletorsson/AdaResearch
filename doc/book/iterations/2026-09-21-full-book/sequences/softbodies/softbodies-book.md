# softbodies: the chapters

## SoftBodies Soft Body Deformation

*SoftBodies_Soft_Body_Deformation*

# What holds a cube together?


The cube gives way. Yet it does not become a collection of loose triangles. Something continues to hold its parts in relation. Before looking at the settings, choose what you expect a softer cube to do: change further, return more slowly, or fail to return at all?

Try STIFFNESS, then change DAMPING separately. The first changes resistance to deformation; the second damps motion. A body that moves less is not necessarily a body that resists deformation more. RESET restores the opening coefficients. It does not put every vertex back where it was before you arrived.

```gdscript
_soft_body.linear_stiffness = stiffness
_soft_body.damping_coefficient = damping
_soft_body.pressure_coefficient = pressure
```

These are parameters of Godot's soft-body solver. The program supplies a subdivided cube and lets its vertices respond under those rules. PRESSURE introduces another contribution. Watch what inflation can conceal: the same outer silhouette can be maintained by different balances of resistance and internal pressure.

We have already changed whole objects by translation, rotation and scale. Here, their constituent positions change relative to one another. The surface connectivity remains prescribed. Yielding is a new capability; tearing, growing a hole or exchanging a neighbour would require more code. A soft appearance does not announce every freedom a body possesses.



Turn toward the mill. The moving apparatus brings a repeated encounter to a soft sphere. Use MILL to hold the drive. The sphere's physics continues; stopping a mechanism is different from stopping everything it has set in motion.

The cube made its coefficients available on a desk. The mill makes the source of an encounter visible in the room. Follow the motion from the machinery to the surface, then consider the room around both: the collider, support and pinned points belong to this body's conditions as much as its stiffness does.

The nearby jelly variants remain useful comparisons, and radiolaria offers a different warning: intricate biological resemblance can be constructed without soft-body dynamics. Keep that distinction for later. First we need to see how a surface changes when some of its points are required to stay.

---

## SoftBodies Cloth Physics

*SoftBodies_Cloth_Physics*

# Which points must stay?


Walk along the hanging strips. Each begins as an open surface. Unlike the pressurized cube, it has no enclosed interior for pressure to inflate. The upper edge holds while the rest hangs below it.

Press PINS to keep only the upper corners. Look for the difference before naming it. The material settings have not changed. The allowed motion has: points that were fixed can now participate in the sag. PINS alternates those two arrangements; RELEASE removes the pins, and REBUILD makes fresh strips with their upper rows fixed again.

```gdscript
sb.set_point_pinned(i, keep)
```

For each strip, the desk finds the top row in its mesh coordinates and chooses which indices to pin. This is a boundary condition written into an array. The frame makes that condition visible, but the frame and the pinning rule are distinct constructions. A convincing support does not prove how the simulation is attached to it.

Try STIFFNESS after choosing a support. We now have two ways to change the silhouette: change the material response, or change which points may move. When we describe an object as compliant, how much of that description belongs to the object, and how much to the arrangement holding it?



The four falling bodies provide a second encounter. They are soft spheres, retained from the earlier collection, not pieces of woven cloth. LANDING changes the support below them between a floor, a narrow pan, a rail and a cone. Rebuilding that comparison also starts a new fall.

Their timers disable processing and raise damping and stiffness at scheduled moments. This stopping method is not an explicit snapshot of all vertex positions. The apparent crumple depends on the solver as well as the timer; it is not a shape the material was destined to have. Two shipped stop times are equal; four specimens do not automatically mean four different moments.

This prepares two questions we will return to: what makes the body deform, and what makes us stop looking? Carry the fixed edge into the next hall. There, the support itself moves.

---

## SoftBodies Carusell

*SoftBodies_Carusell*

# The support moves


Stand where you can see the hub and the hanging bodies together. The ring turns because its angle is advanced by the program. The joints and deforming bodies respond to a support whose motion has already been prescribed.

Lower the SPEED. Then REVERSE it. Do the bodies immediately take up the new arrangement? STOP sets the angular rate to zero, but it does not erase velocity, gravity or contact. The support can stop commanding a new angle while its consequences continue.

The rate is measured in radians per second. A complete turn is `TAU` radians. The driven rotation connects this hall to Transformation and Oscillation, but the hanging bodies add a different problem: their current state matters to what happens next.

Change STIFFNESS or PRESSURE while watching a particular body. We should not attribute every difference to speed when we have also changed material coefficients. The apparatus makes a limited experiment possible, provided we remember what we touched.

This carousel offers an image of freedom through motion. Its moving parts also show how motion can be organized by obligations: a joint, a pin, a driven hub. The question is which relations can move, and which relations move them.



The cloth strips nearby retain a fixed support. Return to them after watching the ride. They make the contrast available at the same bodily scale: a surface can respond while its boundary remains still, or respond because its boundary is driven.

The sticks, pick-up cubes, flex pad and soft mushroom remain part of the collection. They are opportunities for further encounters, rather than evidence that every visible object runs the same solver. Begin with one comparison you can follow, then widen it.

In the next room, the enclosing architecture takes on a deformable surface. The distinction between a body and its surroundings becomes harder to maintain by pointing.

---

## SoftBodies Obsticals

*SoftBodies_Obsticals*

# The room has a body


The walls swell. Find a position from which both their edges and their centres remain visible. Selected vertices stay pinned while the surfaces respond between them. Before entering, watch a complete pressure cycle.

AMPLITUDE changes the range of pressure. RATE changes how quickly its driving phase advances. HOLD DRIVE holds that phase; it does not freeze the wall vertices. The soft solver can continue settling under the pressure it last received.

```gdscript
var p = (sin(_time) + 1.0) * 0.5 * breath_amplitude
for sb in _walls:
    sb.pressure_coefficient = p
```

The sine wave supplies pressure to a deformable body. It does not directly specify the location of every point on the wall. The actual surface is a result of the solver, its constraints and its encounters. This is the bridge from the earlier sine spaces: a periodic instruction now enters a system that can respond.

Calling it breathing is an invitation to bodily recognition. This room has no need for air and no sensor deciding when to inhale. The resemblance can be affecting without becoming a description of its mechanism. Its capacity to narrow space still deserves a practical question: how much room remains for the visitor?



The nearby contact gallery keeps other combinations visible: soft bodies meet rigid obstructions. Look at one named cell before surveying the whole array. The specimen, its support and its settings constitute a particular test; their variety is not a single scale from hard to soft.

The flag dancer remains as another encounter with a driven system. Together these objects begin to distribute softness across the room rather than confine it to one specimen. Yet the museum crossing still has independent support. A deforming wall and an onward route make different promises.

Next we will hold and replay a contact experiment. A spectacle of differences becomes more useful when we can identify which differences were introduced.

---

## SoftBodies Obsticals Part2

*SoftBodies_Obsticals_Part2*

# Same fall, another encounter


The array contains several kinds of encounter. Start with the names: a slippery collider, a corner strike, high drag, a torus. They do not vary just one property. Choose one cell and compare it with a cell whose difference you can describe.

REPLAY restarts the group from its declared seed. The opening study removes the gallery's additional random changes to stiffness and pressure. VARIATION restores those changes. A fixed seed repeats a recipe for initial conditions; it does not promise bit-for-bit identical physics on every computer.

```gdscript
sb.linear_stiffness = 0.5
sb.damping_coefficient = 0.01
sb.pressure_coefficient = 0.0
```

The gallery applies each named cell's settings on top of these defaults. Optional variation then adds another layer. The final coefficients, the starting mesh and the obstruction all matter. A name like “Jelly” cannot substitute for that construction.

HOLD pins the current vertices. RELEASE restores the pins recorded before that hold. Neither action retrieves an untouched original body. GROUP opens another set of encounters; the study disables automatic respawning and ongoing deflation so that bodies do not multiply while you are trying to inspect one.

The most interesting result may be an awkward fold that a smooth rendering would conceal. Hold it and move around it. Ask which part is an effect of contact, which part comes from the triangulation, and which part depends on the solver's finite effort. Those are invitations to further experiments, not conclusions available from a single silhouette.

The array is useful because it holds differences near each other. It becomes misleading if proximity is mistaken for a controlled comparison. The next hall turns that problem toward time: when we keep a shape, what have we selected from the event?

---

## SoftBodies Playground of Joy

*SoftBodies_Playground_of_Joy*

# When does a body become a form?


The rounded body continues to respond while an instrument colours its surface. MEASURE changes what is made legible: strain, collision or volume. The body has not acquired a new material because we changed its reading.

Keep the reading on volume and press FEEDBACK. Now the instrument acts back: it adjusts pressure to bring its reading toward the recorded value. Switching FEEDBACK off restores the selected pressure. It does not retrieve the body you had before.

What has been asked to stay the same? This instrument measures the box around the vertices, aligned with the room's axes. It does not measure the space enclosed by the skin. A fold can change the body without changing that box. A number that helped us look has become a number the body is asked to follow.

SQUEEZE changes the strength used by the artifact's existing squeeze interaction. STIFFNESS changes resistance in the solver. Watch the instrument as well as the silhouette. A colour scale can bring a small difference forward, or persuade us that its chosen quantity is the whole event.

The strain display compares the current vertex positions with recorded positions. That reference belongs to the model. Returning toward it is not a universal tendency toward an original or natural body; it is a particular constraint implemented here.

The branching study and field sculpture remain nearby, so the new capability can be compared with earlier ways of constructing an organic-looking form. A branch recipe, a deformed surface and a sampled field may resemble one another without explaining one another.



The glass vessel has already stopped. Its program begins with a sphere, pins an upper region and runs a custom soft-body simulation for a chosen number of steps. It then builds a surface from the resulting positions.

```gdscript
sim.gravity = Vector3(gravity_x, gravity_y, gravity_z)
sim.constraint_passes = 5
```

DURATION reconstructs the vessel using 40, 200 or 400 solver steps. GRAVITY changes the lateral component of the force. Compare duration first while the force remains fixed. These are numerical steps in a reconstruction, not seconds borrowed from the museum clock.

The object is evidence of a process, with most of that process absent. A different stop could have become the sculpture. Walk up to the frozen skin. Its surface can meet your body; transparency has not made it passable. Look for a mouth. This specimen began as a closed sphere, and deforming it has not cut an opening. To make a vessel we could enter, we would have to change more than its silhouette.

A frozen result lets us look longer. It also makes the timing of a decision disappear into the apparent permanence of a thing. Next, we will ask what else an image of a body invites us to infer.

---

## SoftBodies Affect Theory Visualization

*SoftBodies_Affect_Theory_Visualization*

# What makes this look alive?


The forms invite recognition before explanation. Spikes, rings and lattices suggest organisms, shells, pollen or something that might brush against skin. Let that recognition arrive, then keep it beside the question of how these objects were made.

Stop ROTATION. Toggle EFFECTS to change the particles surrounding the forms. What still looks alive when these motions cease? COLOUR also rebuilds the geometry in this implementation; with the initial unpinned random seed, it can change more than colour. Press SEED to choose a repeatable construction before comparing palettes. SPIKES changes a probability in that recipe; it does not teach an organism to defend itself.

The program constructs several families from geometric elements. Its parameters include `spikiness_probability`, `max_spike_length` and `detail_level`. These names describe decisions available to the generator. They are not measured properties of a living radiolarian.

We have arrived here with the ability to generate patterns, branch, deform a mesh and sample a process. That toolbox makes several accounts of an organic-looking object possible. Which one did you expect when you first saw these forms? What in their colour, repetition or motion supported that expectation?

The gap is productive. Desire can travel ahead of an explanation; a strange body can invite attention before we know how to describe it. Learning the recipe need not cancel that encounter. It gives us something specific to vary when the familiar repertoire begins to close around what a body is allowed to look like.

Radiolaria belongs here as an explicit contrast, not proof that static geometry is a soft-body simulation. In the next hall, spatial differences will be maintained by exchanges in an evolving field. Biological resemblance and a model of morphogenesis will finally meet as different claims we can examine.

---

## ProceduralGeneration Reaction Diffusion Systems

*ProceduralGeneration_Reaction_Diffusion_Systems*

# A pattern has a metabolism


A patch interrupts the field. Before advancing it, predict where the next change should occur: everywhere at once, around the boundary, or only inside the patch? STEP performs one update. A hundred updates make the consequence easier to see while keeping the same rule.

At each address the program stores two concentrations, U and V. It reads the old arrays, calculates local changes and writes separate arrays for the next state. Only then are the buffers exchanged. The result does not depend on whether the display happened to draw the left edge first.

```gdscript
var uvv = u * v * v
var du = Du * lap_u - uvv + feed * (1.0 - u)
var dv = Dv * lap_v + uvv - (kill + feed) * v
```

Diffusion exchanges with neighbours; reaction, feed and removal change the local quantities. This is the Gray-Scott model, not a direct implementation of Turing's original chemical equations. REGIME chooses another feed/removal preset and restarts the field. SEEDING changes the initial arrangement. Compare those interventions separately.

The grid wraps at its edges. Concentrations are clamped to the interval zero to one. These choices are part of the experiment. A field that seems to continue beyond its frame has a particular way of returning through it.



The second reaction–diffusion display remains a running comparison with its own implementation and settings. It is not a synchronized duplicate of the desk study. Look for recurring spatial features, then return to the controls before attributing a difference to one coefficient.

The soft-body samples, detailed bulge and Confessing Body theatre preserve further connections to the chapter. A chemical field can colour a wall, displace a surface or feed a growth rule, but each application needs an explicit mapping. Pattern formation alone has not made a solid that can bear your weight.

This matters to the red thread. New combinations become possible, and so do new confusions. A useful bridge should let us inspect the operation that carries a field into a form. The next artifact provides precisely such a mapping—and gives one of its controls an especially demanding name.

---

## Topology Entropy Morphogenesis

*Topology_Entropy_Morphogenesis*

# Who connected the controls?


The surface opens and folds around passages. It recalls the sine and noise spaces we walked earlier, now combined into a sampled field. Before touching S, choose one opening you can follow with your eyes. Keep track of it as the surface is reconstructed.

S changes several parameters together. The desk reports their values so that an impressive transformation does not hide its recipe.

```gdscript
current_frequency = lerpf(base_frequency, high_frequency, S)
current_noise_amp = lerpf(base_noise_amp, high_noise_amp, S)
current_threshold = threshold_center + threshold_wobble * (S - 0.5) * 2.0
```

The parameter is called entropy in the source. Here it is an authored control between settings, not an entropy value calculated from a distribution. Its name cannot establish a law connecting disorder and form. The mapping can nevertheless become a useful instrument if we expose what it does.

NOISE removes or restores the noise contribution. LEVEL changes the threshold arrangement. RESOLUTION changes the number of samples used to construct the surface. Try them separately, then compare that experience with moving S. Which differences had been bundled into its single gesture?

The generated collision belongs to the reconstructed surface. An opening that appears in a rendering may still be too narrow for the player. A change in geometric frequency is not automatically a change in connectivity, and neither alone certifies a traversable route. We can learn to ask each question at the scale where it has consequences.

Across these halls, a body has become a set of relations that can yield, remain attached, be driven, meet an obstruction, or be held as a sculpture. We have also seen appearances that imply mechanisms they do not contain. The point is not to exhaust desire by naming every rule. It is to gain enough purchase on a rule to change what it permits—and notice what the next construction still leaves out.

---
