What keeps you looking after you know the form?

<!-- @pyramid -->

Four pyramids mark the corners of a raised square. Before going closer, try to hold the arrangement in mind. Where would you put a fifth?

Walk around the court. One pyramid passes in front of another. A gap opens where two outlines seemed to meet. The objects have stayed still; your movement changes the picture. You have met this distinction before, but now the picture has become a place with room around it.

Take the side ramp onto the platform. The four corners repeat a form you can describe: a square base, four triangular sides, one apex. Five vertices, eight edges, five faces. Knowing those counts helps you recognise the family. It leaves you free to notice something else.

<!-- @pyramidlong -->

The fifth pyramid is taller and stands in the centre. Look back at a corner. Does the centre seem to organise the others, or have you made it important because it rises above them?

Its base is still square. Its apex is still a single point above it. The tall pyramid's source collects the base vertices and then adds that point:

```gdscript
vertices.append_array(ring)
vertices.append(_apex_position(ring))
```

The same connections can carry a different height. In this version the base is 0.8 metres wide and the apex rises 2.8 metres above it. The script triangulates the square base into two faces for rendering; together with the four sides, that makes six triangles. We can explain how it is built without settling what its height does to the arrangement.

<!-- @cube_scene -->

Four small cubes sit around the spire in a cross. Follow that cross with your eyes, then look toward the corner pyramids. A few familiar solids are becoming a court, a monument, perhaps a model of somewhere you would like to go. Which reading arrived first?

The arrangement returns to the room's earlier floor plan. Its reference belongs to an anonymous sixteenth-century manuscript of geometric and perspective studies: solids drawn, combined and staged until a study begins to suggest an unfamiliar architecture.[^solids] Here the forms stand on a platform made from the same cube vocabulary as the museum floor. The support is already part of the picture.

You can imagine another arrangement. You do not need to build every possibility before leaving this one.

<!-- @snap_pyramid_puzzle -->

Beside the front of the court, five snap points offer a small construction. Connect four into a base cycle and join each to the fifth. Watch what the puzzle accepts.

Its detector recognises those connections. It does not measure whether the base is square. Keep that distinction close: the program can complete its test while your question about the form remains open. The court was here before the test succeeded. Its place in the room has another history.

<!-- @ -->

## The tools are still here

<!-- @durer_scene -->

Follow the raised connection and the next ramp to the separate platform. The tableau gathers objects after Dürer's *Melencolia I*: a polyhedron, a sphere, a compass, a ladder, a numbered square. Find something you now know how to begin making. Then find something in the arrangement that this knowledge has not explained.

You have spent a chapter assembling a vocabulary. Here it returns as a scene. The compass belongs among the tools of geometry, but lying beside the other objects it also asks about work: begun, interrupted, waiting. These are possibilities for reading the tableau, not a solution hidden inside it.[^durer]

Go close to the numbered square. Choose a row and add it before reading further.

```text
16   3   2  13
 5  10  11   8
 9   6   7  12
 4  15  14   1
```

Try a column. Each row and column, and the two main diagonals, sums to 34. The 15 and 14 in the bottom row recall 1514, the year of the engraving. The numbers work.

Stay a little longer. Has that correct answer finished what you came to look at?

Perhaps the pleasure of the arrangement is enough for now. Perhaps its precision makes the interruption more palpable: these instruments can still measure, while the next action remains uncertain. We can read melancholy here without making geometry useless. We can also want the scene for the questions it keeps available.

## Enough to continue

The previous room left us approaching a curve with finite pieces. An exact mathematical description and a rendered body make different promises. More triangles can improve an approximation; they cannot decide what we should want to make with it.[^abstraction]

Dürer's engraving is itself a made thing. An accomplished image gives us an encounter with unfinished work. That matters here. Looking, arranging, imagining and taking pleasure in a form can keep an investigation moving while its purpose is unsettled. The aesthetic attention is already doing work.

There may be awe in that encounter: a few tools, and more possible constructions than we have time to pursue. We can approach the sublime as a question about the limits of grasping something as a whole, without calling the finite scene infinite.[^sublime]

Look back toward the five pyramids. They have become another picture from here. Choose one relation you would carry forward: the repeated corners, the tall centre, the distance between the platforms. In transformation, we will move, turn and scale the forms, and find out what those operations preserve.

We leave with enough to continue. There is still something here we have not finished looking at.

<!-- @ -->

[^solids]: Anonymous, sixteenth-century geometric and perspective manuscript, Herzog August Bibliothek, Cod. Guelf. 74.1 Aug. 2°. See [*Solid Objects*](https://publicdomainreview.org/collection/solid-objects/) and the [image selected for this room](https://pdimagearchive.org/images/4577a16c-d0e9-43d6-96fc-f125c47c6afe/). This court adapts an earlier AdaResearch arrangement; the manuscript is not attributed here to Dürer. Its additional compound solids remain references for later studies.

[^durer]: Albrecht Dürer, *Melencolia I* (1514), [Metropolitan Museum of Art](https://www.metmuseum.org/art/collection/search/360018). The museum describes several interpretations rather than a settled key. AdaResearch stages selected objects, not a complete or geometrically exact reconstruction of the engraving. Reading aesthetic attention as a way to continue is this book's proposal.

[^abstraction]: In [Plato's *Republic*, Book VI](https://classics.mit.edu/Plato/republic.7.vi.html), geometrical reasoning concerns the figures understood through a drawing rather than the particular marks alone. AdaResearch also asks what the made representation permits a body to do. The distinction can support invention as well as frustration. A non-terminating decimal expansion of π does not mean that π has infinite magnitude or that mathematics cannot specify a sphere.

[^sublime]: Kant's [*Critique of Judgement*](https://www.gutenberg.org/files/48433/48433-h/48433-h.htm), §§25–27, distinguishes continuing to apprehend parts from comprehending a whole; §49 describes aesthetic ideas as occasioning thought beyond what a determinate concept can exhaust. These are later lenses for this room, not claims about Dürer's intention. The book borrows the problem of sustained attention without requiring Kant's resolution of it.
