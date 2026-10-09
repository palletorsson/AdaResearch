# Reading a rule

*A study after Sol LeWitt · 1 October 2026*

At first the room seems full of different objects. Look again at the five forms on the long support. The white member keeps returning. Four corners stay on the ground. Above them, another four spread, contract or move aside. Much of the difference can be made by deciding where those corners go.

This is a useful image to carry through Ada. We can meet it before we know how to build it, return with a few operations, and discover that we can make something the image does not contain.

<div class="pair">
<figure><img src="reference-five-forms.png" alt="Supplied photograph: five white open geometric forms on one long plinth."><figcaption>The supplied five-form photograph. LeWitt's <em>Five Open Geometric Structures</em> is documented by <a href="https://www.lissongallery.com/artists/sol-lewitt/artworks/five-open-geometric-structures?image_id=3605">Lisson Gallery</a> as a 1979 work in acrylic on mahogany.</figcaption></figure>
<figure><img src="five-forms.png" alt="Native Godot study of a cube, pyramid, narrow box, truncated pyramid and sheared box."><figcaption>Our native Godot study. A chosen vocabulary of positions and connections; dimensions and joinery are approximations. This is a standalone scene, not a museum screenshot.</figcaption></figure>
</div>

## Begin with what the image gives us

We can see repeated white members, open interiors, five related forms and a common support. We can infer a family of connections. We cannot measure every concealed joint from the photograph, or recover a unique instruction that must have produced it.

The distinction matters. We are making an executable interpretation and comparing its consequences with the image. Getting a similar view is one test. Turning the camera and finding that the construction still makes sense is another.

For the cube frame, eight positions and twelve connections are enough. Four connections close the base, four close the top, and four join them. We already know how to join two positions from Point Lines. Giving the connection a white, square section lets us see it; the section is a material decision added to the abstract line.

The cube's twelve edges are not its twelve triangles. We do not need to fill the six openings with faces to make this work. Godot supplies a mesh for each bar; the learner supplies the relations between the corners.

## Five forms, three decisions

| In our study | Decision | What stays fixed |
| --- | --- | --- |
| Cube | Keep both squares the same size | Height, connections, member thickness |
| Narrow box | Reduce both horizontal coordinates | Height and member thickness |
| Truncated pyramid | Shrink the upper square | Base and height |
| Pyramid | Bring the upper corners together | Base; four edges now reach one apex |
| Sheared box | Move the upper square sideways | Base; parallel upper and lower squares |

The tapered form reveals a real gap in the lineage. Scaling the whole cube shrinks its base too. To keep the base and narrow the top, we must select which positions change. Shearing is also a new operation, not another name for rotating the object.

At the pyramid's apex, four stored addresses coincide. The top edges have become zero length. Our renderer omits them, leaving five distinct positions and eight visible edges. We can still keep eight entries in the list, but the list no longer counts the distinct places in the object. The familiar cube description has reached one of its limits.

## An array gives each decision an address

<div class="pair">
<figure><img src="reference-combinations.png" alt="Supplied photograph of white open forms arranged on individual plinths in a square array."><figcaption>The supplied arrangement. MCA Chicago catalogues LeWitt's 1979 book <a href="https://mcachicago.org/art-artists/collection/open-geometric-structures-five-geometric-structures-and-their-combinations/">Five Geometric Structures and their Combinations</a>. This reference does not establish the exact placement rule of this photograph.</figcaption></figure>
<figure><img src="cyclic-array.png" alt="Our five-by-five Godot array with a cyclic selection of five forms."><figcaption>Our proposed cyclic arrangement: twenty-five addresses, five available forms. The rule is ours, not a recovered LeWitt instruction.</figcaption></figure>
</div>

The existing Chessboard study asks for a colour at each address. Here we ask for a form. The placement can remain unchanged while the answer at every place changes.

<div class="experiment" data-comparison="array">
<p class="eyebrow">ONE CHANGE / SAME CAMERA</p>
<div class="switches"><button type="button" data-choice="cyclic" aria-pressed="true">Shift each row</button><button type="button" data-choice="repeat" aria-pressed="false">Repeat the row</button></div>
<p class="rule"><code data-rule>(column + row) % 5</code></p>
<img data-result src="cyclic-array.png" alt="Native Godot capture of the cyclic array; the five forms shift by one place in each successive row.">
<p data-note aria-live="polite">Each new row begins one form later. Five forms return in another order.</p>
<p class="small">These buttons compare two recorded Godot states. Open the downloadable project to orbit and change the live scene.</p>
</div>

`% 5` makes the count wrap after five choices. It is a compact rule with a large visible consequence. We do not have to introduce randomness to make variation, or choose twenty-five objects independently to make a complex arrangement.

## A footprint, then a height

<div class="pair">
<figure><img src="reference-modules.png" alt="Supplied photograph of five white stepped cube lattices on a wooden floor."><figcaption>The first photograph appears to show <em>Five Modular Structures (Sequential Permutations on the Number Five)</em>, 1972. The <a href="https://www.nationalgalleries.org/art-and-artists/313/five-modular-structures-sequential-permutations-number-five">National Galleries of Scotland</a> describes a shared ground plan and structures rising in steps to five units, with the fifth uniformly five units tall.</figcaption></figure>
<figure><img src="five-height-rules.png" alt="Native Godot capture of five cross-footprint lattices generated by different height rules."><figcaption>Our response: one cross-shaped footprint, five explicit height rules. The exact footprint and functions are hypotheses for this study, not a measured reconstruction.</figcaption></figure>
</div>

The first photograph looks more complicated, but the unit is simpler: keep the same cube frame and repeat it. At each ground address, decide whether a column exists. If it does, decide its height. A third loop places the units above one another.

Our five height functions are `x + 1`, `5 - x`, `z + 1`, `5 - z`, and `5`. The first four climb in different directions. The fifth holds every occupied column at five units. Now change only which ground addresses are occupied.

<div class="experiment" data-comparison="footprint">
<p class="eyebrow">ONE CHANGE / SAME HEIGHT RULES</p>
<div class="switches"><button type="button" data-choice="cross" aria-pressed="true">Cross footprint</button><button type="button" data-choice="square" aria-pressed="false">Filled square</button></div>
<p class="rule"><code data-rule>x == 2 or z == 2</code></p>
<img data-result src="five-height-rules.png" alt="Five stepped lattices built on cross-shaped footprints.">
<p data-note aria-live="polite">Nine ground addresses per structure. Much of the square is left empty.</p>
<p class="small">Recorded native Godot views. The change adds occupied columns while preserving each structure's height function.</p>
</div>

The footprint changes how much of the room the structure occupies and how much of another structure we can see through it. “More” is not only a larger count. It is a different relation between an object, its neighbours and the observer.

## When are we ready in the spine?

**The full project belongs in Arrays, completed at Tutorial_3D.** We can introduce the photograph much earlier. Recognising a connection is a useful first achievement; independently generating a family is a later one.

| Return in the spine | What the student can now contribute |
| --- | --- |
| Point One → Coordinates | Distinguish a position from its visible body; place the corners. |
| Point Lines | Join two positions; give a line length, direction and thickness. Begin reading the photograph. |
| Trace → Grid | Keep positions in a list; use repeated addresses. These are dependencies, not permission to skip ahead. |
| Triangle → Polyhedra → Cube | Read connections and faces; construct an enclosure from shared corners. Make an individual open frame using the supplied bar renderer. |
| Transformation | Place, rotate and scale instances. Add a short bridge for changing selected corners: taper and shear. |
| Array | Make a row, then a table; choose a form at each address. This is the five-form arrangement's teaching home. |
| Tutorial_3D | Add the third index and an occupancy or height rule. Make the stepped structures. |

The current **Chessboard** kit already makes the transfer concrete: change `colour_of(x, z)` into a function that chooses a form or a height. But the map folder for **Array** does not yet contain its own `tutorial.md`, and the existing Tutorial_3D technical text mainly describes the production artifact. Conceptual placement is not the same as a finished learner route. This portable study supplies a bounded bridge; it should not be treated as proof that the whole curriculum already teaches every step.

For the hall, I would first show the five-form row together, then the array, with space to look back at the row. Keep the larger lattice for the return in Tutorial_3D. In Point Lines, one frame or one reference image is enough: showing the whole vocabulary there would make the first line carry too much.

## What can we make that is not in the photograph?

<figure class="wide"><img src="between-forms.png" alt="Seven Godot frames progressing from pyramid to cube by increasing only the upper square's size."><figcaption>Our variation: seven sampled upper widths. Base, height and bar thickness stay fixed.</figcaption></figure>

Between the named forms there is room. We can let the upper square grow through seven sizes. We can leave out one connection and find the view from which its absence disappears. We can use the same height rule on a diagonal, a border or a footprint with a gap. These are small, explainable decisions with different spatial consequences.

There is a critical question inside that pleasure. Why these five forms? What did the vocabulary make easy to see, and what did it leave unnamed? A system can be open to view and still allow only a narrow set of answers. The intermediate forms give us a way to press on the selection without abandoning the rule.

Making an inhabitable version is a further step. Scale alone will not tell us which openings admit a body. We would need to choose collision boundaries and test passage. That is a possible return to the museum, not something the current desktop study claims to have established.

## Try, compare, keep the result

Start with one form. Predict which corners will move, change one value, and inspect from two sides. Then change a selection rule while keeping the addresses still. Save the original, your inferred rule and one variation together. The image gives the investigation somewhere to begin; it does not have to be its final answer.

[Open the short making study](making.html) · [Download the complete Godot project](open-structures.zip) · [Read the project notes](README.md) · [Inspect the native test report](report.json)

**Built and checked:** four scene modes, eight native captures and 27 passing checks in Godot 4.6. Checks cover edge counts, coincident apex positions, finite transforms, fixed bases, unchanged grid addresses and the two rule changes. No existing hall or canonical manuscript was changed by this study. No learner or physical headset trial has been made.
