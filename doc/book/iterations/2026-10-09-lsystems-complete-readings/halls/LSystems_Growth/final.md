# What a branch remembers

<!-- @parametric_lsystem -->

A short upright line, a pale point at its tip. Beside it, a second reading waits. We have brought the turtle out of Grammar Lab. There, we changed the angle of a sentence. Here we follow what it carries from one instruction to the next.

The sentence is already written:

```text
F[+F]F[-F]F
```

Its rule comes from a small family in Prusinkiewicz and Lindenmayer’s *The Algorithmic Beauty of Plants*.[^abop] The first F has drawn a line. What must the turtle keep if it is to leave the trunk, make a branch, and find its way back?

The dark sphere is our handle; the pale point records where the drawing has arrived. Step to the opening bracket. Nothing extends. The readout says SAVE. A state has been kept, and the next stride has shortened, although the point has not moved. An operation has taken place without adding anything to the outline.

Continue through the turn and the shorter branch. Hold this reading before its closing bracket. The witness keeps its pale point at the branch end.

Where will the live point go?

It returns to the fork. The branch remains, with no return line joining its tip to the trunk. The next F continues upward from the saved place. The branch's turn and shorter stride have not become the trunk's next instructions.

A branch may contain another branch. The most recent departure must be recovered first. Position returns with direction and stride; restoring only the place would leave the turtle facing somewhere else. What it can recover depends on what was saved.

A return can preserve what happened during a departure while allowing something else to continue. The drawing does not have to erase its branch to resume its trunk.

Keep a complete reading, then change the branch ratio. At one, a branch takes the same stride as its parent. Above one, it becomes longer. The sentence and turns stay fixed, and both drawings use metres. Neither is squeezed to fit its plinth.

The code calls the value length_decay. Its name suggested shortening. The multiplication permits something else. Which proportion made this drawing look like a proper tree to us?

Read another generation. The unshortened trunk reaches above us; a branch within a branch applies the ratio again. The earlier drawing stays beside it. We can follow the local decision and still be surprised by the room it begins to occupy.

The stack offers a dependable return for the state its programmer chose to save. It contains no sunlight, weight or account of a neighbouring body. These branches have no collision surfaces. Resemblance has brought us to the idea of a tree; support, shelter and obstruction would ask for further work.

<!-- @ -->

The animated tree, obstacle-querying tree, earlier L-system tree and cypress remain beyond the desk. They approach growth through other operations. Carry the saved state forward. In the next hall, even forward may be read sideways.

[^abop]: Przemyslaw Prusinkiewicz and Aristid Lindenmayer, *The Algorithmic Beauty of Plants* (Springer, 1990), figure 1.24: F[+F]F[−F]F is its (a), Competition’s F[+F]F[−F][F] its (b), and the believing turtle’s FF+[+F−F−F]−[−F+F+F] and Grammar Lab’s PLANT preset are its (c) and (f) with the turns mirrored.
