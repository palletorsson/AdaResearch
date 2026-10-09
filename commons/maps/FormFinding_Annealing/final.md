# Willing to get worse

You have to be willing to get worse to get better. And then the room asks a harder question: how far down do you actually want to go?

The first stable shape you fall into need not be the one you want. The point in the first hall could finish in different valleys, and the rooms since have changed what makes a shape hold: a drafted curve, a formula, a finite relaxation, an encoded relation. This is the room that knows the trick for getting out, and the room that argues the trick can be taken too far.

## Getting out

<!-- @energy_landscape_bench -->

A bench with a wrinkled tabletop: four hundred and eighty-four little boxes standing at the height of an energy field, three sine waves crossed, coloured from blue in the troughs to violet on the ridges. A soft yellow blob sits in one of the hollows. Gravity and local downhill nudges draw it toward lower parts of the surface; no rule surveys all the basins for the deepest one. The first hall's question returns in another body: what can a local move discover, and what can it miss?

<!-- @simulated_annealing -->

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

<!-- @max_q_basin_room -->

And then the turn toward two wells in a low, open tank. Approach the narrow well from its outside edge and look down into it. Compare them before pressing INTERPRET. What stays still? What keeps changing? The lower result and the more responsive result have been placed beside one another, but have they been given the same conditions?

![Looking into the deep well from its outside edge inside the museum](/book-images/figures/formfinding/deep-well-museum.png)

*The deep well from its outside edge at standing eye height. The cube at the bottom does not move.*

On one side a deep, narrow pit holds a static cube. On the other a broad, shallow basin holds something soft that keeps moving, finding a shape and losing it and finding it again. The difference is staged: the cube is a mesh with no motion assigned, while the soft lattice receives a random jostle every two and a half seconds. Its floor constraint and the drawn bowl are separate constructions. These are different receivers under different conditions, not two runs of one measured objective.

Press INTERPRET after the comparison. The work proposes that the more responsive form is the better minimum, and gives that preference the name Q. Its dead-perfect crystal and its still-changing body are roles in an argument: low enough to hold, high enough to be moved. The installation has authored those roles; it has not measured a universal boundary between life and rest.

<!-- @impossible_end_table -->

A further image, standing in the room as furniture: an end table whose top never touches its base. Two steel brackets overlap in plan with sixteen centimetres of daylight between them, joined in the drawing by one central cable and three perimeter cables. A teacup on top, unbothered. The pose refers to tension-supported furniture, but no force or contact solver tests whether this pictured arrangement can stand.

Islands of compression in a sea of tension is the invitation. Here the brackets and cables are meshes placed at chosen addresses. Their stillness does not establish cancelling forces; the scene never lets gravity trouble the teacup. What would a physical version have to demonstrate that this image can only ask?

<!-- @science_screen -->

A screen, washing the wall green. Its diagram is another representation, not a measurement of Q in the two wells. Depth alone would leave out the different receivers and the disturbance supplied to one of them. The comparison asks which of those differences matters to the purpose we have chosen.

<!-- @ -->

## Low enough to hold, high enough to be moved

That is the chapter, and it ends by turning against its own first sentence. Finding a form has meant several different operations: a point following a local slope, a cable drafted between controls, a surface generated from a formula, a mesh retaining a finite relaxation, a mobile drawn to satisfy ideal moments. None gives us permission to treat every still shape as the least-cost answer to the same problem.

Then this one. Reaching the lowest value in a model is not the same as finding the form you want. A shallow basin can preserve a useful response to disturbance even when a deeper basin gives a lower score. That comparison is a choice about this model's purpose, not a test that separates living matter from dead matter.

Next: build a form and inspect the rule that decides whether it has settled well enough.
