# lsystems: the chapters

## LSystems Grammar Lab

*LSystems_Grammar_Lab*

### The same sentence, another body


Two upright lines meet us. Below each, the same letter: `F`. Can one sentence have two bodies?

Press NEXT once. The live line acquires turns; the held line stays where it was. Count the live segments before looking at the counter. Then press HOLD. Both drawings now share this sentence:

```text
F+F-F-F+F
```

Leave NEXT alone. Press TURN. Follow the first bend across the two drawings. The letters below them have not changed. One reading turns through ninety degrees; the other now turns through a hundred and twenty. Five drawn segments in each, yet the same route through the symbols takes another route through space. Some segments may overlap. Count the instructions as well as the lines you can distinguish.

We brought a construction out of the fractal halls. Here we can separate two moments within it: making a sentence, and reading that sentence as movement. HOLD gives us time beside a previous reading. TURN changes the live interpreter's angle. NEXT rewrites the sentence from which it draws.

Keep the new angle and press NEXT again. The held drawing remains. The live sentence has forty-nine symbols and twenty-five drawing instructions. The turning signs also take up space in the string; they do not each leave a segment. What has multiplied, and what has merely been carried forward?

RULE opens the replacement used by this preset: each `F` becomes `F+F-F-F+F`. In `lsystem_editor.gd`, the next sentence is assembled from the old one:

```gdscript
var new_string = ""
for c in _current_string:
    new_string += str(_rules.get(c, c))
_current_string = new_string
```

A symbol without a replacement passes through as itself. The newly written letters wait for the next generation; they are not rewritten again during this pass. First one `F`, then five, then twenty-five. The small loop has a rhythm, and a place where its repetition must wait.

Another pass through the resulting string gives it geometry. `F` and `G` advance the turtle and draw. `+` and `-` turn its heading. The turtle is a travelling state: position, direction and a sideways axis. A line does not tell us all of that state by looking like a line.

Try RESET, then PRESET three times to reach PLANT. There is an `X`, and no line above the live plinth. We met an invisible point in the first hall, Point One. This absence has a different cause: `X` belongs to the rewriting rules, but this interpreter gives it no drawing action. Press NEXT. Drawing instructions appear around the `X` symbols. What was undrawn was still capable of contributing to the next sentence.

The brackets now matter. `[` saves the travelling state; `]` restores it. A branch can end without forcing every later segment to continue from its tip. The next hall will let length enter that inheritance too.

Look again at the two outlines. Each is fitted to its display. More instructions need not make a taller body here. That apparent continuity of size is another operation, performed after the turtle has travelled. Our eyes receive a composed result: rewriting, interpretation, fitting, thickness, light. None is the untouched original behind the others.

This desk stops at four requested generations, with a budget of 4,096 symbols. If a replacement would exceed that budget, the last complete generation remains. Its readout distinguishes the generation shown from the one requested. A long printed sentence also declares that only its first 120 symbols are visible. Two different limits, two different kinds of remainder.

Seven presets give us places to begin. They do not exhaust the bodies that a grammar could permit; the physical desk does not yet let us type a new rule. Nor does a changed outline automatically make another space habitable: these thin drawings have no collision surfaces. The desire to inhabit them brings another body, another requirement, into the question. Which operation would we have to open next?


The earlier trees, the string study, the city grammar and three trees grown from three traditions’ axioms remain beyond the desk; the last of these asks whose grammar a rule is. Their resemblance can invite a comparison without proving that they share its live sentence. Carry the bracket into the next room: what must a branch remember so that another branch can begin?

---

## LSystems Growth

*LSystems_Growth*

### What a branch remembers


A short upright line, a pale point at its tip. Beside it, a second reading waits. We have brought the turtle out of Grammar Lab. There, we changed the angle of a sentence. Here we can follow what the turtle carries from one instruction to the next.

The sentence is already written:

```text
F[+F]F[-F]F
```

This tree's rule replaced one F with those eleven symbols. It is the first of a small family printed in Prusinkiewicz and Lindenmayer’s *The Algorithmic Beauty of Plants*; Competition’s rule and the readers in the hall after next come from the same page.[^LSystems_Growth--abop] Its first F has drawn a line 0.8 metres long. The pale point marks the turtle's current position. What must it keep if it is to leave the trunk, make a branch, and find its way back?

Press STEP once. Nothing extends. The next symbol is `[`. The readout says SAVE; the stack count becomes one. The next length has changed from 0.800 to 0.576 metres, although the point has not moved. An operation has taken place without adding anything to the outline.

STEP again: `+` changes the direction. Another STEP reaches F, and the shorter branch appears. HOLD this reading. The held drawing keeps its pale point at the new tip.

Now comes `]`. Where will the live point go?

It returns to the fork. The branch remains drawn, with no return line joining its tip to the fork. Next length is 0.800 again. Press STEP: the trunk continues upward from the saved position. The branch's turn and shorter stride have not become the trunk's next instructions.

The turtle carries a state: position, orientation, length, angle and branching depth. At `[`, the interpreter puts a copy on a stack. A stack returns the most recently saved record first. One branch may contain another; the inner branch must finish before we return from the outer one. This nesting gives a small program a way to remember several departures without confusing their returns.

After saving, the source changes two values for the branch:

```gdscript
current_length *= length_decay
current_angle *= 0.95
```

The first line means: take the length we have and multiply it by the ratio. Here, 0.8 × 0.72 gives 0.576 metres. The second changes forty degrees to thirty-eight. F still means draw forward, but how far forward now depends on the state in which the turtle reads it.

At `]`, this excerpt from `parametric_lsystem.gd` retrieves the saved record:

```gdscript
var state: Dictionary = stack.pop_back()
pos = state["pos"]
dir = state["dir"]
right = state["right"]
up = state["up"]
depth = state["depth"]
current_length = state["length"]
current_angle = state["angle"]
```

Position returns, the orientation axes return, and the previous length becomes available again. None of these assignments removes a segment already drawn. A return can preserve what happened during a departure while allowing something else to continue.

Keep stepping until all eleven symbols have been read. Five segments, two side branches, a stack empty again. HOLD the complete reading. Then press RATIO once: 0.72 becomes 1.00. Follow a side branch against its held counterpart. It now takes the same 0.8-metre stride as the trunk. The sentence and turning directions have stayed the same. Both drawings use metres; neither is squeezed to fit its plinth.

Press RATIO again. At 1.15, the branch is longer than the segment from which it departs: 0.92 metres. The code calls this value `length_decay`. Its name suggested shortening. The multiplication also permits something else. Which proportion made this drawing look like a proper tree to us?

TREE shows two complete rewriting generations. There are now sixty-one symbols and twenty-five drawn segments. The unshortened trunk reaches 7.2 metres above its starting point. Within a branch inside another branch, the length factor is applied twice: 0.8 × 1.15 × 1.15 = 1.058 metres. The pink first generation remains beside it until we choose to hold another reading. We can follow a local rule and still be surprised by the room it begins to occupy.

STEP reveals a recorded trace of the interpreter; it does not make the computer wait between its calculations. TREE requests another sentence. These are two different ways of looking into a process that would otherwise arrive as a finished drawing. RESET brings back the first line when we want to follow it again.

The stack offers a dependable return, but only for the state its programmer chose to save. It contains no sunlight, weight or account of a neighbouring body. The thin branches have no collision surfaces. Their resemblance to a tree leaves those further requirements open. What would we have to add before this branching could support, shelter or obstruct us?


The animated tree, the obstacle-querying tree, the earlier L-system tree and the cypress remain beyond the desk. They approach growth through other operations. Carry this distinction forward: a sentence supplies instructions; an interpreter decides what they do. In the next hall, even forward may be read sideways.

[^LSystems_Growth--abop]: Przemyslaw Prusinkiewicz and Aristid Lindenmayer, *The Algorithmic Beauty of Plants* (Springer, 1990), figure 1.24: F[+F]F[−F]F is its (a), Competition’s F[+F]F[−F][F] its (b), and the believing turtle’s FF+[+F−F−F]−[−F+F+F] and Grammar Lab’s PLANT preset are its (c) and (f) with the turns mirrored.

---

## LSystems Grammars And Curves

*LSystems_Grammars_And_Curves*

### When forward goes sideways


Does an instruction say how it must be obeyed?

Three short lines rise from three origins. Each has read the first F of the same sentence, taking a stride of 0.32 metres. We have kept the travelling state from Growth, but the question has moved: what agreement connects an instruction to a movement?

Press READ F. The blue line goes sideways. Its gold arrow still points up; its white arrow points across. The gold arrow shows the stored heading, the white one the direction the reader will draw. Those two directions no longer agree.

The sentence has not changed. Neither has the stride. This reader takes the direction it was given and exchanges its x and y components. What used to contribute to height now contributes to horizontal distance. Before seeing a whole tree, we can catch the disagreement in a single step.

Now press ANGLE. The middle reader changes from twenty-five to forty-five degrees. Its first line stays upright. Why did this change produce no visible turn? Keep pressing STEP until the sixth symbol. The first two Fs extend the stem; a plus turns the heading; a bracket saves it; another plus turns again; the next F draws. The middle reading has departed from the green reference. An angle matters when an instruction uses it.

All three readers follow:

```text
FF+[+F-F-F]-[-F+F+F]
```

There are twenty symbols and eight drawing instructions. Finish the sentence, finding corresponding forks as you go. When the brackets close, the saved positions and headings return, as they did in Growth. Each drawing has read the same bracket at the same moment. Yet one spreads differently, and another seems to have forgotten which way a tree should stand.

Here is the direction calculation in the believing turtle:

```gdscript
var dir := Vector2(cos(heading), sin(heading))
if sideways:
    dir = Vector2(dir.y, dir.x)
```

The angle called heading supplies the two components of a unit direction. The conditional exchanges them. The next line uses that direction to take a step in the museum's drawing plane:

```gdscript
var nxt := pos + Vector3(dir.x, dir.y, 0.0) * step
```

The third component is zero: these drawings remain planar inside a three-dimensional room. The step multiplies the direction; adding it to the current position gives the next position. This is the vector operation we brought through the earlier halls, now given another reading.

Try to match every blue fork to a green one. The correspondence is unusually dependable. With the same angle, exchanging x and y at every step reflects the entire construction across the diagonal x = y, relative to its origin. It preserves lengths, angles between segments and which branches connect. A reflection can overturn our expectation of uprightness while retaining this much structure. It is not simply a ninety-degree rotation; follow an off-axis branch to see the difference.

![The green reading and the blue READ F reading of the same sentence at TREE, drawn from the rule, with the diagonal x = y through their shared origin](/book-review/doc/book/figures/lsystems/believing-turtle-reflection.png)

*Both readings drawn from the rule at generation two: 172 symbols, 64 segments each, 25 degrees, a 0.32-metre stride. The blue one is the green one reflected across the dashed diagonal; every fork has its counterpart.*

Press READ F again. The blue reading returns to the green one's arrangement. The exchange is reversible. Its strangeness has a precise operation we can repeat, inspect and undo.

TREE gives all three readers two complete rewriting generations: 172 symbols, 64 drawn segments. The same local differences accumulate across a larger body. No drawing has been resized to fit its case. Find the first fork again before trying to recognise the whole outline. More detail can obscure a relation we understood one step earlier.

STEP reveals recorded interpreter states, not a calculation suspended between button presses. After the last symbol it returns to the beginning of the reading; RESET also restores the initial angles and forward convention. The original lectern and its smaller studies remain behind this desk, including their unequal step lengths and finite drawing prefixes. They offer another comparison, with different conditions.

Calling this reader a believing turtle gives us a way to attend to its commitments. It does not give the turtle an inner conviction. The commitment is executable: F is assigned a direction through this code. We can change that assignment. We can also ask what the change has left untouched. The branches still have no collision surfaces; a sideways drawing has not yet become somewhere we can stand. That further desire needs another operation.


<!-- study-spine:tube_painting -->


Someone has already begun. Three bent lines hang in front of a pale wall. Their ends are within reach. Take one and continue it.

The part you inherited stays where it was. Your hand adds to its end. Let go: the new length remains in the air, carrying the turn you just made. Bring another end towards the wall and it settles against the surface. A drawing begins to make its own partition.

There is a pen for starting elsewhere. But beginning again is no longer the only invitation. You can accept the shape already here, prolong it, or make its unfinished edge lead somewhere its first gesture did not suggest.

Choose VIEW. The coloured skin disappears. A path remains; then rings appear along it. Choose again and the faces return between them. What looked like a single flowing body keeps a count of the decisions that made it.

These lines do not sag. Their suspension is something the program grants. The wall is a place to meet, not a support they need. Leave one end unattached. For once, an unfinished thing does not have to fall.

Choose NETWORK. A white pipe holds an opening through its middle; a black cable hangs between two supports; the pink tube keeps the turn of a hand. Bring an end to another run. An amber marker offers a joint. Release, and the two share a connection. A crossing alone is not enough. What looks continuous still needs a decision about where it belongs.

Beside the drawing, three coloured bodies wait above dark wheels. Close the power lever. The wheels turn at unequal rates; each body finds another sway. Pull the motor cord and the figures keep their last pose. The small synthesizer can go on sounding. Its connection is elsewhere.

The cord has the same kind of skin as the lines we have been making. Here its ends also carry an agreement: this output may reach that input. The drawing has acquired a consequence. What would we connect if a line could give something else permission to move?

Look up. Large pink pipes pass over and under one another. Their gloss bends the room back towards us. Change the rule at the small console: the weave becomes ribs, then long returning loops. What fitted in a hand now reaches across the bay. Repetition has given the line the scale of a ceiling. We are standing inside one of its arrangements.


The floor curves and the volumetric path remain in the collection. Their finite constructions let a sentence visit many grid locations; they do not occupy every point of this room. Beyond them lies Architecture. A step will acquire width, a branch may become a corridor, and a return will have to be considered in relation to a body trying to find its way.

---

## LSystems Architecture

*LSystems_Architecture*

### When a line acquires walls


Can a line admit you?

Four pale segments lie on the floor. One leads from the entrance to a junction; two turn away from it; the fourth continues ahead. You can already follow them with your eyes. On the flat plan, your feet can also ignore them. There is no wall asking you to choose.

Press BUILD. A low solid base and glass rise along the boundary. Enter beside the control desk, take a side branch and come back. The junction is open; the side branch ends against a wall. The straight continuation has another opening. Those different endings were decisions someone had to supply.

We have brought the turtle's saved position and direction from Growth. The previous hall changed how it read forward. Here we keep one reading and ask what must be added around it. The dungeon's branch rule rewrites F once into this short program:

```text
F[+RF][-RF]F
```

The first F reaches the junction. The bracket saves that position and direction. A turn, a room marker and another F make the first side branch; closing the bracket returns the turtle to the junction. The second bracketed group does the same on the other side. The last F continues the stem. Each movement becomes four metres in this study.

Two Rs appear in the sentence. Find the two places they mark. Follow the brackets carefully before deciding that there must be two rooms.

In the dungeon's actual interpreter, R does this:

```gdscript
rooms.append(pos)
```

It records the current position without moving. Both branches begin at the same saved junction, so both room records have the same address. A list can count two instructions while the floor contains one shared place.

Leave the brass frame and press ROOMS. The junction spreads into a square, 2.8 metres across. Enter again and step away from its centreline. There is now somewhere to pause while another route continues through. The program has acquired a spatial use through the footprint we assigned to a mark. The mark itself did not contain a gathering, a cupboard or a private retreat.

The construction collects the floor cells covered by all corridor and room footprints. Shared cells are kept once. At each cell edge it asks whether another occupied cell lies beyond it:

```gdscript
if occupied.has(cell + direction): continue
```

An internal edge receives no wall. That small refusal keeps the junction open. At exposed edges the builder places walls, except at the two deliberately chosen main entrances. The grammar supplies the records; the construction supplies a boundary policy. Calling the records architecture did not perform this work for us.

Return outside the frame and try WIDTH. The clear width cycles through 2.2 metres, 0.4 metres and back to 1.4. Watch the pale centrelines: they stay where they were. Try entering the narrow version. Your body’s collision capsule is forty centimetres across, and so is the gap. The line continues without a break; whether you pass is decided by the disagreement between a capsule and two walls, a few centimetres the plan does not show. Opening the junction into a room will not repair that entrance.

This gives us two descriptions of connectivity. Every branch still meets the same junction in the plan. The space available to this body has changed. Its size participates in what counts as a passage. A different body would require another test. More branches would not answer the question that width has made concrete.

The controls refuse construction changes while a visitor remains within the study. Leave its frame, then press again. That rule belongs to this space too: the person at the desk cannot silently rebuild the walls around someone inside. We can examine the rule and imagine other arrangements for agreeing to a change.

PLAN removes the walls and lowers the footprints to a drawing you can walk across; RESET returns to the opening comparison. The museum floor remains beneath every state. Behind the study, the original miniature dungeon rests on its plinth. Its more elaborate grammar fits into a small display. Look down at it with the narrow entrance still in mind. A plan can be legible to an eye long before it is usable by a body.


The retained orthogonal structure, folded dragon path, seed and mesh studies offer further readings. We will return to them. Beyond the seed study a floor hatch opens as you approach and offers a crystal; lift it and, five seconds on, a vent nearby answers with three walking bodies, an encounter another chapter will read. Next, in Competition, we ask what happens when a rule's next move must meet a world that other growth already occupies.

---

## LSystems Competition

*LSystems_Competition*

### Who gets the first turn?


Two stems wait above a tiled field. One is amber, one blue. Both begin with F, the same diameter and the same rule. Their colours let us follow them; colour gives neither a different appetite.

Press STEP: A takes a turn. A small branch appears, and a square patch of soil drops. Press STEP again: B’s turn; the readout names who is next. Both have reached generation one. Look at what they took: A received 2.250, B 1.980. These are the model's resource values. We have not measured grams of food.

Is something wrong with B's instructions?

Press ORDER to begin the comparison again with B first. The same soil returns; the same two starting stems return. Take two turns. B now receives the larger amount. Nothing in the branching sentence had to change.

Architecture separated the line from the boundary that lets a body pass. Here we separate a rewriting rule from the conditions that let it run. The familiar brackets still save and restore a turtle's state. Both specimens use this replacement:

```text
F → F[+F]F[-F][F]
```

The forest does something before applying it. It reads the soil around the selected root, subtracts a portion from each cell, and adds those portions to the tree's uptake. The comparison gives both trees a growth multiplier of one. This excerpt is the subtraction inside that cell loop:

```gdscript
var take := minf(_nutrient_grid[cy][cx] * 0.15 * tree.growth_rate_mult, _nutrient_grid[cy][cx])
_nutrient_grid[cy][cx] -= take
uptake += take
```

Each initial sampling square contains twenty-five cells. The squares overlap in twenty cells. The first tree takes fifteen percent of each cell's current value. The second arrives at a patch partly used by the first. Its rule is intact; its starting world is already different.

The two root markers are close together on the field. The branching displays stand apart, enlarged four times so that we can inspect them. Their display positions do not move the roots. Follow the coloured squares back to the soil before mistaking the distance between the exhibits for the distance in the calculation.

Try SEASON. This also begins a fresh comparison, now holding winter steady. Take two turns. The patch sinks, and the uptake readings change. The stems do not branch.

The consumption happened before this test:

```gdscript
if nutrients > 0.05 and _current_season != Season.WINTER:
    tree.lsystem.generate()
    tree.generation += 1
```

Winter refuses the rewrite. It also stops the separate diameter increment. It does not undo the earlier subtraction. A body can remain visibly still while changing the conditions around it. To discover that here, we needed the field as well as the tree. A picture of the crown alone would have concealed the operation.

Press SOIL. For one simulated second, nearby cell values diffuse and replenishment draws them towards the supplied level. No tree takes a turn; the chosen season stays fixed. In winter replenishment is slower. The desk separates these operations so we can follow them. Behind it, the original forest runs them together over time, with five different grammar strategies and the earlier controls.

Return to spring and let the pair reach three generations. Further turns report a generation limit. The limit belongs to this study. It does not tell us that the trees have matured, exhausted their world or found an ideal form. Soil can still change. Even an ending needs its condition read.

We can now ask something more specific of the forest. Which differences came from instructions, which from resources, and which from whose turn came first? The order is a small piece of code, easy to overlook among the branches. It helps distribute a possibility of growth.

There are other schedules we could write: rotate the first turn after each round, or calculate everyone's request before changing the shared field. Neither is supplied by these buttons yet. Each would give us a different experiment. Calling the first arrangement natural would close that opening too soon.


Stay with the retained coral for a moment. Its branching form has another recipe; it is not drawing food from this soil. Similar-looking bodies need not inhabit the same relations. In Living, we turn towards the controls that let us author a body, and ask which possible changes those controls have made available.

---

## LSystems Living

*LSystems_Living*

### What counts as a change?


The tree waits above a low plinth. Beside it is a place for another tree. Press HOLD. Now there are two: the design we can change and a witness that will stay where we left it.

In Competition, the same grammar met different conditions. Here we reach further back, towards the numbers from which a grammar is made. The desk begins with Depth selected. Its value is 4.000. Press MORE once. The number changes. Look at the branches.

Try again. And again. By 4.800, the number has moved four times, but the tree still agrees with its witness. Is the control doing anything?

One more press reaches 5.000. Another generation of branching appears.

The control has been changing a value called segments in the DNA resource. DNA here means a collection of parameters used to construct a body. It is a name for this data structure; the name does not establish that the specimen is alive. The tree generator reads that value through this line:

```gdscript
var generations: int = clampi(roundi(dna.segments * 0.5), 2, 5)
```

First halve the raw number. Then round it to a whole number. Finally keep the result between two and five. At 4.800, the intermediate value is 2.400; it rounds to two. At 5.000, it is 2.500; it rounds to three. The number we moved and the instruction the generator received are different records.

Here a continuous control is translated into whole rewriting generations. Several distinct settings produce the same instruction. That is useful: a generation must be a count. It is also a place to look when a desired difference disappears.

The tree still starts with F. At each rewrite, F becomes a short stem S followed by bracketed branches. The Forks gene supplies their count and Arrange supplies their turns. S, in turn, becomes FF. The turtle then reads the completed sentence, advancing, turning, saving a state at an opening bracket and returning at its closing partner. The earlier grammar lessons are inside this instrument.

Use GENE to pass through Forks and reach Angle. A small increase now changes the directions of the branches without adding a rewriting generation. Two controls move smoothly under the hand, yet one crosses a counting threshold while the other changes geometry. A control's appearance cannot tell us what kind of change it offers.

Press PLANT. A copy appears on the floor pad beyond the two plinths. Change the editing tree again. The placed one keeps its form. HOLD keeps its own witness too. RESET restores the opening design and leaves these copies for comparison.

This steadiness had to be written. The export used to point at the same editable DNA resource. Moving a slider could therefore change the data that a later consumer would receive. Now the export begins by making a copy:

```gdscript
var snapshot := _dna.duplicate(true) as CritterDNA
Engine.set_meta("sculptor_tree_dna", snapshot)
```

The hall also copies the displayed geometry onto its planting pad. A later PLANT replaces that local specimen. The older branching catalyst has a different use for the exported DNA: it may mutate and rescale a copy when producing a temporary tree. Placing a specimen here does not recruit it into Competition's soil or teach the floor to grow.

The original eight sliders remain on the side rack, including RANDOM. They offer more ways into the same resource. Eight controls are still only a selection from the parameters and rules that make the body. They cannot ask for a new alphabet, a branch joined back to an earlier branch, or a different relation to the ground. Those changes require another part of the program.

On the side rack, drag Depth and Forks towards their upper limits and read the command count on the desk. The sentence can request more branches than this preview will draw. At its current detail level, the interpreter stops after two hundred F or S drawing commands; very short segments may produce no mesh at all. The display names that budget. What looks like a finished crown may be the point where drawing was stopped.

There is pleasure in finding a body among these variations. There is another kind of curiosity when the variation we want has no control. Stay with that desire long enough to name what is missing: another connection, another rule, another way of occupying the room. Then we have somewhere specific to continue writing.


The older tree, coral and paper studies remain beyond the workbench, among the authored platforms. Each makes form through its own procedure. Next, a cube returns. We will open another part of the program: the operations that select its faces, draw them inward and extend them. The question of a desired change with no control will have a different body to work on.

---

## LSystems Shape Grammars

*LSystems_Shape_Grammars*

### A family the cube can become


The cube has returned. It stands on a low plinth, small enough to look down on. A dark diagonal crosses its pink top. We met that division in Primitives: the square the eye gathers is two triangles in the mesh.

The first six specimens form a family. They stay where they are. You can leave one, walk around another and come back to the first without losing the comparison.

Beside the cube, each of those two triangles has drawn inward. The top is still flat. A mint-coloured border occupies the space between each smaller triangle and its old edges. Nothing has been cut out of the cube. The operation has replaced each selected triangle with a smaller one and the triangles needed to connect it to the boundary.

The third specimen lifts the two inner triangles. New side faces join their raised edges to the surface below. Walk around it. What looked like a square lid has become two separate projections. The diagonal was more than a line drawn on a surface: it helped decide what the operation could take hold of.

![The cube, the inset faces and the first extrusion, built by the museum's mesh grammar.](/book-review/doc/book/iterations/2026-09-24-form-grammar-spine/first-three.png)

*One seed, then two operations. Pink marks the faces that receive the next operation; mint marks the inset borders. These colours help us follow the construction.*

In the tree room, a rule replaced letters before a turtle read them as movement. Here a rule selects faces and changes the mesh itself. The inset moves each corner towards its triangle's centre. The extrusion moves the smaller triangle forty centimetres along its outward normal, adding walls behind it. A normal is the direction perpendicular to that face; on these two faces it points up.

The fourth specimen repeats that pair of operations three times. Only the new tips continue. The shoulders stay behind. Follow one projection down towards the cube and find the earlier stages in its steps. Repetition has kept a history in the surface.

Next to it, a wider pair rises to the same height. Both took three steps of forty centimetres. The difference is how far each inset draws the corners towards their centre: eight per cent here, twenty-eight beside it. One changed value is enough to alter the space between the tips. These are choices we can save and return to. In the project's DNA systems, such values help describe a family of possible bodies.

The sixth specimen reaches sideways and down as well as up. Its seed is the same cube. The inset amount and number of rounds return to the fourth specimen's values. This time all twelve starting triangles are selected. Each keeps a line of descendants; the new tips continue while their side walls remain. Walk around to find the projections hidden from the entrance.

![Three rounds with two inset amounts, followed by the same operations starting on all twelve faces.](/book-review/doc/book/iterations/2026-09-24-form-grammar-spine/three-families.png)

*The specimens keep the same metre scale. Their lowest points rest above the plinths, so the last cube's centre sits higher to make room for its downward growth.*

Changing the amount gave us another member of a family. Changing the selection changed where that family could go. Neither choice asks for a hole through the centre, a bridge joining the tips or a soft surface between them. The two operations in this study cannot make those requests. More repetition will not supply a missing operation.

There is still room for surprise. A familiar cube has become a stepped pair, then a body whose projections hide one another as you move. We can enjoy that discovery and ask for something its recipe cannot yet say. The next experiment begins where we can name that missing possibility.


Further on, one triangle has left the cube. The pink face rests on a narrow stem. Its diagonal edge now meets the air. The other triangle has been left out so that we can see what happens to this one.

Beside it, six curved strips spread from the face's centre. Their tips lift; spaces remain between them. The triangle is still there, beneath their meeting point. Inset and extrusion have given way to another operation, called petal splay. The new name brings a resemblance with it. Stay with one strip long enough to see how it was made.

Its direction changes along its length, and its width narrows towards the tip. The builder samples that path in sixteen sections and joins the edges with triangles. No noise has been added. The curve follows a chosen rule. Up close, its changes of angle remain visible in the light.

![One retained triangle beside the curved strips added to it.](/book-review/doc/book/iterations/2026-09-24-form-grammar-canopy/face-and-petals.png)

*The seed face and the small petal study. The large version waits beyond them. All three use the same added support design.*

Earlier, extrusion connected a lifted face to the edges it left below, making side walls. These strips have open edges. Follow one towards its tip, then look past it. Colour ends; the rest of the room continues. The renderer lets us see both sides of each strip. It has not filled a volume between them.

The last construction is the same surface, four times larger. Every generated point has kept its relation to the others. The support has been enlarged with it. Where the small surface begins ninety centimetres above the floor, this one begins at three metres sixty.

Walk beneath it.

A moment ago we could look down into the arrangement. Now it occupies the sky above us. The pink triangle spreads over the column, while the curved strips rise beyond its edges. Walk towards a gap. One surface passes out of your view and another enters it. The form stays still; your movement changes what covers you.

![The same generated surface seen from beneath at a camera height of 1.7 metres.](/book-review/doc/book/iterations/2026-09-24-form-grammar-canopy/beneath.png)

*The same vertices, enlarged uniformly by four. The camera is now below the surface. Its gaps remain open.*

The stem was added separately. The rule that drew the strips supplied neither a column nor a floor to stand on. Those decisions allow this encounter, and they can be changed too. Recognising something like a flower did not settle how a body would approach it. Enlarging it made that question harder to overlook.

There is pleasure in the change of address: a form small enough to inspect has become a place beneath which to pause. It has also kept its limits. More petals might hide a gap from one viewpoint; a continuous enclosure would require us to join the boundaries. What should remain open is now a question we can ask from inside the arrangement.

These forms did not settle under weight. The gallery holds them fixed. Form Finding asked which arrangements could hold and which would count as a result. Here we have made the construction explicit, before adding any judgement of success. Later, Genetic Evolution will let a score choose among described bodies. We will be able to ask both what its builder can make and what its evaluator notices.


Next, Assemblage gives us two diagonal marks and a field of separate choices. We will recognise paths in their arrangement. A rule can leave more to see than it was asked to represent.

---

## Assemblage Same Desire

*Assemblage_Same_Desire*

### Two marks, many paths


When you see a path in this textile, who connected its pieces?

Choose several neighbouring diagonals and follow the line your eye makes through them. At a fork, notice which continuation you choose. Read the same area from the other end. The marks have stayed still; your route through them may change.

Living gave us a witness that could stay while a design changed. Press HOLD here. A second sheet keeps the current marks beside the one we can edit. Now press ALPHABET.

The diagonals become horizontal and vertical bars. Keep looking at the same small group of cells. Has its path survived? Press ALPHABET again. One outcome becomes a large block, the other a small block. What looked like a route may now look like a density, an enclosure or a scattered set of objects.

The choices have not been made again. Each of the sheet's 144 cells still holds the same random sample. The same threshold still selects its outcome. We changed what that outcome draws.

The original diagonal alphabet gives its bar one of two rotations:

```gdscript
bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
```

PI radians is half a turn; a quarter of PI is forty-five degrees. The sign chooses which way the bar leans. The other alphabet uses zero and half of PI, producing a horizontal or vertical bar. The stored choice can pass through either interpretation. Its address in the array does not move. The textile is named for a one-line Commodore 64 program, `10 PRINT CHR$(205.5+RND(1)); : GOTO 10`, which printed exactly this coin-flip between two diagonals down the screen.[^Assemblage_Same_Desire--tenprint]

The grammar rooms taught us to distinguish a sentence from the turtle that reads it. Here we hold a record of choices and give it another set of marks. A picture can change substantially while the decisions remain intact. That does not make its appearance incidental: the marks give us different relations to follow.

Return to the diagonals. Try ODDS. The next setting is 0.75. Some blue marks become warm ones. This time the decisions changed, although the samples did not.

Each new cell originally receives a sample and compares it with the threshold:

```gdscript
var sample := _rng.randf()
var slash := sample < odds
```

ODDS reuses that recorded sample. A value between 0.5 and 0.75 changes sides when the threshold moves from one to the other. A value below 0.5 was already admitted. The screen counts how many cells choose A; a threshold of 0.5 does not require exactly half of a small sheet to choose it.

The difference is now precise. ALPHABET changes the marks while holding the decisions. ODDS changes the decisions while holding the samples. SEED supplies another reproducible set of samples. HOLD lets one resulting sheet remain beside these experiments. RESET returns the editable sheet to its opening state.

Press STEP. The oldest row leaves the bottom; a new row enters at the top. The other eleven rows keep their samples and shift down. The small automatic textile behind the study runs this operation over time. A finite window lets us watch an ongoing process without keeping every mark it has produced. The discarded row may matter to a route we were following. It is no longer in this window.

Walk onto the pattern beyond the desk. The same choices have been drawn across the floor. Follow a diagonal, then cross it. The floor supports both movements. Changing the marks changes what the surface invites you to follow; it does not cut a passage or raise a wall. No collision boundary follows these lines.

That distinction gives us a next experiment we have not built: let a mark become a barrier, then test whether the same array remains traversable. We would need to decide what counts as a connection, construct its collision and check a route. A maze-like image has done none of those things for us.

The paths can be real features of the image without being planned routes. Your reading and the generator's operation are different contributions to the encounter. The pleasure of finding a way through need not disappear when we learn how little the generator knew about it. We gain a place to intervene: in the choices, the marks, their connections, or the body that will approach them.


Stay with the rest of the room. The working loom computes which thread lies above another from a draft; its crossings depend on several related tables. The pattern galleries retain their maker names, including the gallery dedicated to Kristina Torsson. These are other procedures and histories beside the two-mark textile. Sharing a computational medium does not make them interchangeable.

The plaque and tilted scale invite a question about formal limits. Their presence does not turn this textile into a proof of incompleteness. The room can bring practices into conversation while leaving their differences available for study. The same desire is a question we carry between them: what can this way of making open, and where must we learn another way?

Next, generated forms will be compared using a numerical score. The cube family kept all six of its results, and here a path could matter because we chose to follow it. What changes when a program is asked to decide which result should continue?

[^Assemblage_Same_Desire--tenprint]: Nick Montfort and nine co-authors, *10 PRINT CHR$(205.5+RND(1)); : GOTO 10* (MIT Press, 2012), a book about that one line. The two diagonals are PETSCII characters 205 and 206; RND decides which.

---
