# What makes an encounter?

<!-- @arena_relation_lab -->

The four-legged walker has acquired a small dark body. A familiar shape, perhaps already carrying the expectation that it will jump at you. Before it moves, notice what you have brought into the room with it.

Press RUN. The creature heads toward the blue beacon. Move BEACON to one side. Offer FOOD. Something about the same animal's direction changes. Nothing in its legs has been replaced.

Follow it to the mushroom. It pauses over the food and lowers its body. Wait. The pause belongs to the action: arriving is not yet having eaten. After two seconds, the meal is completed and the animal can move again. What does it go toward now?

This encounter considers two candidates: its own offered mushroom and one nominated visitor. At the beginning, that visitor is the beacon. Press VISITOR to take its place yourself. The board says YOU. Walk closer, or let the food be closer. You and the mushroom now enter the same comparison.

There is no bite in this version. That changes what you can risk while looking, without changing the question of how a target becomes a target. The other crabs retained deeper in the Arena have their own configurations; the panel controls this one experiment.

Now bring up SCREEN. A wall appears between the opening positions of the creature and the central beacon. The beacon has not ceased to exist. Move it to the side, or move yourself until the line clears the wall. Which part of the world is available to this creature now?

Reveal PARTS. The candidate label and line expose a current selection, while the completed-meal count records something that has happened. The two numbers are doing different kinds of work.

```gdscript
if d<distance and _sees(candidate.global_position):
    best=candidate
    distance=d
    bait=candidate==station.food
```

The closest visible candidate within six metres wins. Food is not given a higher rank simply for being food. A nearer beacon can win instead. This is a scoped version of the existing crab's selection: one nominated visitor and this station's mushroom, rather than every eligible object in the museum. It has no sight memory. A blocked candidate cannot continue drawing it through a remembered target, although the inherited controller can briefly exclude a candidate it has failed to reach.

Look at the sight line again. The query runs horizontally, twenty centimetres above the floor. Candidate distance, however, uses the three-dimensional positions of the nodes. Seeing and measuring do not even use quite the same world. The golden line on our floor is a display of selection, not a camera image from the creature's eyes.

A meal holds its attention for two seconds once feeding begins. Moving another candidate during that interval does not interrupt the meal. Offer another mushroom after the first is gone. The counter rises. At five completed meals, the creature stops moving.

```gdscript
_rooted = true
can_bite = false
_target = null
_lunge_t = 0.0
patrol_speed = 0.0
chase_speed = 0.0
```

There is a name in the source for this state: rooted. It does not currently grow branches. The same body remains, with a different set of actions available to it. Five is a threshold somebody chose; feeding has changed state, not trained a new policy. How quickly might we have called this trust, taming, exhaustion, or friendship if the counter and the code had stayed hidden?

That gap can hold an artistic question without being passed off as evidence. What relation do you feel when the creature approaches? What changes when it leaves you for something else? We can alter the conditions of that encounter and watch our own interpretation arrive beside its implementation.

RESET replaces this animal with an unfed one and keeps the panel choices. It is a new experimental beginning, not the creature forgetting its meals. RUN can pause this creature's controller, including a meal. The food's brief appearance and disappearance animations use their own clock; the rest of the museum continues. The golden perimeter pauses observation if the animal leaves the central area; it does not imprison it with a physical collision.

As in Legs, its movement is a commanded position change. The feet plant and swing, and the controller uses obstacle queries to limit steps. There is no integrated body momentum to conserve. The next exhibit asks what an encounter would have to share if that conservation were part of its rule.

## What the collision shares

If momentum is conserved, why can two collisions look so different?

<!-- @collision_carts -->

The carts are shown twice: before the encounter on the upper track and after it on the lower one. Find the striker’s incoming arrow in the first view and look for its outgoing arrow in the second. Move MASS RATIO and follow what happens to that arrow before worrying about the formula.

For a light striker, it points back. Near equal masses, the striker's outgoing arrow disappears while the other cart takes the motion forward. With a heavier striker, both outgoing arrows can point in the original direction. The control changes the comparison; these are diagrams of possible outcomes rather than carts repeatedly colliding in front of you.

Keep one mass setting while comparing the upper and lower tracks. Identify the striker by its colour and width, not merely by which cart has the longer arrow. Check that you are comparing the same body before and after. Then follow the other cart across the two views. Its initial lack of an arrow and its later forward arrow belong to one change, while the striker's change belongs to another. Describe both before saying that motion was lost. As you adjust the mass ratio, watch the striker's width too: the control changes the body's represented mass as well as the resulting velocity arrows.

Momentum combines mass with velocity, including its direction. A small body moving quickly and a large body moving slowly can contribute comparable amounts. Conservation constrains the total across the two bodies. It does not require each body to keep its own speed, or even its original direction.

The diagram assumes an isolated, elastic collision along one line. Its target starts at rest, and the striker's initial speed stays fixed. Those conditions matter. Two carts that stick together would answer a different collision rule, even though total momentum could still be conserved. The control here changes mass ratio; it does not offer a choice between bouncing and sticking.

Predict which way the striker will leave before crossing the equal-mass setting. Then ask a different question: which cart would be easier to catch afterwards? The quantity the model preserves and the consequence a visitor cares about need not be the same thing. Even the arrows require care: they are drawn for legibility, so their physical lengths are not a precision measuring instrument.

<!-- @ -->

The next room considers force as a place. Bring the habit of looking at the whole relationship before judging an outcome from one body's motion.
