You have to be willing to get worse to get better. And then the room asks a harder question: how far down do you actually want to go?

The first stable shape you fall into is rarely the best one. The marble in the first hall found the nearest bottom, not the lowest, and every settling thing since has done the same. This is the room that knows the trick for getting out, and the room that argues the trick can be taken too far.

```gdscript
var delta_energy: float = neighbor_energy - current_energy
var accept: bool = false
if delta_energy < 0:
    accept = true
else:
    var probability: float = exp(-delta_energy / maxf(current_temperature, 0.0001))
    accept = randf() < probability
```

A better move is always taken. A worse move is taken with a probability that depends on how much worse it is and how hot things are. That second branch is the entire idea, and it is a strange thing to write down: a rule that deliberately accepts a bad outcome, because a run of bad outcomes is the only way out of a hole.

## Getting out

<!-- @energy_landscape_bench -->

A bench with a wrinkled tabletop: four hundred and eighty-four little boxes standing at the height of an energy field, three sine waves crossed, coloured from blue in the troughs to violet on the ridges. A soft yellow blob sits in one of the hollows. It descends into whichever basin it was dropped above and stays there, which is the first hall's marble again on a surface with more than one bottom, and it is here as the thing that needs fixing.

<!-- @simulated_annealing -->

The cabinet that fixes it: a dark survey table, waist high, with a milled basin holding a metre and a half of glowing relief. The surface is the Rastrigin function, which is the standard cruelty of this field, a smooth bowl with a cosine corrugation laid over it so that it has one true bottom and a regular grid of decoys all the way out. A temperature starts at a hundred and cools toward a tenth. A gauge along the rail shows how often a worse move is being accepted.

Run it hot and the search wanders almost anywhere, uphill as readily as down. Run it cold and it is gradient descent again, refusing every backward step. Cool it in between and it explores first and commits later.

The numbers behind the gauge are worth a moment. A move costing five hundredths of an energy unit is accepted about four times in five at a temperature of a fifth, and never at all at two thousandths. And when the search stops improving for long enough, the cabinet does not wait: it hops the whole solution to a new basin and starts again from there. This is a machine built around the admission that its own best rule gets stuck.

<!-- @max_q_basin_room -->

And then the turn, and you will have to look up to find it. Two wells cut into one seven-metre plate, and the plate is hanging three and a third metres over your head: it shares its cell with the spawn and got bumped, then the grounding pass lifted it clear of the walls, so the room's argument is on the ceiling and the frozen cube in its dead well dangles at about your eye level.

On one side a narrow pit two and a fifth metres deep with steep walls, holding a single rigid half-metre cube. It is at the lowest energy here, it is perfectly settled, and it will never be anything else. On the other a broad shallow basin with something soft in it that keeps moving, finding a shape and losing it and finding it again. That one is higher up. By the arithmetic of the previous four halls it is worse.

The claim on the floor is that it is the better minimum, and the room calls the difference Q. The deepest well is a dead-perfect crystal, finished. A form that can still be moved has to be resting somewhere shallow enough to be moved out of, which means the liveliest place in an energy landscape is never the bottom of it.

<!-- @impossible_end_table -->

The proof that this is not a metaphor, standing in the room as furniture, and the tensegrity the last hall promised and did not deliver. An end table whose top never touches its base: two steel Y-brackets whose arms overlap in plan with sixteen centimetres of daylight between them, one central cable holding the top down against three perimeter cables that stop it swaying. A teacup on top, unbothered.

Islands of compression in a sea of tension. Nothing here is resting on anything. Every part is being pulled, hard, in a direction that exactly cancels, and the stillness of the teacup is the sum of forces that never stop.

<!-- @science_screen -->

A screen, washing the wall green. Had it looked up it would have drawn two basins and drawn the deeper one deeper, because depth is the only quantity a diagram of this kind carries. Q is the difference between those two wells, and depth is precisely the axis on which the shallow one loses.

<!-- @ -->

## Low enough to hold, high enough to be moved

That is the chapter, and it ends by turning against its own first sentence. A form is the answer to a minimisation problem, and matter finds those answers by falling. Four halls of that: the marble, the chain, the settling mesh, the balanced mobile, none of them drawn, each one the shape that costs the least.

Then this one. If falling all the way down is how a form is found, the fully found form is a crystal, and a crystal is over. What is alive is what stopped part way, in a basin wide enough that it can be knocked about and come back, resting at a minimum it has not finished with.

Next: the same question in the language of matter that will not hold still at all.
