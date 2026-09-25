# The boundary takes a detour

<!-- @fractal_koch_curve -->

Four metres of line wait behind the desk. Keep its ends in view. Where could more line go?

Press NEXT. The middle lifts into a peak. Follow it up and down before reading the counter. The ends have not moved apart, but travelling between them along the line now takes longer. Press again. Each of the four new segments takes its own detour, including the ones already climbing.

At the fourth step, 256 segments share a path a little over twelve and a half metres long. The endpoints still stand four metres apart. Distance between them and distance along the boundary have begun telling different stories.

This is the small decision inside each replacement:

```gdscript
var b := start + dir * (len / 3.0)
var d := start + dir * (2.0 * len / 3.0)
var c := mid_point + perpendicular * height
```

The next list joins `start → b → c → d → end`. Four segments, each a third of the old length. The next call receives these segments as its beginning. A multiplication of four thirds can be followed with the eye.

Try TURN. The detours go to the other side. The count and path length survive the reversal. They have not told us everything about the shape.

RESET, then FORM. A triangle closes the starting line into a boundary. NEXT sends its peaks outward; TURN folds them inward. There is an inside to negotiate now. An instruction about direction has become a decision about where an enclosure extends.

Our machine stops at four replacements. The familiar Koch limit follows the standard construction indefinitely; its boundary has unbounded length while enclosing a bounded area. This desk has finite segments drawn with thickness. We can learn the rule that approaches the limit without pretending the headset contains it. From Trace we still carry a question: how much of the next detail could this encounter distinguish?

<!-- @sierpinski_triangle -->

A filled triangle waits across the aisle. We have spent several rooms making descendants. What if the next generation occupied less of its parent?

Press NEXT. Find the middle before looking at the three corners. The middle is now an opening in the drawing. Another press makes a new opening inside each retained corner. The large absence remains; the small ones accumulate around it.

The code locates three midpoints:

```gdscript
var m1 = (v1 + v2) / 2.0
var m2 = (v2 + v3) / 2.0
var m3 = (v3 + v1) / 2.0
```

The next calls receive the three corner triangles. Their sides are half as long, so each has a quarter of its parent's area. Three quarters remain. At four cuts, eighty-one kept triangles occupy about 4.93 square metres of the original 15.59. There are more pieces to address and less surface to colour.

Now press VIEW. Pale middles appear where the rule made its removals. Press again. The kept corners disappear from the drawing, and the middles stand in their colours. What we had called the waste now holds the room's attention.

The program still computes the same corner triangles. It has changed which results receive meshes. The negative view draws forty removed middles from the four cuts. These are parts the operation already located; we did not need a new fractal to find another subject inside it.

DEPTH gives the drawn pieces more thickness. Their planar area does not change. Neither view makes these pieces load-bearing: the sculpture has no collision, although its control desk does. An opening in an image, a hole in a solid and a passage for our body ask different things of the implementation.

We can change the view back. That matters here. The ease with which this display restores a discarded part belongs to this stored construction. It does not make every act of removal reversible.

<!-- @box_counting_dimension -->

The next triangle arrives as points. This bench has its own generator: eight thousand repeated moves halfway towards a chosen corner. It is related to the triangle we just cut, but it is not reading that sculpture's mesh.

Press FINER. The grid tightens over the same points. Try COVER. Coloured cells mark where at least one sample was found. A crowded cell and a cell holding one point each count once. An empty cell contributes nothing, even when the ideal construction might place detail there.

Here is the counting decision:

```gdscript
var ix := int(shifted.x / box_size)
var iz := int(shifted.z / box_size)
occupied[ix * 10000 + iz] = true
```

The key gives this cell an address. Writing it again does not create another occupied cell. Arrays and grids have returned as a measuring instrument.

RANGE reveals a plot and fits the three coarsest measurements. Press it again for the three finest, then for all six. The reported slope moves while the point cloud stays put. Which value would you have called the triangle's dimension if only one had been shown?

The ideal Sierpinski triangle has dimension `log(3) / log(2)`, about 1.585. This instrument fits a finite sample at six box sizes. The number it returns depends on those choices; it is evidence from a procedure, with a range beyond which we have not tested it. RESET reproduces the same sample so the comparison can begin again.

The unoccupied cells tell us where this reading found no points. They have no authority over what may exist. The question becomes sharper when a model is used to decide what the world should retain: what happens to what it did not count? Here we can start with the smaller act: change the grid, look again, and leave room for an answer the first reading could not hold.

<!-- @sierpinski_pyramid -->

The cube pyramid returns from the cellular automata rooms. There we put its resemblance beside another way of making a pattern. Here, walk around it. Keep one of its rising edges in view, then press COMPARE.

Something has been held back. The top comes down. Did the cubes shrink? Come closer: the cubes have kept their size. Press again and the taller construction returns. Follow an edge that survived both versions. Where did its neighbours go?

An earlier comment in the source promised five recursive calls. The program made six. We have kept that inherited construction as the first view. COMPARE holds back the extra upper call wherever the recipe repeats. The remaining calls keep their positions and the same three levels of recursion.

RULE reveals the count after we have looked: 216 cube instances become 125. One call withheld, ninety-one instances gone. That call had descendants of its own. Some cubes overlap, so counting what the program creates is not the same as counting separate blocks we can see.

The discrepancy could have disappeared in a correction. Instead it has become a way to touch the recipe. The name invited us to recognise a form; the switch lets that recognition falter. Which version would you have accepted if the other had never been offered? RESET brings back the inherited one. We can keep the strange result and still learn how it was made.

<!-- @ -->

Around these instruments, the earlier collection remains: assembled cubes, a bent Koch arch, recursive specimens and the dark sphere on the old raised cell. There is more to inspect than the route can finish.

In the next hall, removal enters a volume. We will approach the Menger sponge with a body that can fly. Which of its openings will become somewhere we can go?
