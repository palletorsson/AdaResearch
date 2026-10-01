# The plate

*Before Day Zero · nothing to install · one picture to look at*

The course opens with a picture and comes back to it at the end of every part.

It is plate 31 of Ernst Haeckel's *Kunstformen der Natur* (Art Forms in Nature), 1904: *Cyrtoidea*, in German *Flaschenstrahlinge*, the flask-shaped radiolaria. Haeckel drew it and Adolf Giltsch made the lithograph. The plate is in the public domain. The copy at the top of this page comes from [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Haeckel_Cyrtoidea.jpg), made smaller.

Radiolaria are single cells that live in the sea and build a skeleton of silica. Each of the nine on the plate is smaller than a grain of sand.

## Look first

Look at the plate for a minute before you read on. Write down two lists: what the nine bodies have in common, and what differs between them.

Keep the lists. We come back to them.

## What the nine share

Here is our list. Yours may be better.

1. **One axis.** Every body stands on a vertical line and is the same all the way round it.
2. **An outline.** Cover the left half of a body. The right half is one line from the tip of the horn to the lip of the mouth. Turn that line round the axis and you have the shell.
3. **Joints.** The line pinches in and swells out: a head, a chest, sometimes a belly, sometimes five in a row.
4. **Pores.** The wall is a lattice. The holes sit in a honeycomb, six round each, and on some bodies they grow larger toward the mouth.
5. **Counted parts.** One horn on top. Three feet at the mouth, or a crown of teeth. The count goes round the axis.
6. **Bristles.** Thin needles, here and there, with no count at all.

What differs is numbers: how long the line is and where it pinches, how wide the bars between the pores are, how many feet, how long the bristles. The plate reads as nine species. It can also be read as one body with about ten numbers, shown nine times. In this course that is called a family, and a page like this one is its comparison sheet.

## Three people who asked whether form has rules

**Haeckel drew.** He looked through a microscope at thousands of these shells and put them in order on the page.

**D'Arcy Thompson transformed.** In *On Growth and Form* (1917) he argued that a living form is a diagram of the forces that made it, and that one form becomes another when the grid it is drawn on is stretched or bent. He used Haeckel's radiolaria as examples.

**Turing asked whether a rule could grow them.** He had read Thompson's book as a schoolboy. In 1952 he published "The Chemical Basis of Morphogenesis": two substances that react and spread can make a pattern from almost nothing. One of his last students, Bernard Richards, solved Turing's equations on the surface of a sphere and found shapes with two, four and six spines that matched radiolaria Haeckel had drawn for the report of the *Challenger* expedition.

Palle Torsson, whose project this course belongs to, takes Turing as its muse. What is documented is that Turing knew Haeckel's drawings and used them as the test of his theory: he told Richards that the shapes his equations gave were real organisms, drawn in the records of the *Challenger* voyage.

The three are also three ways of working, and the course uses all of them: read a form as rules, change one form into another, and let a rule grow it.

## The remake

![One shell as six operations, and six shells from the same operations](/course/plate_remake.png)

We made the plate again in Godot. The top row is one shell, one operation at a time:

1. a profile, the half outline;
2. the profile turned round its axis;
3. pores, by the rule the project already had: inset every triangle and delete the middle;
4. pores, by a new rule: inset a cell of six triangles toward the point they share;
5. three feet, branched from three faces of the lip;
6. bristles, branched thin from a few of the bars.

The bottom row is six shells made by the same list with other numbers.

Two of the rules did not exist in the project before this picture: turning a profile round an axis, and the cell of six. They were added for it. Everything else was already there.

![Six forms, five stages each](/course/plate_family.png)

The same six, each stopped at five places in the list. In the museum this is one work, `cyrtoid_by_rule`, with two axes: `form` and `stage`.

The remake does not reach the plate. Its wall is a sheet with no thickness. Its pores are hexagons where the plate has rounded holes. Its feet are straight where the plate has claws, and it has no wings. Each of these is a rule we do not have yet.

## What of it can you make now

Each part of the course ends with this question. These are the answers we expect; yours go in your sketchbook.

| After | What of the plate you can make |
| --- | --- |
| Place and join | The outline: one half of a shell as a recorded line, from the horn to the lip, and the axis beside it. With the turn handed to you as one function, a solid vase with joints. |
| Articulate | The joints as parts under one root: head, chest, belly. And Thompson's move: shift the points of one profile and the helmet becomes the flask. |
| Repeat and vary | Counting round the axis: three feet, eighteen teeth. Then the shell as one class with its numbers, and the plate as a comparison sheet of one family. |
| Surface | The pores: cells of six, opened, wider toward the mouth. Bone white on black. Here the vase becomes a skeleton. |
| Move by law | Feet that curve, drawn as a path made of steps. A shell that sinks and drifts under a force you wrote. |
| Disturb, field, skin | Bristles from a seeded chance. Pores whose size follows a noise field, as on the large shell in the middle of the plate. A shader for the engraved line. |
| Grow by rule | Turing's question. Do not place the pores and spines; let a rule decide where they come, and open and branch what it marks. One individual saved as a file of numbers. |
| Deform, imply, combine, flock | A wall with thickness, and pores made by taking away. Many shells drifting together. |
| Learn, break, measure, release | A hall of shells in the collective museum, each with its numbers shown, and what the plate hides said beside it. |

## What the plate owes

The plate is not a photograph. Haeckel drew his shells more regular than the ones under the microscope, chose which to show, and arranged them as ornament. Its symmetry is partly his.

The same author arranged human beings in a hierarchy of races, and others used that ranking after him. An eye that puts forms in order can put people in order too. We keep the plate, and we keep that beside it.

Our remake has its own debt: it shows only what our rules can say. A shell that fits none of them would not appear on our sheet.

## Sources

- Ernst Haeckel, *Kunstformen der Natur*, plate 31, 1904: [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Haeckel_Cyrtoidea.jpg)
- Bernard Richards and Turing's equations on a sphere: [Alan Turing: Virtuosity and Visualisation](https://www.researchgate.net/publication/305315466_Alan_Turing_Virtuosity_and_Visualisation)
- Turing reading Thompson: [Selection, growth and form: Turing's two biological paths towards intelligent machinery](https://www.sciencedirect.com/science/article/pii/S0039368124000657)
- Thompson and Haeckel's radiolaria: ["A Single and Indivisible Principle of Unity": On Growth and Form in Context](https://link.springer.com/article/10.1007/s13752-023-00449-x)

These were found by a web search on 1 October 2026 and read as summaries, not in full.
