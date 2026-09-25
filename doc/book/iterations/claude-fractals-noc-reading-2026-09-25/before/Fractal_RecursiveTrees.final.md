# Where will the next branch go?

<!-- @recursive_tree_2 -->

A trunk waits. Where would you put its first fork?

Press GROW. Two branches appear at its tip. Press again, following one of those branches rather than the outline of the whole tree. Each new pair begins where a previous segment ends. Predict the next fork before asking for it.

The previous room let one call become several. Here we give those calls a place to start, a direction and a length. Four presses leave thirty-one segments, including the trunk. The fourth generation contains sixteen of them. Shorter branches do not mean fewer branches.

Leave the generation count where it is and press ANGLE. The tree opens. Press again: its branches draw closer to the direction their parents were taking. The button cycles through three turns, measured from the parent direction. Follow the same first fork. Its descendants have moved, but none has been added or removed.

Now press LENGTH. The ratio changes from 0.70 to 0.85: each child inherits more of its parent's length. The next press takes it to 0.50. You can make a crowded body or a much smaller one without changing the number of segments. Walk around it. A branch that seemed short from the desk may have been pointing towards you.

These lines come from the growing tree's implementation:

```gdscript
var new_length = parent_data.length * length_reduction
```

And, after the new direction has been calculated:

```gdscript
var end_position = parent_pos + branch_direction * new_length
```

The second line hands the next fork its beginning. A vector, a multiplication and an addition carry the body further. What looked like a tree can be followed as a succession of these handovers.

Press FORKS at the fourth generation. Three descendants now leave each tip. The display rises from thirty-one to one hundred and twenty-one segments. This change adds connections to the branching graph; turning or lengthening its existing edges did not. A visible crossing of two branches still does not join them in the program.

RESET returns to the trunk and the original settings. This specimen uses no random variation. Repeat the same choices and the same branches return. Growth here is a queue of instructions, advanced one generation at a time. The surrounding museum continues while the tree waits.

There is no light to seek, no root taking water, no neighbour whose shade changes the next fork. The branches are visible meshes; they do not offer the player's body a climbable support. Their outline invites a promise that their implementation has not made. What would we have to add for one of these forks to become shelter?

<!-- @recursive_tree -->

Across the approach, the red block tree has already spent its calls. Choose a large branch and follow it towards its smaller descendants. At a fork, predict the next division, then find another fork at a similar depth. A shared procedure need not give them the same dimensions or the same number of children.

Press STRATA. Colour separates three branching levels from the trunk. Follow a route to its last visible block. REACH draws the accumulated bounds; ENDS adds marks at the handover and terminal branches. FORM returns the original colours. These readings belong to the same built geometry. Changing the view does not draw another tree.

This tree does use random choices, from the seed shown on its desk. The choices vary its branches within a fixed construction rule. A seed can repeat an arrangement; it cannot tell us which arrangements the rule never permits. Even the blunt boxes can persuade us to call it organic. We can enjoy that recognition and still ask what it has made too easy to recognise.

<!-- @ -->

Further in, the downward trees, the mesh fractal, the desk and the small subdivision cubes keep other possibilities in view. They need not all answer the same question. The old enclosure remains a detour around something we cannot see from every position. We have more procedures to learn before resemblance becomes our only way to choose a body.

Next comes Cantor: another generation, this time made by deciding what will be removed.
