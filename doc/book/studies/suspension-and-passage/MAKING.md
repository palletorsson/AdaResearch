# One choice at each address

This is a return after **Array / Tutorial_3D**. Day Zero has supplied the working project. Coordinates gives a place; Translation moves it; the array gives two indices. Point One has already distinguished a visible form from a collider. Here those operations meet in a small rule.

The making task is to choose **which seven pieces leave room below them**. We borrow the fragment mesh, material, collision bodies, room and walking controller. Constructing those systems would be another lesson.

Open `commons/artifacts/suspension_passage/score.gd` in the downloaded project. Every displayed fragment really reads this score. The first arrangement chooses:

```gdscript
return x == 3
```

The addresses run from zero to six. In every row, column three is raised. The coordinate changes only in height; the fragment's identity and mesh remain attached to its address.

First change `3` to `2`. Run the project as you already know how. Predict where the passage moved, then walk to it. The height count should remain seven. This one change is enough for the first exercise.

The second arrangement chooses:

```gdscript
return x == (2 * z) % SIDE
```

For rows zero to six, the selected columns are **0, 2, 4, 6, 1, 3, 5**. `% SIDE` keeps the remainder after division by seven, wrapping the selection into the seven available columns. There is still one raised piece per row. Successive openings no longer meet as a passage for this walking body.

The row rule is easier to understand after the first comparison. It is not necessary to learn modulo, mesh construction and pathfinding all at once.

You can also edit the arrangement without writing code: click two cells at different heights in the small grid. They exchange heights; the total stays seven. A click on the same cell cancels the selection. These swaps affect the running scene and reset when you choose a preset; they do not rewrite the score file.

For a first work, make a route that turns once. Keep seven raised cells initially. If you need another, decide what to exchange or whether your chosen budget should change. Do not promise that every seven-cell pattern can connect opposite edges. Offer the arrangement to another person before telling them your intended path.

The **Body** button changes the supplied capsule from 0.56 m to 1.32 m wide while retaining its 1.75 m height. These are two declared probes, not a model of the range of human bodies. The artwork stays fixed. The question becomes: which part of the arrangement must change for this other volume to pass?

The executable score is kept separately below. The larger fabrication and viewer scripts are supplied apparatus. No pathfinding algorithm is required to author this study.
