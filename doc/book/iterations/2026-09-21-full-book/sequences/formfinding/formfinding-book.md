# formfinding: the chapters

## FormFinding Descent

*FormFinding_Descent*

# Where does downhill take you?


The last room let a field carry you across a gap. You brought motion into it; the field changed that motion; something of the journey remained when you left. Here a gold point waits above a blue surface. There is no gap to jump. There is a button marked STEP.

Before pressing it, choose where you think the point will go.

One press leaves a short line behind. Another extends it. The number called cost changes. Try a few more presses before RUN. What repeats? What gets smaller? Does the point travel the same distance each time?

RUN lends the operation a rhythm. It repeats the same step, with a pause between updates so you can follow it. The pause helps us watch; it is not time inside the equation. Stop the run and take over with STEP again. The line remembers where the point has been, but that memory does not propel it.

This is already a departure from Forces. There is no stored velocity here.

## A direction without a destination

Press PARTS. The pink arrow offers a local direction. It lies horizontally, above the drawing; its length is capped at one metre. It does not point at a destination that the program has found elsewhere. The program has looked a little to either side of the current address.

In the x direction it asks how much cost changes between x minus 0.03 and x plus 0.03. It divides that difference by the distance between the samples. It does the same along z. Two comparisons make a vector: the sampled gradient. Its negative gives the direction the point will try.

Now reveal RULE. The moving point becomes a short instruction:

```gdscript
proposed = point - rate * gradient(point)
```

The subtraction is familiar. We have carried vectors, combined them and used them to cross space. Here subtraction changes an address in a search. RATE decides how far to trust the local direction. It does not name speed in metres per second. No mass is divided out; no acceleration is accumulated.

On the opening bowl, the cost is one quarter of x squared plus z squared. At the usual rate, the steps shrink as the point approaches the centre. The program does not need to know the centre's address to make those steps. We can see the whole bowl; the update uses nearby samples.

Eventually the display says SMALL SLOPE. Look at that wording before calling the run solved.

## Two beginnings

Switch SURFACE. The blue drawing now has two unequal valleys. Changing a setting starts a fresh run, so the next trail belongs to that setting alone. Keep RATE at 0.7 and STOP at 0.01. Run from the first START, note the final cost, then select the second START and repeat.

Both runs can stop at a small slope. They do not arrive at the same cost.

In the recorded desktop comparison, the first run finishes near -0.304 and the second near 0.295. The rule, tolerance and surface are shared. The beginning differs. One valley is lower, but the point in the other valley has no instruction to cross the intervening rise in search of it.

The surface makes this difference visible all at once. The moving point encounters it locally, one update at a time. You can walk around the plot and see the other valley. That knowledge has not entered the algorithm merely because it has entered your view.

What would have to change for the point to search there? Keep the question. Annealing will give us one way of approaching it later.

## How much is enough?

Try a looser STOP setting. A larger tolerance accepts a larger remaining slope. The run can finish earlier, at a different address and cost. Nothing in the surface has announced that this much unfinished movement is acceptable. We supplied that threshold.

Then return to the bowl and increase RATE. A downhill direction is a local statement; a long step can pass the useful part of it. Cost can rise. At the largest setting, a proposed step can leave the six-metre frame. The display says LEFT FRAME and keeps the last valid point. It does not silently push the point back against an edge and congratulate itself.

A third ending, STEP LIMIT, means the budget of 160 moves was spent. These endings answer different questions. Small slope describes a local measurement. Leaving the frame describes a boundary. Spending the budget describes how long we agreed to search.

Even a zero gradient would not by itself prove a global minimum. A maximum or a saddle can have one too. Here we can inspect the authored surface and compare runs. Elsewhere that overview may be unavailable.

## The surface we agreed to search

The plot is drawn with 48 by 48 cells, each split into two triangles. The gradient samples the cost function directly, at offsets of 0.03. It does not read the rendered triangles. What you see and what the point measures are related representations with different resolutions.

Its displayed height is another choice:

```gdscript
height = 0.40 + 0.22 * cost(point)
```

The height makes cost legible across a table. It is not gravitational potential energy, and the blue mesh is not a floor for your body to climb. The point's apparent descent comes from changing an address and drawing the result. Behind this experiment, the retained marble toy carries velocity and receives periodic programmed kicks. Its motion may resemble searching, but it uses another update. The resemblance gives us a comparison to investigate.

There is room for a different body in these small changes. One beginning inhabits a valley another beginning misses. A threshold admits one endpoint and rejects the next. Yet lowering cost only means improving according to the cost we wrote. Nothing in the arithmetic establishes that this measure contains everything worth keeping.

For now the landscape is authored and the point searches it. We have not yet let a connected shape emerge under load. In the next hall, hold two ends of a cable and let the space between them become the question. What can change when some things must remain fixed?

---

## FormFinding Catenary

*FormFinding_Catenary*

What has already been decided when a curve seems to find itself?

The last hall let you follow a search taking steps. Here, first take a curve in your hand. Then compare it with one whose coordinates come from a formula. The hanging chain and the soap film are the physical references: under specified supports, loads and material assumptions, a settled chain or film can make a difficult calculation visible. But these objects in the museum arrive by different routes. Watch for the difference between drawing an answer, evaluating an answer, and letting a system settle toward one.

## The chain


Four cyan beads, and a four-metre cable glowing magenta into blue slung through them. Take a bead and move it. The whole curve recomputes and re-skins in your hands, every frame. Hold the ends in mind while you move an interior point: what have you asked the curve to obey?

Read it carefully, because it is the room's honest object. The cable is not a chain solving its own equation. It is a spline whose sag is two Bezier handles per span, each pulled down by a fixed fraction of that span's length, so the depth is drafted rather than found. It resembles a hanging cable because its maker supplied a rule for sag. Your hand changes the constraints of that drawing. No weight has been measured and no rope length conserved.


Three washing lines pegged with towels and shirts, supported at their ends by crossbars. These curves are sampled from `cosh`. Their sag comes from three chosen parameters; the washing adds colour and an association with weight, but it adds no load to the calculation. Then look up. Above each line hangs its ghost: the same curve mirrored upward as a pale arch. The cathedral is implied.

Gaudí used hanging models to study structural form. Inverting a suitable tension model can suggest a compression structure under corresponding loads and supports; it is not a guarantee that any inverted curve will stand. Here the two poses let you see that reversal, while the plaque names the limit: an analytic drawing, not a gravity solver. The washing and the cathedral share a curve. They do not yet share a test.[^FormFinding_Catenary--hanging-model]


## The film


The chain, revolved into a surface. A soap film can form a catenoid between two coaxial rings, but the rings do not guarantee one enduring answer: stability depends on their separation, and a film can collapse into separate discs. “Minimal” does not promise a globally smallest surface for every boundary.[^FormFinding_Catenary--film]

Here it lies low and wide, a cyan wireframe hourglass about a metre and a fifth across and a little over a third of a metre tall. Lift the model and turn it. The opening travels with it; the sampled mesh retains its shape. The same `cosh` appears again, now drawn around an axis. You can inspect the result in your hand, but you cannot stretch its rings or watch a film settle between them.

```gdscript
@export var c: float = 0.5      # waist radius

var r: float = c * cosh(u / c)
var x: float = r * cos(v)
var y: float = r * sin(v)
var z: float = u
```

The same `cosh` appears in a catenary and in the radial profile of a catenoid. Here `c` sets the waist radius; the chosen range of `u` decides how much surface we keep. The formula does not choose its own boundary. Somebody has already chosen the numbers from which it will begin.


In a slot between two pillars, the other one, and you may step over it before you notice it: a green wireframe corkscrew twenty centimetres across, about thirty-eight centimetres high, six thousand triangles in a thing the size of a mug. Lift this one too. A straight line rotates as it rises; the display gains about nineteen centimetres in each full turn.

A helicoid is ruled: straight lines lie along its surface. A catenoid is a surface of revolution. Suitable patches of these surfaces belong to an isometric family: they can be continuously related while preserving their intrinsic distances. That does not make these two differently bounded meshes the same object, and nothing in the room performs the deformation. It is a further encounter to build, not a movement to imagine that you have already seen.[^FormFinding_Catenary--surfaces]


The screen has no compatible live measurement from these objects. Its scanner needs more than a nearby shape or a suggestive name: it needs data in a form it recognises. The surfaces are visible; their mathematical relation has not become a signal the screen can read. There is still work between having an object and having an instrument for it.


## Matter as the solver

A real chain can move, overshoot and settle after an end is displaced. A film has a history too. The equilibrium equation describes a possible settled condition; it does not erase the time needed to reach it. In this room that time is absent for another reason: the laundry curves and surface meshes are constructed from chosen formulas.

This is still a powerful way to make form. The boundary, the formula, the sampling and the drawing each decide something. The calculus of variations asks what makes a shape stationary under allowed changes. Our objects let us approach that question, and also ask which changes their code has allowed us to make.

Next: what happens when the solving has to be done in steps after all, by a machine with a frame budget.

[^FormFinding_Catenary--hanging-model]: Santiago Huerta, [“Structural design in the work of Gaudí”](https://oa.upm.es/703/) (2006), on hanging models, graphical methods and equilibrium design. The inversion is conditional on loads and supports; the laundry artifact evaluates and mirrors a formula.

[^FormFinding_Catenary--film]: Gareth P. Alexander and Thomas Machon, [“A Björling Representation for Jacobi Fields on Minimal Surfaces and Soap Film Instabilities”](https://arxiv.org/abs/1912.13009) (2020). Instability and the transition to separated films are not implemented in this model.

[^FormFinding_Catenary--surfaces]: Danny Calegari, [*Minimal Surfaces*, §1.4](https://math.uchicago.edu/~dannyc/courses/minimal_surfaces_2014/minimal_surfaces_notes.pdf), on the conjugate family and isometric deformation. The local relation does not identify arbitrary finite meshes or their boundaries.

---

## FormFinding Relaxation

*FormFinding_Relaxation*

A released mesh settles into a shape nobody specified, and what stands afterwards is a fossil of the forces that made it.

The last hall let us draw a sag and evaluate a formula. Here a connected shape keeps a history of being changed. A frame budget allows only so many corrections: nudge the points, move to the next constraint, begin another pass. The cloth continues; the lattice and the vessel keep the pose reached after a chosen number of steps. Their stopping times were supplied with their rules.

## Nudged, not solved


A magenta cloth of ten by eight points hanging from its two top corners. It receives sixty settling steps before you arrive, then continues in fixed one-sixtieth-second steps. Watch it before touching the controls. A changing sideways gust keeps disturbing it; motion here does not mean that a single settling process has failed to finish.

The panel now offers PASSES, RESET and WIND. PASSES cycles through nudged, worked, pressed and held: one, four, eight and twelve constraint passes per step. Each choice restarts the same grid and its sixty preliminary steps. Switch WIND off to compare the corrections under gravity alone. Try one pass, then four. Does the cloth hold the same outline? RESET lets you return to the beginning without changing the chosen settings.

```gdscript
var pos: Vector3 = positions[i]
var prev: Vector3 = prev_positions[i]
var vel: Vector3 = (pos - prev) * damping
var new_pos: Vector3 = pos + vel + gravity * dt * dt
prev_positions[i] = pos
positions[i] = new_pos
```

There is no separately stored velocity in that code. In the position update used by Loup Verlet in 1967, where a point is going is implied by where it just was: keep two positions, and their difference carries the motion.[^FormFinding_Relaxation--verlet] The temporary variable called `vel` holds that difference after damping. A point at rest, released, falls gravity times a step squared on its first update. At sixty steps a second, this bench's gravity gives less than a millimetre. The constraints then correct those proposed positions.

Now read MEAN and WORST. They report spring-length errors relative to the lengths we asked the cloth to keep. A pass corrects each spring in turn, moving a free endpoint by half the current error scaled by stiffness; a correction can disturb a neighbouring spring. More passes give those relations another chance to agree.

In a matched desktop calculation after 420 total undriven steps—sixty preliminary steps and 360 more—one pass leaves a mean absolute error of about 1.409% and a worst spring error of 34.276%. Four passes reduce both, to about 0.359% and 8.936%. The average has become small while one local relation is still far from its request. Look between those two numbers. What would we overlook if the bench reported only the reassuring one?


The lattice version stands on a bench: forty-eight pink masses, a hundred and seventy-nine cyan wires, rocking eight degrees either side on an eighteen-second cycle. Compare its movement with the cloth. Are the relations between its points still changing, or is one retained form being turned?

All eighty of its solver steps ran before the room finished loading. The rocking carries a frozen result: a grid with a random hundredth-of-a-metre disturbance per particle, rest lengths, gravity and a fixed time to act. Nobody placed each vertex of the final slump by hand. Somebody did choose the conditions from which it came.


And here is where it stops being a demonstration. A sphere of glass, fifteen rings by twenty-two segments, three hundred and thirty particles, of which the eighty-eight above the top eighth are pinned as if gripped by a blowpipe. Every free vertex is pushed out by a fifth as an initial expansion. Spring rest lengths are made from that expanded shape, then the whole thing is dropped into gravity for two hundred steps of the same solver the cloth is running.

It runs once, when the room loads, and stops. The pose it happens to be in at that moment is the vessel. The glass does not contain you: it has no collider, so your body can walk through its wall.

In the source, changing stiffness, gravity or the number of settling steps makes other vessels possible; those controls are not on this exhibit. A different duration keeps a different moment of the process. The clock is part of the genome here. The form records the conditions that acted on it and how long they were allowed to act.


A screen, and the thing this room is about is the one thing no still image can hold. Every shape here is a duration: eighty steps, two hundred steps, a cloth still taking another step. A picture of a vessel contains none of the falling that made it, which is exactly what a fossil is and exactly what the vessel is.


## A fossil of forces

The vessel in this room was designed through conditions rather than by placing its final vertices. What you see is the frozen output of a simulation, kept because it was interesting, in the same way a fossil is a shape that some process left behind and then stopped.

That is the chapter's argument at its most literal. Nobody drew the amphora. Somebody chose a stiffness, a pin ring, a pulse and a number of steps, and the amphora is what those choose.

Next: a balance written into the relations between parts. How can we tell an encoded equilibrium from a form that has physically found one?

[^FormFinding_Relaxation--verlet]: Loup Verlet, [“Computer Experiments on Classical Fluids. I”](https://journals.aps.org/pr/abstract/10.1103/PhysRev.159.98) (1967). The bench adds distance-constraint corrections to its position update; those corrections and their pass budget are part of this implementation.

---

## FormFinding Equilibrium

*FormFinding_Equilibrium*

Where forces cancel, a form can hold still. That stillness can conceal opposition, exactly matched. But a still image can also be made without calculating any forces. How would you tell?

The preceding halls gave us steps, drawn curves and a mesh left in the pose where its computation stopped. Here the question becomes structural: which relations make a shape hold, and which relations have only been drawn? Start with a balance whose arithmetic you can inspect.

## Balanced by arithmetic


A curtain of painted aluminium discs on hair-thin wires, nearly six metres wide and three and a half tall, filling the north half of the room. Each disc carries a small dark nameplate reading its modelled mass in grams, which is the room telling you what to check.

Find one arm with a disc hanging from each end, and compare their nameplates. Which has the larger mass? Which is nearer its pivot? Follow that relation up one branch before reading the calculation.

```gdscript
var wl: float = left["mass"]
var wr: float = right["mass"]
var total: float = wl + wr
var arm: float = span * (0.7 + 0.35 * float(d)) * _rng.randf_range(0.85, 1.15)
var dl: float = arm * wr / total
var dr: float = arm * wl / total
```

Read the crossover. The left-hand distance is computed from the right-hand mass, and the right-hand distance from the left. Multiply out and the two mass-distance products agree, apart from numerical rounding. Gravity would multiply both by the same factor. The heavier child rides the shorter arm because the arithmetic gives it no choice.

For each disc, the source multiplies its area by three millimetres of sheet and the density assigned to aluminium. Then it builds every rod from the bottom up: add the two children's masses, place the pivot where their moments cancel, report the total upward. The rods and wires have no mass in this calculation. That omission lets the visible masses and distances satisfy a clean lever model; it does not establish how the sculpture would behave if we built it from the materials it resembles.

And it does not move. There is no process loop anywhere in it: for all the wire and the counterweighting, this is frozen sculpture, and the room's own older notes claiming it turns on a breath are describing something else. What hangs here is the solution to a chosen system of equations, held still because it was never going to do anything else.


Three struts and three orange joints, with a rhythmic squeeze arriving every few seconds. Watch the width as the height contracts. The whole object is being scaled: the source writes a sine-driven change directly into its transform. It looks as though a load arrives and is refused, but no load has been applied and no member force is calculated.

There is a structural question worth keeping inside that appearance. An ideal hinged triangle with fixed side lengths cannot rack in its plane as an unbraced four-bar frame can. A side-by-side load experiment could let you test that difference. This animated triangle has not done that experiment for us.

One correction the name will not make for you. It promises a tensegrity, but the three struts meet at their joints and there is not a tension cable in the object. Keep the distinction between an attractive pose and the force relations needed to sustain it. In the next hall, an apparently impossible table will ask for that distinction again, with an unbothered teacup on top.


A steel tower three and a half metres tall standing on a seven-metre plate, four fat corner legs and four stacked panels of cross-bracing, an orange beacon at the top. Its board now says RECURSIVE BRACED STOREYS / NO LOAD TEST. The old promise of maximum strength for minimum material remains an interesting aim. This construction has not measured either quantity.

The recursion halves the tower vertically and braces each half again, so what recurses is the storey and not the strut, and the finer legs it adds lie along the same corner lines as the coarse ones, hidden inside them. A beam made of beams is the idea. Stacked bracing, three deep, is the building. Its slight sway is prescribed too; the tower is not responding to a wind or testing a failure threshold.


The screen has no live load measurement from these objects. Its generic scanner can classify a tower by the word “fractal” and count children, but neither quantity establishes a balance. For the mobile, we need the two mass-distance products at each joint; for the tower, a stated load and a measured response. The nameplates are a beginning. A picture of structure is not yet an instrument for its strength.


## Gravity as co-designer

Gaudí's hanging models offered another way to approach this problem: set up weights and supports, allow a physical relation to appear, and study its inversion as a possible compression structure. The load and the boundary matter as much as the curve. The model is a way to reason with gravity, not a certificate that every shape it suggests will stand.[^FormFinding_Equilibrium--hanging-model]

Our three objects make different parts of that reasoning available. The mobile exposes a balance encoded in its mass model. The triangle lets us catch an animation passing for resistance. The truss makes repetition and bracing visible while leaving strength untested. Their differences give us the next experiments: change a mass, compare a hinged square, put a specified load on the tower. Those encounters are still to be built.

One thing to carry out. Before asking whether a form has reached the bottom, ask what was allowed to move and what counted as success. The next hall asks whether the bottom is where you want to be.

Next: how to leave a hole you have already fallen into, and why you might not want the deepest one.

[^FormFinding_Equilibrium--hanging-model]: Santiago Huerta, [“Structural design in the work of Gaudí”](https://oa.upm.es/703/) (2006). The physical equilibrium method is a reference for these digital models, not a claim that their rendered members currently solve it.

---

## FormFinding Annealing

*FormFinding_Annealing*

You have to be willing to get worse to get better. And then the room asks a harder question: how far down do you actually want to go?

The first stable shape you fall into need not be the one you want. The point in the first hall could finish in different valleys, and the rooms since have changed what makes a shape hold: a drafted curve, a formula, a finite relaxation, an encoded relation. This is the room that knows the trick for getting out, and the room that argues the trick can be taken too far.

## Getting out


A bench with a wrinkled tabletop: four hundred and eighty-four little boxes standing at the height of an energy field, three sine waves crossed, coloured from blue in the troughs to violet on the ridges. A soft yellow blob sits in one of the hollows. Gravity and local downhill nudges draw it toward lower parts of the surface; no rule surveys all the basins for the deepest one. The first hall's question returns in another body: what can a local move discover, and what can it miss?


The cabinet that fixes it: a dark survey table, waist high, with a milled basin holding a metre and a half of glowing relief. The surface is the Rastrigin function, the particular cruelty here: a smooth bowl with a cosine corrugation laid over it so that it has one true bottom and a regular grid of decoys all the way out. A temperature starts at a hundred; the run stops at a tenth or at its step limit. The rail's histogram groups the acceptance probabilities assigned to uphill proposals. The separate accept percentage counts all accepted proposals, including downhill ones.

Run it hot and larger uphill proposals can be accepted. As it cools, the random proposals shrink and costly ones become less likely to pass. This is still a search through random neighbours, not the gradient rule from the first hall. START T sets the next reset's temperature; moving it during a run also changes the proposal scale, without directly replacing the current temperature.

```gdscript
var delta_energy: float = neighbor_energy - current_energy
var accept: bool = false
if delta_energy < 0:
    accept = true
else:
    var probability: float = exp(-delta_energy / maxf(current_temperature, 0.0001))
    accept = randf() < probability
```

A better move is always taken. A worse move is taken with a probability that depends on how much worse it is and how hot things are. That second branch is annealing's central permission, and it is a strange thing to write down: a rule that sometimes accepts a worse outcome so that a local improvement need not become a prison.

The numbers behind the gauge are worth a moment. A move costing five hundredths of an energy unit has an acceptance probability of about 0.779 at a temperature of a fifth. At two thousandths it would be about 1.39 × 10⁻¹¹: extraordinarily unlikely, not zero, and below this run's stopping temperature. The cabinet also watches recent acceptance and adjusts its cooling rate. After eighty successive proposals without a downhill improvement, a separate rule can force a random relocation and reheat the search. HOP invokes that relocation directly; it does not ask the acceptance branch for permission. This is a machine built around the admission that its own local rule can get stuck.


And then the turn toward two wells in a low, open tank. Approach the narrow well from its outside edge and look down into it. Compare them before pressing INTERPRET. What stays still? What keeps changing? The lower result and the more responsive result have been placed beside one another, but have they been given the same conditions?

On one side a deep, narrow pit holds a static cube. On the other a broad, shallow basin holds something soft that keeps moving, finding a shape and losing it and finding it again. The difference is staged: the cube is a mesh with no motion assigned, while the soft lattice receives a random jostle every two and a half seconds. Its floor constraint and the drawn bowl are separate constructions. These are different receivers under different conditions, not two runs of one measured objective.

Press INTERPRET after the comparison. The work proposes that the more responsive form is the better minimum, and gives that preference the name Q. Its dead-perfect crystal and its still-changing body are roles in an argument: low enough to hold, high enough to be moved. The installation has authored those roles; it has not measured a universal boundary between life and rest.


A further image, standing in the room as furniture: an end table whose top never touches its base. Two steel brackets overlap in plan with sixteen centimetres of daylight between them, joined in the drawing by one central cable and three perimeter cables. A teacup on top, unbothered. The pose refers to tension-supported furniture, but no force or contact solver tests whether this pictured arrangement can stand.

Islands of compression in a sea of tension is the invitation. Here the brackets and cables are meshes placed at chosen addresses. Their stillness does not establish cancelling forces; the scene never lets gravity trouble the teacup. What would a physical version have to demonstrate that this image can only ask?


A screen, washing the wall green. Its diagram is another representation, not a measurement of Q in the two wells. Depth alone would leave out the different receivers and the disturbance supplied to one of them. The comparison asks which of those differences matters to the purpose we have chosen.


## Low enough to hold, high enough to be moved

That is the chapter, and it ends by turning against its own first sentence. Finding a form has meant several different operations: a point following a local slope, a cable drafted between controls, a surface generated from a formula, a mesh retaining a finite relaxation, a mobile drawn to satisfy ideal moments. None gives us permission to treat every still shape as the least-cost answer to the same problem.

Then this one. Reaching the lowest value in a model is not the same as finding the form you want. A shallow basin can preserve a useful response to disturbance even when a deeper basin gives a lower score. That comparison is a choice about this model's purpose, not a test that separates living matter from dead matter.

Next: build a form and inspect the rule that decides whether it has settled well enough.

---

## FormFinding Forge

*FormFinding_Forge*

# A shape that counts

Who decides when a shape has settled well enough?


Arrange the loose pieces into a stack, then let go. Watch the height and stability display. If the pieces fall into a quiet heap, compare that stillness with a taller arrangement that holds. Both can stop moving, but the puzzle does not treat them as the same result.

Its recognition asks for height as well as a period of sufficiently small movement. A low heap can therefore be stable and still fail its test. When a raised arrangement meets both conditions, the transformation animation begins. The animation acknowledges the detector's decision; it does not establish that the arrangement has become biologically alive.

Try another construction before accepting the first as the answer. The pieces and their contacts constrain what can stand, while the height condition selects which standing forms will count. That second choice belongs to the task's author as much as to gravity.


At the neighbouring optimiser, follow the point and its trail across the coloured surface. The energy readout and step count give you something to compare with its motion. Look for the slowing approach to a resting region and the later start from a different position.

Choose a short section of the optimiser's trail and compare its beginning with its end. Follow the energy readout while new steps appear, then notice whether the path changes direction or simply continues straight. A curved path can arise because the direction of descent changes from place to place. When the demonstration begins from another position, choose a second section rather than assuming it must retrace the first. Compare the approaches to a low region, leaving the question of the final destination open. This gives you two histories to explain, instead of treating the resting point as the only part of the calculation that matters.

Here a numerical rule estimates the local slope in two directions and takes a small step downhill. It repeats that operation, retaining a short record of previous positions. The surface supplies the quantity being reduced. After more than thirty steps, the demonstration starts again when the sampled slope is below 0.002, or when the frame edge permits a step smaller than 0.002 times the learning rate. That second ending is marked BOUNDARY: a limit on the permitted move, not a claim that the surface is flat. A small local slope is not proof that the point has found the best possible place on every landscape.


Build a low arrangement that you find useful and the puzzle refuses. Describe its usefulness without pretending it passed. This is a precise way to question a success criterion: retain the physical result and change what you ask it to mean.

The next sequence begins with oscillation. A form can persist through returning motion as well as through rest; settling is only one way for a system to continue.

---
