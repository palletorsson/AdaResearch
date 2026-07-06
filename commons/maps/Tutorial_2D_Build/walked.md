# Tutorial_2D_Build — walked

> R-021/R-028: considered critical tutorial, ghost-drafted from the working map;
> Palle rules the voice. The walk (tutorial) woven with the turn (critical).

## The cast

4×4 grid · row helper · column helper · grid agent · xyz_coordinates

## The walk

One index found a slot; here two indices find a **point**. The row and column helpers first break the axes apart — this many across, this many down — and then the 4×4 grid locks them back together so a coordinate pair becomes something you can pick up and read. A grid agent copies itself and wanders the same cells you walk, and the map lets you feel the difference between the static grid and the living traversal that inhabits it. Sixteen positions, each named by exactly two numbers: `grid[y][x]`. You stop knowing merely *where* and start knowing *where in relation to what*.

## The turn (critical)

The jump from row to grid is the chapter's first genuinely **multiplicative** moment, and the map is right to treat it as a leap rather than an addition: a second dimension does not add four cells to four, it multiplies them into sixteen — sequence becomes *territory*. This is the exact hinge where arrays stop being lists and become spatial data structures, where a data structure becomes a **map of itself**. And the grid agent smuggles in the chapter's forward-looking claim: the moment there is a field of addresses, there can be something that *navigates* it programmatically — the first algorithm that treats space as data. Point Line Grid, one chapter back in primitives, made you feel the grid's discipline on the body; here the grid becomes the thing a body (or an agent) reasons *with*. The quantized floor grows a second axis and, with it, the possibility of a route.

## Room for improvement

*(Palle: "8 becomes 16, not 8+8" is the key insight. Note whether the grid agent
reads as the birth of navigation or as an extra prop.)*
