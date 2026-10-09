# What a branch remembers

<!-- @parametric_lsystem -->

A short upright line, a pale point at its tip. Beside it, a second reading waits. We have brought the turtle out of Grammar Lab. There, we changed the angle of a sentence. Here we can follow what the turtle carries from one instruction to the next.

The sentence is already written:

```text
F[+F]F[-F]F
```

This tree's rule replaced one F with those eleven symbols. Its first F has drawn a line 0.8 metres long. The pale point marks the turtle's current position. What must it keep if it is to leave the trunk, make a branch, and find its way back?

Press STEP once. Nothing extends. The next symbol is `[`. The readout says SAVE; the stack count becomes one. The next length has changed from 0.800 to 0.576 metres, although the point has not moved. An operation has taken place without adding anything to the outline.

STEP again: `+` changes the direction. Another STEP reaches F, and the shorter branch appears. HOLD this reading. The pink point stays at the new tip.

Now comes `]`. Where will the live point go?

It returns to the fork. The branch remains drawn, with no return line joining its tip to the fork. Next length is 0.800 again. Press STEP: the trunk continues upward from the saved position. The branch's turn and shorter stride have not become the trunk's next instructions.

The turtle carries a state: position, orientation, length, angle and branching depth. At `[`, the interpreter puts a copy on a stack. A stack returns the most recently saved record first. One branch may contain another; the inner branch must finish before we return from the outer one. This nesting gives a small program a way to remember several departures without confusing their returns.

After saving, the source changes two values for the branch:

```gdscript
current_length *= length_decay
current_angle *= 0.95
```

The first line means: take the length we have and multiply it by the ratio. Here, 0.8 × 0.72 gives 0.576 metres. The second changes forty degrees to thirty-eight. F still means draw forward, but how far forward now depends on the state in which the turtle reads it.

At `]`, this excerpt from `parametric_lsystem.gd` retrieves the saved record:

```gdscript
var state: Dictionary = stack.pop_back()
pos = state["pos"]
dir = state["dir"]
right = state["right"]
up = state["up"]
depth = state["depth"]
current_length = state["length"]
current_angle = state["angle"]
```

Position returns, the orientation axes return, and the previous length becomes available again. None of these assignments removes a segment already drawn. A return can preserve what happened during a departure while allowing something else to continue.

Keep stepping until all eleven symbols have been read. Five segments, two side branches, a stack empty again. HOLD the complete reading. Then press RATIO once: 0.72 becomes 1.00. Follow a side branch against its held counterpart. It now takes the same 0.8-metre stride as the trunk. The sentence and turning directions have stayed the same. Both drawings use metres; neither is squeezed to fit its plinth.

Press RATIO again. At 1.15, the branch is longer than the segment from which it departs: 0.92 metres. The code calls this value `length_decay`. Its name suggested shortening. The multiplication also permits something else. Which proportion made this drawing look like a proper tree to us?

TREE shows two complete rewriting generations. There are now sixty-one symbols and twenty-five drawn segments. The unshortened trunk reaches 7.2 metres above its starting point. Within a branch inside another branch, the length factor is applied twice: 0.8 × 1.15 × 1.15 = 1.058 metres. The pink first generation remains beside it until we choose to hold another reading. We can follow a local rule and still be surprised by the room it begins to occupy.

STEP reveals a recorded trace of the interpreter; it does not make the computer wait between its calculations. TREE requests another sentence. These are two different ways of looking into a process that would otherwise arrive as a finished drawing. RESET brings back the first line when we want to follow it again.

The stack offers a dependable return, but only for the state its programmer chose to save. It contains no sunlight, weight or account of a neighbouring body. The thin branches have no collision surfaces. Their resemblance to a tree leaves those further requirements open. What would we have to add before this branching could support, shelter or obstruct us?

<!-- @ -->

The animated tree, the obstacle-querying tree, the earlier L-system tree and the cypress remain beyond the desk. They approach growth through other operations. Carry this distinction forward: a sentence supplies instructions; an interpreter decides what they do. In the next hall, even forward may be read sideways.
