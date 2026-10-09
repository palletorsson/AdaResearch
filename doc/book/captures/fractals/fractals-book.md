# fractals: the chapters

## Fractal Recursion

*Fractal_Recursion*

### How many times can *again* happen?


A square waits above the first desk. Press MORE. Another square appears inside it, half as wide. Ask again. The instruction is brief enough to hold in your head; the shrinking squares soon become harder to hold in your eyes.

Before opening RULE, try LAYOUT. The squares spread into a descending row. Nothing has been added. What looked like an interior can be arranged as a succession. COLLAPSE presses all the drawn squares down to the smallest term, leaving the outer frame where it was. The count does not fall with their visibility.

Here is the self-call from the artifact:[^Fractal_Recursion--noc]

```gdscript
var new_size: float = size * size_reduction
_draw_recursive_pattern(center, new_size, d - 1)
```

The function has just drawn a square. It now calls itself with a smaller size and one less level to spend. At the beginning of each call, this condition can return it to the caller:

```gdscript
if d <= 0 or size < TERM_MIN_SIZE:
    return
```

`TERM_MIN_SIZE` is one centimetre. This desk also caps the requested depth at seven. Those are different limits: a chosen number of calls and a chosen minimum size. Neither is the same as the smallest detail your eye can distinguish in the helmet.

Beside the desk, the same sizes stand on the floor as doorframes. Ask for more, then leave the buttons and approach them. The first square is 2.2 metres across. You can walk through it. The next is half that height; it meets a standing body before the body can pass. The next is half again. The instruction keeps making openings after it has stopped making a passage for you.

Walk alongside the smaller frames. They remain available to the eye after they have become unavailable to that upright walk. LAYOUT and COLLAPSE change the squares above the desk; the doorframes keep the original measurements. A rearranged image, a limit in the function, the reach of a body: each can stop us somewhere else.

![The same shrinking terms become doorframes on the museum floor.](images/recursion-thresholds.png)


Seven levels produce seven squares. One call makes one further call. Each square repeats the shape of the one around it at a smaller size. That resemblance gives us a way towards fractals, but it is not enough to define one. A straight line is also made of smaller lines; looking closer brings no new structure. In the exact fractal constructions ahead, smaller parts repeat the whole and fine structure continues however far we zoom.[^Fractal_Recursion--1] Here we reach a last square. The room has stopped where a rule could go on.

We could also write this particular descent as a loop. Seeing a square inside another square does not tell us which program made it. We had to look behind the image.


The other desk begins with one ring. Predict the count after MORE. Five. Once more: twenty-one. The footprint remains roughly the same while the number of things occupying it changes quickly.

Each call draws its ring, then makes four smaller calls, shifting their centres right, left, up and down. Four levels leave `1 + 4 + 16 + 64` rings: eighty-five. The fifth leaves three hundred and forty-one. “One more” has acquired a different cost.

Return to depth four and try PACKING. The child radius changes; the number of rings stays. Press PACKING until the readout says dust, then ask for depth five: the fifth ring’s requested radius, two metres times 0.25 four times over, is about eight millimetres, below the source’s one-centimetre cutoff, and a whole level is lost. A depth allowance does not guarantee that every call will draw. Some overlap, some meet, some separate. TURN releases their planes into the artifact's rotating motion. Stop it to return to the frontal comparison. An apparent tangle can come from placement and pose as well as from adding more things.

The room can accommodate three hundred and forty-one rings. That does not mean it has made three hundred and forty-one distinctions easy to read. We met this gap in the first sequence, at the trace hall, where a drawn line kept only the positions its spacing could tell apart: what is stored, what is drawn, and what a body can use do not share a resolution.


Now a cube waits on a plinth. Press SPLIT. Eight smaller cubes take its place. Press again. Fifteen, not sixty-four. This machine divides one selected cell at a time.

Choose DRILL and spend the twelve splits. Then choose SPREAD and spend the same allowance. Both end with eighty-five cells. DRILL follows one corner into smaller and smaller scales; SPREAD chooses a cell from the shallowest remaining level. The readout reaches depth twelve in one case and depth three in the other. Equal counts have bought different bodies.

LOTS draws from the remaining population. Its seed is fixed here. BEGIN lets you repeat the same choices and inspect something you missed. Repetition becomes a way of paying attention.

The source sets a child's scale like this:

```gdscript
var new_scale = cube_scale * 0.5 * 0.9
```

Half, then a little smaller. The gaps that make the division legible are authored too. And the tiny cell that DRILL keeps choosing still costs something even after its difference becomes difficult to see. More work need not yield more experience. Where would you spend the next split?


At the last desk, NEXT starts to make a chair. After the first cut, press GHOST. Eleven pale cells return around the sixteen that were kept. SCAR marks the discarded centres; GONE hides those witnesses again. The choice of what to keep has become visible beside its result.

Something else moved. The first stage lifts the divided lattice; subsequent stages flatten the seat, extend legs and back, then add armrests. The chair was not simply waiting inside the original cube. Parts are selected, translated, stretched and added according to an intention about chairs.

This artifact carries “recursive” in its name, but its construction runs through five authored stages. There is no self-call in that sequence. Its presence beside the squares is useful precisely because a familiar appearance can conceal a different procedure.


The table, staircase, pagoda and other works remain beyond the desks, a collection to return to with these distinctions in hand. We do not have to make every object evidence for the same claim.

A rule, a stopping condition, a choice of where to continue: we can now separate them. In the next hall the call branches. What does a tree inherit from the branch before it, and where can it differ?

[^Fractal_Recursion--1]: Benoît Mandelbrot coined *fractal* in 1975. The distinction here between self-similarity and fine structure follows Daniel Shiffman's introductory discussion in [“What Is a Fractal?”, *The Nature of Code*](https://natureofcode.com/fractals/#what-is-a-fractal). It is a way into the examples, not a complete mathematical definition.

[^Fractal_Recursion--noc]: The square and ring source files credit Daniel Shiffman's *The Nature of Code*, Examples 8.2 and 8.3, adapted from Processing into GDScript for VR. The compact desks and their LAYOUT, COLLAPSE and PACKING comparisons are additions in this project. The example numbers follow the source-file headers.

---

## Fractal RecursiveTrees

*Fractal_RecursiveTrees*

### Where will the next branch go?


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

RESET returns to the trunk and the original settings. This specimen uses no random variation. Repeat the same choices and the same branches return. Now press GROW once more and watch where the new branches appear. Every unfinished tip advances in the same press. The desk holds those tips in a queue and works through one generation at a time.

We could instead follow one branch all the way to its last twig before returning for its siblings. A self-call can take that route. With the same fixed angles and lengths, the completed tree could look the same; watching it being made would be a different encounter. Here the next generation waits for your hand. The surrounding museum continues.

There is no light to seek, no root taking water, no neighbour whose shade changes the next fork. The branches are visible meshes; they do not offer the player's body a climbable support. Their outline invites a promise that their implementation has not made. What would we have to add for one of these forks to become shelter?


Across the approach, the red block tree has already spent its calls. Choose a large branch and follow it towards its smaller descendants. At a fork, predict the next division, then find another fork at a similar depth. A shared procedure need not give them the same dimensions or the same number of children.

Press STRATA. Colour separates three branching levels from the trunk. Follow a route to its last visible block. REACH draws the accumulated bounds; ENDS adds marks at the handover and terminal branches. FORM returns the original colours. These readings belong to the same built geometry. Changing the view does not draw another tree.

This tree does use random choices, from the seed shown on its desk. The choices vary its branches within a fixed construction rule. A seed can repeat an arrangement; it cannot tell us which arrangements the rule never permits. Even the blunt boxes can persuade us to call it organic. We can enjoy that recognition and still ask what it has made too easy to recognise.


The small tree further in begins with a sentence. A short string is rewritten four times, then read as steps and turns. Its angle control changes how those turns are drawn. The letters can stay while the branches move.

Look back at the two trees near the entrance: the growing tree keeps its proportions; the red tree repeats a seeded draw. Beside them, the little grammar tree gives instructions letters we will learn to read in a later hall. Which one most readily becomes a tree in your eyes? That recognition arrives before any of them has met soil, light or wind.

Further in, the downward trees, the mesh fractal, the desk and the small subdivision cubes keep other possibilities in view. They need not all answer the same question. The old enclosure remains a detour around something we cannot see from every position. We have more procedures to learn before resemblance becomes our only way to choose a body.

Next comes Cantor: another generation, this time made by deciding what will be removed.

---

## Fractal CantorSet

*Fractal_CantorSet*

### More pieces, less material


One bar is waiting. Where could it go if we let it become two?

Press NEXT. The new pair appears beneath it. Their outside ends reach as far as the first bar, but the middle is missing. Press again. Look for the new gaps before counting the pieces. Each piece has lost its own middle; the first large gap has not been divided or repaired.

The trees sent another branch into space. Here another generation leaves less behind. At the fifth cut, thirty-two pieces share less than a metre of the six metres we began with. The desk counts the latest row. Above it, the old bars are still present. The whole display has become busier while the thing it is recording has become smaller in total length.

Turn HISTORY off. There is much less to look at. The kept length does not change. The earlier rows were a record we added so we could follow the operation. They were never extra members of the latest generation.

GHOST brings back pale marks where this generation cut its middles. They have no collision. The display can remember an absence without filling it with something that supports a body. Turn HISTORY on again and follow the larger absences upwards to the rows where they first appeared.

These two lines make the next pair in the bar's code:

```gdscript
var new_length = bar_length / 3.0
var offset = bar_length / 3.0
```

The new bars are placed at the old centre minus that offset and the old centre plus it. Their width is `new_length`. Two thirds remain, separated by the third for which we create no solid bar. Repeating the operation gives us:

```text
pieces      = 2^n
piece length = 6 / 3^n
kept length  = 6 * (2/3)^n
```

The count rises as the retained length falls. Neither number tells us how much work the renderer is doing. With history visible, it draws every earlier row as well. At five cuts that means sixty-three solid bars, before we count the ghosts, the desk or the rest of the room.

The screen stops at five. Its smallest pieces still have width, height and depth. The mathematical construction asks us to continue without a last cut.[^Fractal_CantorSet--1] Its limiting set has zero total length and uncountably many points. We have not displayed that limit. We have made a finite instrument for approaching its rule.

From here the gaps can look generous. Carry that impression up the ramp.


There is a broad opening under the pink beam. Walk through it. The same removal that interrupted a bar now offers a passage.

Return to the desk and press CUT twice. Smaller openings appear beside the first one. Choose one that looks wide enough, go up the ramp and try it. At this setting the gaps include three metres, one metre and a third of a metre. All are gaps. They do not all admit the same body.

The rule supplied intervals. The pagoda gave them height and depth, stacked their history above them, and made their surfaces collide with us. Here is the box shape used by its collision code:

```gdscript
shape.size = Vector3(width, block_height, block_thickness)
```

The interval's width is only one of those three decisions. Press DEPTH: the passage becomes longer or shorter while its opening stays the same width. LATEST removes the earlier levels overhead. The ground-level intervals remain; the roof was our way of arranging their past.

Try the narrow gap once more. The simulation does not collide with every fold of your clothes. It tests a proxy body. A passage can exclude that body even when the eye can travel through it. The obstruction belongs to a relation between the gap and the body we have implemented. To make a way through, we could widen the opening, change the body, or change which surfaces count as solid. Each choice makes a different world.

More cuts have made more openings, but many are too small for this visitor. Nothing in the operation promises that more detail will make more room for us. And still we want to look inside. That desire can lead us back to the rule, to ask which of its decisions might move.


At the far end of the hall, three trees stand in a row. They are one rule, three times. Each is grown by a call that makes its children and then calls itself on each of them, the self-call of the first hall, with every fork's angle and length drawn by chance; near the trunk each fork makes three, further out two. Once grown, the branches push apart level by level until they have found room. No seed is kept. The hall builds three different trees each time it is built, and none of them can be asked for again. Every desk in this sequence returns the same object when you press RESET; these trees never do, and “the same tree” stops meaning anything you could check.

The smaller Cantor drawing, the cloud and the dark sphere remain around the experiment as well. Their kinds of repetition do not have to resolve into one shape. Further on, Koch will put a detour into a line; Sierpinski will carry removal into a triangle. We have learned to lose length while multiplying pieces. What happens when the next rule makes the boundary grow instead?

[^Fractal_CantorSet--1]: Georg Cantor published the set in 1883, in the fifth of his papers “Über unendliche, lineare Punktmannichfaltigkeiten” (*Mathematische Annalen* 21); Henry J. S. Smith had described the same construction nine years earlier. The pagoda is built on Daniel Shiffman's Example 8.4 in *The Nature of Code*.

---

## Fractal KochSierpinski

*Fractal_KochSierpinski*

### The boundary takes a detour


Four metres of line wait behind the desk. Keep its ends in view. Where could more line go?

Press NEXT. The middle lifts into a peak. Follow it up and down before reading the counter. The ends have not moved apart, but travelling between them along the line now takes longer. Press again. Each of the four new segments takes its own detour, including the ones already climbing.

At the fourth step, 256 segments share a path a little over twelve and a half metres long. The endpoints still stand four metres apart. Distance between them and distance along the boundary have begun telling different stories.

This is the small decision inside each replacement:

```gdscript
var b := start + dir * (len / 3.0)
var d := start + dir * (2.0 * len / 3.0)
var c := mid_point + perpendicular * height
```

The next list joins `start → b → c → d → end`. Four segments, each a third of the old length. The next call receives these segments as its beginning. In the cellular automata halls every cell wrote its next state into a separate array before the arrays were swapped; this list is that swap, with segments for cells, and in the next sequence it will be a sentence. Each of the 256 pieces at the fourth step is a separate object in that list; nothing here has yet asked one of them to move. A multiplication of four thirds can be followed with the eye.

Try TURN. The detours go to the other side. The count and path length survive the reversal. They have not told us everything about the shape.

RESET, then FORM. A triangle closes the starting line into a boundary. NEXT sends its peaks outward; TURN folds them inward. There is an inside to negotiate now. An instruction about direction has become a decision about where an enclosure extends.

Our machine stops at four replacements. The familiar Koch limit follows the standard construction indefinitely; its boundary has unbounded length while enclosing a bounded area.[^Fractal_KochSierpinski--1] This desk has finite segments drawn with thickness. We can learn the rule that approaches the limit without pretending the headset contains it. From the trace hall in the first sequence we still carry a question: how much of the next detail could this encounter distinguish?


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


The next triangle arrives as points. This bench has its own generator: eight thousand repeated moves halfway towards a chosen corner. It is related to the triangle we just cut, but it is not reading that sculpture's mesh.

Press FINER. The grid tightens over the same points. Try COVER. Coloured cells mark where at least one sample was found. A crowded cell and a cell holding one point each count once. An empty cell contributes nothing, even when the ideal construction might place detail there.

Here is the counting decision:

```gdscript
var ix := int(shifted.x / box_size)
var iz := int(shifted.z / box_size)
var key := ix * 10000 + iz
occupied[key] = true
```

The key gives this cell an address. Writing it again does not create another occupied cell. Arrays and grids have returned as a measuring instrument.

RANGE reveals a plot and fits the three coarsest measurements. Press it again for the three finest, then for all six. The reported slope moves while the point cloud stays put. Which value would you have called the triangle's dimension if only one had been shown?

The ideal Sierpinski triangle has dimension `log(3) / log(2)`, about 1.585.[^Fractal_KochSierpinski--2] This instrument fits a finite sample at six box sizes. The number it returns depends on those choices; it is evidence from a procedure, with a range beyond which we have not tested it. RESET reproduces the same sample so the comparison can begin again.

The unoccupied cells tell us where this reading found no points. They have no authority over what may exist. The question becomes sharper when a model is used to decide what the world should retain: what happens to what it did not count? Here we can start with the smaller act: change the grid, look again, and leave room for an answer the first reading could not hold.


The cube pyramid returns from the cellular automata rooms. There we put its resemblance beside another way of making a pattern. Here, walk around it. Keep one of its rising edges in view, then press COMPARE.

Something has been held back. The top comes down. Did the cubes shrink? Come closer: the cubes have kept their size. Press again and the taller construction returns. Follow an edge that survived both versions. Where did its neighbours go?

An earlier comment in the source promised five recursive calls. The program made six. We have kept that inherited construction as the first view. COMPARE holds back the extra upper call wherever the recipe repeats. The remaining calls keep their positions and the same three levels of recursion.

RULE reveals the count after we have looked: 216 cube instances become 125. One call withheld, ninety-one instances gone. That call had descendants of its own. Some cubes overlap, so counting what the program creates is not the same as counting separate blocks we can see.

The discrepancy could have disappeared in a correction. Instead it has become a way to touch the recipe. The name invited us to recognise a form; the switch lets that recognition falter. Which version would you have accepted if the other had never been offered? RESET brings back the inherited one. We can keep the strange result and still learn how it was made.


Around these instruments, the earlier collection remains: assembled cubes, a bent Koch arch, recursive specimens and the dark sphere on the old raised cell. There is more to inspect than the route can finish.

In the next hall, removal enters a volume. We will approach the Menger sponge with a body that can fly. Which of its openings will become somewhere we can go?

[^Fractal_KochSierpinski--1]: Helge von Koch, “Sur une courbe continue sans tangente, obtenue par une construction géométrique élémentaire”, *Arkiv för matematik, astronomi och fysik* 1 (1904). The replacement on this desk is carried from Daniel Shiffman's Example 8.5 in *The Nature of Code*.

[^Fractal_KochSierpinski--2]: Wacław Sierpiński, “Sur une courbe dont tout point est un point de ramification”, *Comptes rendus de l'Académie des sciences* 160 (1915).

---

## Fractal MengerSponge

*Fractal_MengerSponge*

### A hole becomes a place


The cube has no entrance. Nine metres high, nine across, nine deep. Its surface faces us without offering a way in.

At the desk to the right, press NEXT. Find the opening before counting the blocks. A square of the far side has become visible. Move a little: something opens across it, sideways. The removal did more than shorten the route between two faces. It made a crossing inside the cube.

Press NEXT again. Keep the large opening as a reference and look at the blocks around it. Each now carries smaller openings in the same relation. FRAME marks the outside of the original cube. The construction still reaches those edges, although more of its interior has become air.

The display counts the solids: one, twenty, four hundred. Beside the count, retained volume falls from 729 to 540 to 400 cubic metres. More objects have been made to represent less material. We met that difference in Cantor's rows. Now its gaps have acquired depth.

The source addresses twenty-seven positions, three along each axis:

```gdscript
var x: int = i % 3
var y: int = (i / 3) % 3
var z: int = i / 9
```

Each coordinate runs from zero to two. The retained-position table skips the centre and the six face centres: seven cells making a cross through the parent. Twenty remain. The next call receives each of those twenty cubes, with its scale divided by three. The same selection can now make an opening inside something that was previously kept.

Try GHOST. Pale volumes occupy the removals. After two cuts, seven large ghosts mark the first cross and 140 smaller ones mark the next. These marks have no collision. They are a record of what the construction discarded, drawn in the places our bodies might use.

In the previous hall, the removed middles could become the work. Here the removed volumes may become somewhere to be. Turn GHOST off again and approach the frame at floor level.

The glass cube offers another way of moving. Tilt the left controller towards where you want to go and push its stick; let go and you hover. Flight belongs to this enclosure. Descend to either ground doorway when you want to walk again.

Rise towards the large opening. What looked like a dark square becomes a passage, with smaller openings in its sides. Try going through, then circle above the sponge and approach from another face. Choose one small retained cube and try identifying it in both views. The openings rearrange in projection even though their positions in the object remain fixed.

Look into a smaller copy of the passage. Its axial opening is a metre across and a metre high. Light can travel through where a standing body cannot. The body the sponge collides with is a capsule forty centimetres wide whose height follows your head. Flying does not shrink it, and it does not make a retained cube permeable; whether a crouch admits you to a one-metre opening is something to try, not to assume.

There was a connection in the geometry. There was not yet a route for every body.

We changed locomotion without changing the sponge's selection rule. We could also ask what a smaller body would encounter, or what would happen if the opening were enlarged. These would be further experiments. The present room gives us one specific comparison: a large passage we can fly through and a smaller, visibly connected opening that a standing capsule cannot enter.

The glass, the support below us and the borrowed flight belong to the installation. The glass confines that movement to a place where its beginning and ending can be found. At the desk, NEXT, BACK and RESET wait while a visitor remains inside; another press is needed after everyone leaves. GHOST and FRAME can still change the reading. We can discuss a different solid shape without rebuilding it around someone already inhabiting the last one.

Two cuts are enough for this encounter. A third would ask for eight thousand retained cubes with edges a third of a metre long. It would bring further openings, each smaller again. That is a cost and a possibility to investigate, not evidence that the next generation would be a better room. The infinite Menger construction[^Fractal_MengerSponge--1] has a zero-volume limit; these four hundred one-metre cubes retain positive volume and real collision. The limit is not what our body is touching.

The neighbouring aggregation study remains another way for form to begin: wandering particles can attach to an existing cluster. It has its own clock and rules. The catalyst installations and the dark sphere remain too. They offer detours from the cut-and-repeat procedure; this desk does not control them.

Next, repetition takes a numerical form. Instead of retaining twenty descendants, we will generate each new quantity from the preceding two and inspect how its representation changes what we can compare.

[^Fractal_MengerSponge--1]: Karl Menger described the sponge in 1926 (“Allgemeine Räume und Cartesische Räume”, *Proceedings of the Amsterdam Academy* 29) as a universal curve: every curve, however tangled, fits inside it.

---

## Fractal GoldenSpiral

*Fractal_GoldenSpiral*

### A number needs a mapping


Two towers wait at the beginning of the row. Each carries a one. Before asking the machine for another, give it a number yourself. What could follow two equal beginnings?

Press NEXT. Two appears. Another press brings three. Stay with the numbers for a few steps: one, one, two, three, five. The next tower is already implied by a relation you can test.[^Fractal_GoldenSpiral--1] Add the preceding pair, then ask the machine to make its next term.

The row grows, but its heights are suspicious. Eight has not become a tower eight times as high as one. Fifty-five, at the end of this ten-term display, still fits comfortably below the wall. Something has happened between the number and the body that stands for it.

Press HEIGHT. The small towers sink towards the floor. Later ones keep more of their height. Read the labels again: none of the numbers has changed.

With the linear mapping, each unit receives five centimetres. A one is now easy to overlook from a distance. The earlier logarithmic mapping gave it half a metre, then compressed the increasing values. One arrangement keeps the small beginnings present. The other lets height carry addition at a common scale. They offer different ways to read the same history.

Try SUM after revealing at least three terms. Beside the row, two colours share a stack. One colour supplies the earlier value, the other the later one. A separate stack carries their sum. At the last term, twenty-one units and thirty-four units reach the same height as fifty-five. Each unit is still five centimetres. The equality can be checked by looking across their tops.

Now return to logarithmic heights. The unit stacks remain equal, but adding the corresponding tower heights would not reconstruct the next tower. The display has not broken the recurrence. It has changed what height means.

Ask for RULE. The source receives two quantities:

```gdscript
var next_fib = fibonacci_numbers[i-1] + fibonacci_numbers[i-2]
fibonacci_numbers.append(next_fib)
```

The display receives a value and gives it a height:

```gdscript
var h: float=0.05*n if linear else 0.5*log(float(n))+0.5
```

HEIGHT flips `linear`; the recurrence above never sees it. There are two decisions here. We can change the representation without changing the relation it represents. We can also lose sight of a small value without removing it from the sequence. The label and the alternative view let us find that difference again.

Walk around the desk and continue beside the supported displays. The earlier examples remain: seed points, stacked scales, shell-like chambers, a helix and a branching diagram. They are held still here so their arrangements can be inspected. Read one of their small plates. The seed pattern uses an index to choose a radius and an angle. The branching diagram uses a remainder after division to choose how many children to make. These are further rules.

The helix is especially useful to look at twice. Its radius grows by phi over a full turn. A curve usually called a golden spiral grows by phi over a quarter turn. A familiar colour and a persuasive title would not make those constructions identical. The plate names what this source actually draws.

![Plan view of the hall's helix, a golden spiral from the same start, and the rectangle's chain of quarter circles](/book-review/doc/book/figures/fractals/helix-against-golden-spiral.png)

*Left: one full turn from the same start. The hall’s helix grows by phi over the whole turn; a golden spiral grows by phi over each quarter. Right: the rectangle’s arcs, quarter circles of fixed radius, one per square. The hall draws the first and the third; the second exists nowhere in the room.*

The pleasure of recognition can come before the inspection. A shell! A seed head! We can enjoy that resemblance and still ask which operations supplied it. The two ones did not contain instructions to make a flower. We added a way for numbers to take positions, turns and sizes.


A rectangle stands upright farther into the hall. This time there are no towers and no curve. Imagine removing a square whose side is the shorter edge. What shape would be left?

Press NEXT. The square remains visible in one colour; the remainder occupies the other portion. Press again. The next square is smaller and turns the direction of the construction. Follow a few cuts before asking for their measurements.

MEASURE puts side lengths on the squares. They decrease as the cut numbers increase. The first is about 3.090 metres across, the next 1.910, then 1.180. Those are lengths from this five-metre rectangle. They are not the increasing Fibonacci values painted onto another surface.

The readout follows the remainder. Its longer side divided by its shorter side stays close to 1.618034. We have changed the dimensions, yet retained a relation between them. Rotate your attention with each cut: the longer edge becomes the shorter one of the next stage.

For a rectangle of width phi and height one, removing a unit square leaves sides one and phi minus one. To keep the original proportion after turning the remainder, we require:

```text
phi = 1 / (phi - 1)
phi² = phi + 1
```

The positive solution supplies the ratio used here. The code still needs to decide which side loses its square, how many cuts to make, how to colour them and how to bring the result into this upright display. The proportion leaves those choices open.

Try ARC. A line joins circular segments laid through the squares. Turn it off again. The partition remains. Making the curve visible did not cause the subdivisions.

Each segment is a quarter-circle. The resulting joined curve resembles a logarithmic spiral, but its curvature changes from one circular piece to the next. We can follow it and feel its invitation inward without making it evidence of a universal rule of beauty. Another cut makes a smaller square, another length, another demand on the eye. Eventually the record can name a difference the view barely resolves.

The sponge made room by discarding material. This rectangle keeps the pieces together and gives the remainder another turn. The towers changed what a quantity looked like. Each procedure carries something forward and makes other differences harder to encounter. Asking what bodies are possible now includes asking what kind of reading our chosen representation permits.

In the retained room beyond, the recursive cabinet, growing terrain, Romanesco, aggregation study and sphere remain. The Romanesco's cones inherit positions and turns from their parent cones. Its botanical appearance is a construction to inspect, not proof that a plant follows this code. The terrain and aggregation have their own updates. Let their differences interrupt the temptation to call everything here the same pattern.

Next we gather the procedures. Before naming a desired shape, try saying what one step would receive, retain, change and pass on. After the synthesis hall, a grammar laboratory will give those instructions letters and a reader.

[^Fractal_GoldenSpiral--1]: The numbers are Leonardo of Pisa's, from the rabbit problem in *Liber abaci* (1202), and older than his name for them: Virahanka and Hemachandra had counted the same series for Sanskrit metres centuries before. The ratio the towers approach is Euclid's “extreme and mean ratio”; “golden” is a nineteenth-century word for it.

---

## Fractal Synthesis

*Fractal_Synthesis*

### What, exactly, is repeated?


Can you explain two recursive constructions without using their names?

Start at the interval. Before NEXT, describe one step to another person, or say it quietly to yourself: take an interval, keep two shorter intervals at its ends, and repeat on each survivor. Point to an example of the input, the descendants and the gap. Then identify where the displayed construction stops.

Try the description without pointing. “Shorter” leaves something undecided. How short? At which ends? This desk begins with six metres and keeps thirds. After one cut there are two pieces, each two metres long. Before the second cut, predict both the number of pieces and their combined length. They will not change in the same direction.

Here is the step that actually creates a descendant's size:

```gdscript
var new_length = bar_length / 3.0
```

In `cantor_set.gd`, `perform_iteration()` creates a left bar and a right bar of that length, each centred a third of the parent's length away from its centre. The middle receives no surviving bar. The call preserves the position needed to place its descendants; “repeat” alone would not tell us where they belong.

After three cuts, press HISTORY. The upper rows disappear. Has another third been removed?

The lowest eight pieces stay where they were. Together they retain about 1.778 metres. What disappeared was the visible record of earlier stages. Bring it back, then try GHOST. Pale middles mark the new removals at each row. These markers have no collision bodies and do not re-enter the surviving population. We can change what the drawing lets us examine without undoing the selection rule.

This difference matters to our question about possible bodies. A drawing can omit a history while retaining the state that history produced. It can also make an absence visible without making that place available to stand on. Neither visibility nor omission tells us everything about what the program permits.

The fifth cut is the desk's last. It leaves thirty-two finite pieces. The stopping point gives our attention and this instrument somewhere to stand. It does not establish that further difference is impossible. RESET returns to the uncut beginning; it does not rewind the museum.


The red block tree has already branched. Find a fork that seems to end, and follow it backward. What would a call have to remember to place a smaller branch there?

Press STRATA. The blocks change colour according to their recorded branch levels. Press REACH and volumes enclose the extents accumulated through those levels. ENDS marks the joint where the trunk hands off and every deepest recorded block. FORM brings the solid reading back. Compare the same fork through these views: none of these buttons grows a new tree.

The source receives a parent, an origin, a number of branches and two depth values. Its stopping condition is small enough to read in one breath:

```gdscript
if current_depth >= max_depth:
    return
```

Later in `recursive_tree.gd`, `generate_branches()` passes the continuation on:

```gdscript
generate_branches(branch, end_point, num_sub, current_depth + 1, max_depth)
```

The surrounding code chooses dimensions, directions and descendant counts with a local random-number generator. This placement starts from seed 12345. The nested calls stop after three branching levels. A seed is one part of that recipe; the generator, draw order and ranges also matter. The desk's changing colours and cages read the resulting geometry without drawing those random choices again.

Try the incomplete description “make several smaller things.” It could describe both desks and reconstruct neither. The intervals need a retained fraction and placement rule. The tree needs inherited origins, directions, dimensions and descendants. A cage around its reach adds another representation: it encloses empty space as well as blocks. It is not a new shelter with solid walls.

We have accumulated ways to make form, and ways to mistake a reading for the form. The queer possibility here is a question we can keep material: which instruction would have to change for another body to have room? Another colour might help us notice a branch. Another branching rule might alter where the branches can go. Those are different interventions, with different consequences.


The collection beyond offers further procedures to compare. Its held examples leave time for looking; the moving works keep their own clocks. We do not need to turn every resemblance into the same law.

The trees around this hall were grown by a rule too, and it is not any of the desks’. The biome’s own generator writes a sentence with an L-system and reads it with a turtle in three dimensions; how many generations, how many branches at a fork, the angle and the taper come from that plant’s own genes, so no two are the same tree. The flag in the stage file that calls this flora fractal is a name nothing reads. What the ring inherits that the desks do not show is a body per plant: a different sentence for each, and a reader that gives it tubes and leaves. That grammar is where the next sequence begins.

The names on these desks arrived late in another sense. Cantor's set is dated 1883, Koch's curve 1904, Sierpinski's triangle 1915, Menger's sponge 1926, and the word that gathers them, *fractal*, 1975. The structure is older than any of them. The Ba-ila settlements of what is now Zambia were built as a ring of enclosures, each enclosure itself a ring, with the chief's ring at the back of the village repeating the whole at a smaller scale, long before a mathematician called the arrangement self-similar,[^Fractal_Synthesis--1] and the geometric ornament of Islamic architecture repeats a motif inside itself at descending scales for reasons of its own. A rule can be practised for centuries before it is written down. These desks show the written form. They do not show who was already building it.

Carry one explicit rule into the grammar laboratory. There, a string is rewritten before it is read as movement, and the interval you cut five times in the Cantor hall is two letters and two rules: `F` draws a step, `f` walks one without drawing, and every rewrite turns `F` into `FfF` and `f` into `fff`. Read the sentence after five rewrites and the bar's thirty-two pieces and their gaps are already in it, in order, before any turtle has moved; the lab keeps it as the preset called “Cantor”. Its preset called “Koch Curve” is a different Koch from our snowflake, one that replaces `F` with `F+F-F-F+F` and turns ninety degrees, so even a familiar name leaves work for us to do. What does an instruction become when another reader gives it a body?

[^Fractal_Synthesis--1]: Ron Eglash, *African Fractals: Modern Computing and Indigenous Design* (Rutgers University Press, 1999).

---
