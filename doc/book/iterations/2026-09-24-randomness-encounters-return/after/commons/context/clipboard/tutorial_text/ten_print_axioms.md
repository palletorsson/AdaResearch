# 10 PRINT

Two diagonals, many possible arrangements.

```basic
10 PRINT CHR$(205.5+RND(1)); : GOTO 10
```

A draw selects one of two characters. The trailing semicolon keeps the next character on the same line; the screen wraps them into rows. No cell consults its neighbours. Neighbouring marks meet because the grid gives their endpoints shared positions.

## From a mark to a passage

The printed pattern is not yet a walkable maze. A solid wall, a line without collision and a route for a simulated ant give different consequences to the same diagonal. Joining four marks can close a figure while closing a body out of its interior.

In the upright animated fields, several cells turn each second. Those fields have no wall collision for the visitor. The ant follows its own navigation grid, which can close a channel that appears open between the drawn marks. Each change also clears the ant's recorded visits. Its confinement comes from the navigation procedure as well as the image.

## Who chooses what may vary?

The two-choice vocabulary does not by itself determine who can move here. The spacing, crop, thickness, collision and navigation rules participate too. A complex picture is not evidence that a body has become freer. Find an opening and ask whether the body you have been given can use it.

10 PRINT builds patterns from independent choices. A cellular automaton instead makes a cell's next state depend on a local neighbourhood. Their resemblance does not make their procedures the same.
