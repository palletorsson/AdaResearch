# The line that decides

When does a value become a place a body can occupy?

<!-- @perlin_terrain_sculptor -->

A model stands on the bench: a cube of cells, twenty-four to a side, most of them empty and the rest filled with small green blocks. Across the room a terrain made of the same blocks runs away from you at a size you could walk into. They are not two landscapes. They are one field, asked the same question at two magnifications, and the bench is where you can see the question being asked.

A yellow cage marks one cell. The plate names it and shows its whole case:

    cell 15,12,15   field -0.1364   bias +0.0109
    -0.1364 − +0.0109 = -0.1473  >  +0.10   →   empty

Four numbers and one comparison. The field has a value at that place; the height bias subtracts a little more the higher you go, which is what makes a terrain rather than a cloud; the threshold is a line; and the cell is occupied if what is left is above the line.

```gdscript
static func contract_occupied(value: float, v: float, threshold: float) -> bool:
	return value - contract_bias(v) > threshold
```

That is the whole of the rule. It is worth saying plainly what kind of rule it is: a value that varies smoothly and continuously across space is being turned into an answer with exactly two possible states. Everything between −1 and +1 arrives, and occupied or empty leaves.

Press THRESHOLD. The line moves, and the model changes — but look at the plate while you do it. The `field` figure at the marked cell does not move a digit. The same value is standing in the same place; only the line under it moved. The count at the bottom changes: 10925 cells occupied at −0.20, then 8887, then 6549, 4315, 2421.

Those numbers can only go one way. Raising a line that things must exceed cannot let anything new past it, and the room is built so that you could check this yourself rather than take it on trust: the count falls at every step and never once rises. If you had found it rise, either the field had moved or the predicate was not what the plate says it is.

Now the sentence at the bottom of the plate, which is the one to carry out of the room:

    4995 of 13824 cells occupied, in 29 separate pieces (the largest 4830)
    connected is not walkable: this is a set of cells, not a verified passage

Twenty-nine pieces means twenty-nine groups of cells that touch each other face to face. Raise the threshold and watch a thin neck between two of them thin further and then vanish — a bridge that was one cell wide is exactly as strong as the smallest value along it. But a piece being connected in the lattice says nothing about whether a body could walk it. A body needs a floor under it, room above it, a way in, and a slope it can climb. Occupancy is a fact about cells; passage is a fact about bodies; and a room that let you slide from one to the other would be teaching you to trust a map that has never been walked.

The terrain across the room is the same field, the same seed, the same bias and the same line, at another size. When you move the threshold here it moves there — and only there. That is worth a sentence because it was not true a day ago: the bench announced its settings to every receiver in the building, which in a museum that streams several halls at once meant retuning a terrain two rooms away that nobody was standing in.

<!-- @ -->

Noise 6 Wall follows. Carry the two-state answer with you and notice what it cost: a value that knew about degrees arrived, and a decision that knows only yes and no left.
