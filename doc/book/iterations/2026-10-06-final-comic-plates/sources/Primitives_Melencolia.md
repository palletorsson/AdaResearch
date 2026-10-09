# Melancholy of Finitude

What keeps you looking after you know the form?

<!-- @pyramid -->

Four pale blue pyramids mark the corners of a raised square. Before going closer, try to hold the arrangement in mind. Where would you put a fifth?

Walk around the court. One pyramid passes in front of another. A gap opens where two outlines seemed to meet. The objects have stayed still; your movement changes the picture. You have met this distinction before, but now the picture has become a place with room around it.

Take the side ramp onto the platform. The four corners repeat a form you can describe: a square base, four triangular sides, one apex. Five vertices, eight edges, five faces. Knowing those counts helps you recognise the family. It leaves you free to notice something else.

<!-- @pyramidlong -->

The fifth pyramid is pink, taller, and stands in the centre on a matching block. Look back at a corner. Does the centre seem to organise the others, or have you made it important because it rises above them?

Its base is still square. Its apex is still a single point above it. The tall pyramid's source collects the base vertices and then adds that point:

```gdscript
vertices.append_array(ring)
vertices.append(_apex_position(ring))
```

The same connections can carry a different height. In this version the pyramid's base is 0.8 metres wide and its apex rises 2.8 metres above that base. The pink block lifts the whole pyramid another 0.8 metres above the court. The script triangulates the square base into two faces for rendering; together with the four sides, that makes six triangles. We can explain how it is built without settling what its height does to the arrangement.

<!-- @cube_scene -->

Four ochre cubes sit around the spire in a cross. Follow that cross with your eyes, then look toward the corner pyramids. A few familiar solids are becoming a court, a monument, perhaps a model of somewhere you would like to go. Which reading arrived first?

The arrangement returns to the room's earlier floor plan. Its reference belongs to an anonymous sixteenth-century manuscript of geometric and perspective studies: solids drawn, combined and staged until a study begins to suggest an unfamiliar architecture.[^solids] Here the forms stand on a platform made from the same cube vocabulary as the museum floor. The support is already part of the picture.

Imagine one cube placed outside the cross. Its construction would be unchanged; its relation to the court would be different. You do not need to build every possibility before leaving this one.

![The museum court from three viewpoints: aligned, oblique and a plan from above.](/book-review/doc/book/figures/Primitives_Melencolia/melencolia-one-arrangement.png)

*The same court, from three viewpoints. At the left, two corner pyramids hide two others. None of the objects has moved.*

<!-- @snap_pyramid_puzzle -->

Beside the front of the court, five snap points offer a small construction. Connect four into a base cycle and join each to the fifth. Watch what the puzzle accepts.

Its detector recognises those connections. It does not measure whether the base is square. Keep that distinction close: the program can complete its test while your question about the form remains open. The court was here before the test succeeded. Its place in the room has another history.

<!-- @ -->

## The tools are still here

<!-- @durer_scene -->

Follow the raised connection to the next platform. The large stone stands to the left; the winged figure sits to the right, her head resting on a fist. A sphere lies near the sleeping dog. Above them, the ladder, scales, hourglass and bell give the wall its own order. Beneath them, a saw and a carpenter's plane lie among the small tools. Here the forms have company.[^durer]

The compass is in her hand. She has not lost the instrument. A book lies on her lap, and the skirt falls in heavy folds over her knees. Beside her, a smaller winged figure bends over a tablet. One is drawing. The other looks away.

Earlier, a sphere could introduce a primitive. Here it occupies ground beside a tired animal. Nothing has happened to the sphere's definition. Much has happened to what we can see in it.

We have carried something from the court of ideal forms into this clutter of work and waiting. We might call it *geometric desire*: the wish that a form might let us see further, or give us somewhere else to stand. Here that wish meets a body that cannot be reduced to its instruments. Knowing how to construct another solid does not tell her what to do next.

Perhaps we had hoped that getting the form right would put something else right with it. The compass can give a circle a radius. What should we make with the circle? That question stays with the hand holding the instrument.

Walk sideways. The stone hides the smaller figure, then lets it appear again. Our sculpture gives depth to an engraving; Dürer did not leave us the far side of this room. Those hidden surfaces are decisions we have made. The apparent completeness of the model rests on what the picture could not tell us.

![The reconstructed Melencolia tableau inside the museum.](/book-review/doc/book/figures/Primitives_Melencolia/melencolia-tableau.png)

*After Dürer's engraving: an arrangement of sculpted figures, tools and solids. Their placement follows the image; their depth is an interpretation. Walking changes which objects conceal one another.*

The stone has six pentagonal faces and two triangular ends. Its mesh begins with a rhombohedron and cuts off two opposite corners. The proportions are one possible reading of the printed form. We can make a closed solid without claiming to have recovered the only solid the image permits.

Now look up at the numbered square. Choose a row and add it before reading further.

```text
16   3   2  13
 5  10  11   8
 9   6   7  12
 4  15  14   1
```

Try a column. Each row and column, and the two main diagonals, sums to 34. The 15 and 14 in the bottom row recall 1514, the year of the engraving. The numbers work.

Stay a little longer. Has that correct answer finished what you came to look at?

## What do we want a form to promise?

We have learned to recognise a construction and change its rule. The reasons for choosing it have histories too.[^geometric-desire]

This desire will return with different demands. In the patterned surfaces of the Alhambra, geometry belongs to built space; Escher's study of its mosaics later fed his own investigations of repeating figures.[^pattern] A rule can continue beyond the piece of wall that holds it. Our museum also stops building at an edge while letting us imagine more.

Malevich's tilted square in *White on White* offers another possibility: a painted surface can suggest release into unbounded space. Hilma af Klint's *Paintings for the Temple* give abstract forms a different task, within a spiritual inquiry.[^abstraction] The same circle would not mean the same thing in each of these worlds. What someone asks of it matters.

And abstraction need not carry us away from the body. Lygia Clark's hinged metal *Bichos* ask for hands: a flat arrangement opens into a changing object.[^clark] To call this Brazilian work only escapist would miss that return to touch. Perhaps the escape is from having to remain a spectator. What can geometry make possible between a form and the person who meets it?

These histories meet here because we have placed them beside one another. Their different desires remain. Keep that question beside the seated figure. The tools are here. Their next use is not settled.

## The number that was already running

<!-- @frame_counter_display -->

By the way out, a number is changing. It is the same counter you met on your first step into this chapter: `Engine.get_process_frames()`, process frames since the engine started, read fresh on every call.

It is much larger now. Some of that is yours — the picking up, the drawing, the walking, the shifting of a start. A fixed quantity of it is not, and never will be. The frames that passed before you had somewhere to stand did not become yours by being counted alongside the ones that followed. This number adds them together anyway. It has no field for the difference.

In the first room we said that its first number for you was not its first number. That is still the one thing it will not tell you, and you now know several reasons why. A record keeps what its rule admits. Someone chose the rule. The number keeps growing while you read it.

## Enough to continue

Dürer's engraving is itself a made thing. An accomplished image gives us an encounter with unfinished work. That matters here. Looking, arranging, imagining and taking pleasure in a form can keep an investigation moving while its purpose is unsettled. The aesthetic attention is already doing work.

A few tools, and more possible constructions than we have time to pursue.[^sublime]

Look back toward the five pyramids. They have become another picture from here. The objects stayed still while your viewpoint changed. In transformation, you can watch from one place as objects move, turn and scale. Choose one relation from this court—the repeated corners, the tall centre, the distance between the platforms—and ask what would survive such a change.

We leave with enough to continue. There is still something here we have not finished looking at.

<!-- @ -->

[^solids]: Anonymous, sixteenth-century geometric and perspective manuscript, Herzog August Bibliothek, Cod. Guelf. 74.1 Aug. 2°. See [*Solid Objects*](https://publicdomainreview.org/collection/solid-objects/) and the [image selected for this room](https://pdimagearchive.org/images/4577a16c-d0e9-43d6-96fc-f125c47c6afe/). The court follows the drawing's blue corner spires, pink centre and ochre blocks within the earlier AdaResearch floor arrangement. Its dimensions are adapted for the museum. The manuscript is not attributed here to Dürer; its additional compound solids remain references for later studies.

[^durer]: Albrecht Dürer, *Melencolia I* (1514), [Metropolitan Museum of Art](https://www.metmuseum.org/art/collection/search/360018). The museum describes several interpretations rather than a settled key. The [National Gallery of Art](https://www.nga.gov/artworks/6641-melencolia-i) provides a detailed visual description. AdaResearch follows the principal objects and their image relationships in a stylised sculptural arrangement. Depth, rear surfaces, dimensions and the solid's proportions are authored interpretations. The passage from ideal form to embodied hesitation is this book's reading, not a settled account of Dürer's intention.

[^sublime]: Kant's [*Critique of Judgement*](https://www.gutenberg.org/files/48433/48433-h/48433-h.htm), §§25–27, discusses the mathematical sublime through the distinction between apprehending parts and comprehending a whole; §49 describes aesthetic ideas as occasioning thought beyond what a determinate concept can exhaust. These offer a later vocabulary for this room's investigation: how a finite arrangement can keep attention moving among possibilities we have not yet specified.

[^pattern]: The [Metropolitan Museum's account of geometric pattern](https://www.metmuseum.org/essays/geometric-patterns-in-islamic-art) describes its construction and combination with other ornament. It does not license a single spiritual meaning for all Islamic geometry. [Escher in The Palace's timeline](https://escherinhetpaleis.nl/en/about-escher/timeline) records his sustained study of the Alhambra and Córdoba mosaics in 1936; tessellation already appeared in his earlier work.

[^abstraction]: Kazimir Malevich, [*Suprematist Composition: White on White* (1918)](https://www.moma.org/collection/works/80385), MoMA; Hilma af Klint, [*Paintings for the Temple*](https://www.guggenheim.org/teaching-materials/hilma-af-klint-paintings-for-thefuture/paintings-for-the-temple), Guggenheim. These are distinct historical projects. Their juxtaposition here asks what abstraction promises; it does not establish a direct line of influence from Dürer or treat spiritual claims as scientific evidence.

[^clark]: Lygia Clark, [*Poetic Shelter* (1964)](https://www.moma.org/collection/works/91767), MoMA, and the museum's account of [Neo-Concrete art](https://www.moma.org/collection/terms/neo-concrete-art). Clark's participatory work is a particular Brazilian response to geometric abstraction, not a description of every South American modernism. The suggestion that participation changes what escape can mean is this book's proposal.

[^geometric-desire]: Lynn Gamwell, *Mathematics and Art: A Cultural History* (Princeton University Press), especially the preface, the account of chapter 2 on proportion, and the discussions of mathematical models and Minimal Art. Read in the [project's study copy](https://docs.google.com/document/d/1CaUhLfk_CvbcpKYPoIcafWBVoxSZvnw8NujHhC2thIQ/edit?tab=t.0). These discussions inform our distinction between constructing a relationship and assigning it aesthetic or cultural authority. The reading of Ada's pedestals, columns and geometric desire is our own. It does not establish a common intention or a line of influence among the artists brought together here.
