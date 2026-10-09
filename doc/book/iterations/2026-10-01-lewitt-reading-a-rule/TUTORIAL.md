# From one frame to a family

You have already run a project. Here the room, camera and bar renderer are supplied. We will work on the positions and the rules that choose between them. Open `rules.gd` beside the running study.

## 1. What is the smallest thing we need?

Start with **Five forms**, not the large installation. Look through the cube. Its interior is empty. We need eight corner positions and twelve connections: four around the bottom, four around the top, four joining the two squares.

This is the Line operation repeated. Each bar has two endpoints, a midpoint and a length. The renderer gives the connection thickness so we can see it. It does not fill the opening with a face or make an invisible solid box.

Move the reveal slider to the left, then slowly right. Follow the bottom square, the upper square and their connections. Orbit the result: a connection hidden by another bar from one position becomes visible from another.

The cube lesson's twelve **triangles** and this frame's twelve **edges** are different descriptions. We are borrowing the idea of named corners, not turning a triangle list into an edge list unchanged.

## 2. Which positions change?

`shape()` calls `Structure.corners(width, top_fraction, top_shift)`. Height stays at one metre. Width changes both horizontal coordinates, x and z; `top_fraction` changes the size of the upper square; `top_shift` moves that upper square sideways. These are our chosen dimensions, not measurements of the artwork.

| Form | Width | Upper fraction | Upper shift |
| --- | ---: | ---: | ---: |
| Cube | 1 | 1 | 0 |
| Square-based pyramid | 1 | 0 | 0 |
| Narrow box | 0.38 | 1 | 0 |
| Truncated pyramid | 1 | 0.52 | 0 |
| Sheared box | 1 | 1 | 0.32 |

Change the truncated pyramid's `0.52` to `0.8` in `shape()`, then run again. Before running, predict which corners will move. Does the base remain where it was? The bars keep the same thickness while the corners move.

Now change `0.8` to `0.0`. The four upper addresses meet at one position. The four top edges have no length and the renderer skips them: eight nonzero edges remain. We still store eight entries, but they describe only five distinct positions. An address in a list and a place in space are not the same thing.

This also marks a limit of the earlier transformation lesson. Scaling the whole cube cannot keep its base fixed while shrinking only its top. Moving the upper corners sideways is a shear here, not a rotation of the whole object.

Restore `0.52`. **Stop here** if positions and connections are still new. You already have five forms made from one method.

## 3. Where does the decision happen?

Choose **Twenty-five places**. `row` and `column` run from 0 to 4. They locate each form; they can also decide which form appears there.

```gdscript
func form_at(column: int, row: int) -> int:
    if alternative:
        return column
    return (column + row) % 5
```

This is the live function in `rules.gd`, with spaces shown for readability. `% 5` keeps the remainder after division by five. It turns 0, 1, 2, 3, 4, 5 into 0, 1, 2, 3, 4, 0. Each number selects a form from our five-form vocabulary.

At address (0, 1), the cyclic rule chooses form 1: the pyramid. Click **Change array rule**. The same address now chooses form 0: the cube. The supports and spacing have not moved. One rule changed the arrangement of all twenty-five objects.

This is a transfer from the existing Chessboard lesson: `colour_of(x, z)` answered a colour at an address; `form_at(column, row)` answers a form. The array is not only repeated placement. It offers a place to make a decision.

For your own variation, replace the last line with `return (column + 2 * row) % 5`. Predict the first two rows on paper. Run it, orbit, and compare. This is your score; it is not an assertion about LeWitt's original score. Restore the original line before replaying the supplied checks, which test the original specification.

## 4. What does an address permit to exist?

Choose **Stacked modules**. Here the unit stays a cube. Two questions change:

- `occupied(x, z)` says whether a column belongs to the footprint.
- `height_at(x, z, version)` says how many units that column contains.

The five height rules are `x + 1`, `5 - x`, `z + 1`, `5 - z`, and `5`. Indices go from 0 to 4, so heights stay between one and five. The first four climb in different directions; the fifth gives every occupied column the same height. Inside each column, another loop supplies y positions from zero to one below its height.

Click **Change array rule**. The footprint changes from a cross to a filled 5×5 square. The height functions stay the same. Compare the amount you can see through the structures. Shared bars between neighboring cells are drawn once by the supplied renderer.

Make a different footprint by editing `occupied()` to return `x == z`. You have exchanged the cross for a diagonal. Keep the five height rules. What survives of the family resemblance? Record the edit and one view where its consequence is clear.

## 5. What have the five names left out?

Choose **Between the forms**. This view holds the base, height and thickness fixed and samples seven upper fractions from zero to one. Between the pyramid and cube stand forms that were not given their own place in the first row.

We could sample more positions, tilt only one corner, omit a connection or widen the spacing until the separate frames become passages. Each proposal changes a different part of the description. Choose one; do not change all of them at once.

The study currently draws objects. Turning them into architecture would require another decision: which bars resist a body, what size the openings need to be, and where a person can pass. The photograph, the visible mesh and the collision boundary are three different kinds of evidence.

## A small record

Keep the supplied image, the rule you inferred, your first reconstruction and one deliberate variation together. Write three sentences: what stayed fixed, what changed, and what looking from another side made you revise. A successful resemblance does not prove you found the original rule. A useful rule lets you make and explain a new consequence.
