# L-systems — complete reflective sequence

Eight halls in canonical spine order. Current source texts collected on 9 October 2026. See REVIEW.md and evidence.html for the scope of the accompanying checks.


---

<!-- hall: LSystems_Grammar_Lab -->

# The same sentence, another body

<!-- @lsystem_editor -->

Two upright lines meet us. Below each, the same letter: F. Can one sentence have two bodies?

Advance the live drawing once and hold a copy. Then take the small black point and change the angle. Follow the first bend across the two drawings. Their letters have not changed. Each still carries five drawing instructions, yet the same route through the symbols takes another route through space. Some segments overlap. The outline alone cannot tell us how many movements made it.

We brought a construction out of the fractal halls. Here a rule leaves a description we can keep before giving it a body. Making the sentence and reading it as movement become separate acts. The held drawing gives us somewhere to look back while the live one changes. The point has acquired another task in the hand.

Advance again. More letters appear; the held drawing stays. Each F has become a short sequence of movements and turns. The new letters wait for the next generation before they too can be replaced. A small loop has a rhythm, and a place where its repetition must stop.

The turtle carries a position and an orientation through those instructions. Looking at a line does not reveal everything it had to keep in order to draw the next one.

Choose the PLANT preset. An X appears, with no line above the plinth. We met an invisible point in Point One. This absence has a different cause: X belongs to the rewriting rules, but this reader gives it no drawing action. Advance once. Drawing instructions appear around the Xs. What was undrawn could still contribute to the next sentence.

Look again at the two outlines. Each is fitted to its display. More instructions need not make a taller body here. That apparent continuity of size is another operation, performed after the turtle has travelled. We receive a composed result: a rule, a reading, thickness and light. Even the size of the place offered to it has entered what we see.

The desk also has a limit. When another complete generation would exceed its symbol budget, the previous one remains. The readout tells us where construction stopped. A long sentence may be abbreviated on the label too. One limit changes what was made; the other changes how much of its record we can see.

Eight presets give us places to begin. Cantor carries the thirds from the previous hall into letters: one leaves a line, another crosses a gap without leaving one. These presets are a selection from what we could write. The desire for another body may lead us to change the rule; the desire to inhabit it asks for more than these thin, non-colliding drawings provide.

<!-- @ -->

The earlier trees, string study and city grammar remain beyond the desk. Three trees grown from three traditions’ axioms ask whose grammar a rule is. Resemblance invites comparison without establishing a shared procedure. Carry the bracket into Growth: what must a branch remember so that another branch can begin?


---

<!-- hall: LSystems_Growth -->

# What a branch remembers

<!-- @parametric_lsystem -->

A short upright line, a pale point at its tip. Beside it, a second reading waits. We have brought the turtle out of Grammar Lab. There, we changed the angle of a sentence. Here we follow what it carries from one instruction to the next.

The sentence is already written:

```text
F[+F]F[-F]F
```

Its rule comes from a small family in Prusinkiewicz and Lindenmayer’s *The Algorithmic Beauty of Plants*.[^2-final-abop] The first F has drawn a line. What must the turtle keep if it is to leave the trunk, make a branch, and find its way back?

The dark sphere is our handle; the pale point records where the drawing has arrived. Step to the opening bracket. Nothing extends. The readout says SAVE. A state has been kept, and the next stride has shortened, although the point has not moved. An operation has taken place without adding anything to the outline.

Continue through the turn and the shorter branch. Hold this reading before its closing bracket. The witness keeps its pale point at the branch end.

Where will the live point go?

It returns to the fork. The branch remains, with no return line joining its tip to the trunk. The next F continues upward from the saved place. The branch's turn and shorter stride have not become the trunk's next instructions.

A branch may contain another branch. The most recent departure must be recovered first. Position returns with direction and stride; restoring only the place would leave the turtle facing somewhere else. What it can recover depends on what was saved.

A return can preserve what happened during a departure while allowing something else to continue. The drawing does not have to erase its branch to resume its trunk.

Keep a complete reading, then change the branch ratio. At one, a branch takes the same stride as its parent. Above one, it becomes longer. The sentence and turns stay fixed, and both drawings use metres. Neither is squeezed to fit its plinth.

The code calls the value length_decay. Its name suggested shortening. The multiplication permits something else. Which proportion made this drawing look like a proper tree to us?

Read another generation. The unshortened trunk reaches above us; a branch within a branch applies the ratio again. The earlier drawing stays beside it. We can follow the local decision and still be surprised by the room it begins to occupy.

The stack offers a dependable return for the state its programmer chose to save. It contains no sunlight, weight or account of a neighbouring body. These branches have no collision surfaces. Resemblance has brought us to the idea of a tree; support, shelter and obstruction would ask for further work.

<!-- @ -->

The animated tree, obstacle-querying tree, earlier L-system tree and cypress remain beyond the desk. They approach growth through other operations. Carry the saved state forward. In the next hall, even forward may be read sideways.

[^2-final-abop]: Przemyslaw Prusinkiewicz and Aristid Lindenmayer, *The Algorithmic Beauty of Plants* (Springer, 1990), figure 1.24: F[+F]F[−F]F is its (a), Competition’s F[+F]F[−F][F] its (b), and the believing turtle’s FF+[+F−F−F]−[−F+F+F] and Grammar Lab’s PLANT preset are its (c) and (f) with the turns mirrored.


---

<!-- hall: LSystems_Grammars_And_Curves -->

# When forward goes sideways

<!-- @the_believing_turtle -->

Does an instruction say how it must be obeyed?

Three short lines rise from three origins. Each has read the first F of the same sentence, with the same stride. We have kept the travelling state from Growth. Now we ask what agreement connects an instruction to a movement.

Take the familiar dark point and press its trigger. The blue line goes sideways. Its gold arrow still points up; its white arrow points across. The stored heading and the direction of drawing no longer agree.

This reader exchanges the heading's x and y components before it moves. What contributed to height now contributes to horizontal distance. The sentence stays the same. We catch the disagreement in one step, before it becomes a tree.

Change the middle reader's angle. Its first line stays upright. Has the change failed? Continue until a turn is followed by another F. The middle drawing departs from the green reference. An angle matters when an instruction uses it.

Finish the sentence, finding corresponding forks as you go. The brackets restore saved positions and headings, as they did in Growth. One drawing spreads differently; another seems to have forgotten which way a tree should stand.

Try to match every blue fork to a green one. With the same angle, exchanging x and y reflects the whole construction across the diagonal x = y, relative to its origin. Lengths and angles survive, and the same branches connect. Our expectation of uprightness has been overturned while these relations remain.

![The green and blue readings of the same sentence, reflected across the diagonal x = y](assets/reference-c86e0a220522.png)

*The same sentence and stride, with a counterpart for every fork. Follow an off-axis branch: this reflection differs from a quarter turn.*

Return the blue reader to forward. Its arrangement agrees with the reference again. The strangeness has an operation we can inspect and undo. Read another generation and find the first fork before trying to recognise the whole outline. More detail can obscure a relation we understood one step earlier.

Calling it a believing turtle directs our attention to its commitments. It does not give the turtle an inner conviction. F acquires its consequence through a particular assignment in the code. We can change that assignment and ask what the change preserves.

<!-- @ -->

<!-- study-spine:tube_painting -->

<!-- @tube_painting -->

Further into the room, someone has already begun. Three bent lines hang before a pale wall. Their ends are within reach. Take one and continue it.

The inherited part stays where it was. Your hand adds to its end. Release: the new length remains, carrying the turn you just made. There is a pen for starting elsewhere, but beginning again is no longer the only invitation.

Let the skin disappear into paths and rings, then return. What looked like one flowing body keeps a count of the decisions that made it. These lines do not sag. The wall offers somewhere to meet; it is not a support they need. An unfinished thing can remain suspended.

Bring an end to another run. A marker offers a joint; releasing records the connection. A crossing alone does not make one. Beside the drawing, a plugged cord gives a motor permission to move. Unplug it and the coloured bodies keep their last pose while the separately connected sound can continue. Here the ends carry an agreement as well as a shape.

Look up. Pink pipes pass over and under one another. A change at the console makes the weave become ribs, then returning loops. The line has acquired the scale of a ceiling. We are standing beneath one of its arrangements.

<!-- @ -->

The tube bay is another encounter with a path, available beyond the main lesson. The finite floor curves and volumetric path also remain in the collection. In Architecture, the desire to inhabit a drawing becomes more demanding: a step acquires width, and a body will test where it can go.


---

<!-- hall: LSystems_Architecture -->

# When a line acquires walls

<!-- @lsystem_dungeon -->

Can a line admit you?

Four pale segments lie on the floor. One leads to a junction; two turn away from it; the fourth continues ahead. Your eyes can follow them. Your feet can also ignore them. There is no wall asking you to choose.

Build the plan. A low solid base and glass rise along its boundary. Enter beside the desk, take a side branch and come back. The junction is open. The branch ends against a wall. The straight continuation has another opening. Someone had to decide how these paths would end.

We brought the turtle's saved place and direction from Growth. Curves changed how it read forward. Here we keep a reading and ask what must be added around it. The familiar dark point switches between plan and construction; moving it chooses a passage width.

The sentence contains two room markers. Find the places they name. Each branch begins at the same saved junction, and each marker records that place before the turtle moves. Two instructions have led to one address. Counting the records did not tell us how many rooms we would find.

Add their footprint. The junction spreads into a square. Enter again and step away from its centreline. There is somewhere to pause while another route continues through. We gave a spatial use to the mark. It did not already contain a gathering, a cupboard or a private retreat.

Where footprints overlap, the builder keeps shared floor cells once. An edge between occupied cells receives no wall. That small refusal keeps the junction open. At the outer boundary, walls appear except where entrances were chosen. The sentence supplied records; a further decision made them into an enclosure.

Leave the frame and narrow the passages. The centrelines stay fixed. At forty centimetres, the entrance stops a test body sixty centimetres across. Its route remains connected in the drawing. The body's boundary meets two walls whose distance the line alone did not show.

Try the wider version. What has changed is the space available to this body. Another body may require another opening. Adding more branches would not answer the question that width made concrete.

The controls refuse to rebuild while a visitor remains inside the frame. The person at the desk cannot silently change these walls around someone else. That agreement was written too. We can imagine other ways to ask whether a change may proceed.

Return to the flat plan and cross its lines freely. Behind the study, the original miniature dungeon rests on a plinth. Its more elaborate grammar fits into a small display. Look down at it with the narrow entrance still in mind. A plan can be legible to an eye long before it is usable by a body.

<!-- @ -->

The orthogonal structure, folded dragon path, seed and mesh studies offer further readings. Near the seed, a hatch offers a crystal; lifting it later calls walking bodies from a vent, an encounter another chapter will follow. Next, Competition gives a rule surroundings that change before it gets another turn.


---

<!-- hall: LSystems_Competition -->

# Who gets the first turn?

<!-- @ForestCompetition -->

Two stems wait above a tiled field. One is amber, one blue. Both begin with F and the same rule. Their colours let us follow them; colour gives neither a different appetite.

Hold the black point and give each tree a turn. A receives 2.250, B 1.980. These are the model's resource values, not measured quantities of food. Both stems have begun to branch.

Is something wrong with B's instructions?

Start again with B first. The original soil and stems return. Now B receives the larger amount. Nothing in the branching sentence had to change.

Architecture separated a plan from the boundary that lets a body pass. Here we separate a rewriting rule from the conditions that let it run. Each tree takes a fraction of the soil values near its root. Their patches overlap. The second arrives at a place partly used by the first. Its instructions are intact; its starting world is already different.

The branching displays stand apart so we can inspect them. The roots remain close together on the field. Follow their coloured squares back to the soil before mistaking the distance between the exhibits for distance in the calculation.

Begin again in winter. Give each tree a turn. The soil drops, but the stems do not branch.

Only after consuming does the forest ask whether the season permits a rewrite. Winter refuses it without undoing what was taken. A body can remain visibly still while changing its surroundings. A picture of the crown alone would have concealed that activity.

Advance the soil without giving either tree a turn. Diffusion and replenishment change the field. The desk lets us separate these events; the larger forest behind it runs them together over time. What looked like one process can be opened into decisions with different consequences.

The study also stops rewriting after its chosen generation limit. That ending does not establish that the trees have matured, exhausted their world or found an ideal form. We have supplied a stopping condition. The soil can still change.

Which differences came from the instructions, which from resources, and which from whose turn came first? Execution order is easy to overlook among the branches. It helps distribute a possibility of growth.

We could rotate the first turn after each round, or calculate both requests before altering the shared field. Those would be further experiments. Calling this arrangement natural would close the question before we had tried them.

<!-- @ -->

Stay with the retained coral for a moment. Its branching form follows another recipe and takes nothing from this soil. Similar-looking bodies need not inhabit the same relations. In Living, we turn towards the controls through which we author a body, and the changes those controls make available.


---

<!-- hall: LSystems_Living -->

# What counts as a change?

<!-- @genetic_tree_sculptor -->

The tree waits above a low plinth. Hold a copy beside it. One design can change; the other becomes a witness.

Competition kept the grammar fixed while conditions changed. Here we reach towards the values from which instructions are made. Depth begins at 4.000. Increase it. The number moves. Look at the branches.

Again. By 4.800, the number has changed four times, but the tree still agrees with its witness. Is the control doing anything?

At 5.000, another generation appears.

The generator halves the raw value, rounds it to a whole number and keeps the result within a chosen range. Several settings become the same rewriting count. A generation needs to be a count; the continuous gesture must pass through that decision. The number we moved and the instruction received are different records.

The data structure is called DNA. Here that name describes parameters used to construct a body. It does not establish that the specimen is alive. Those values help produce a sentence, and the turtle reads it through the movements and returns we have learned.

Select Angle and move the dark point. Now a small change turns the branches without adding a generation. The hand meets a similar control, but the body changes differently. The appearance of an interface cannot tell us what kind of change it offers.

Plant a copy on the floor pad. Edit again. The planted tree stays, as does the witness beside the live one. We can walk between an earlier choice and the one we are making now.

That steadiness had to be written. The export once referred to the same editable design: later movement could alter what another part of the program received. It now keeps an independent copy at the moment of the press. Preserving a decision requires more than giving it another name.

The local planted specimen is separate from Competition's soil. An older catalyst uses exported DNA differently, making temporary trees it may mutate and rescale. A form carried elsewhere meets another procedure; keeping a recipe does not settle every future use of it.

The side rack offers eight sliders and a random choice. Even together, they open only part of the program. None requests a branch joined back to an earlier branch, a new alphabet, or another relation to the ground.

Push Depth and Forks towards their upper limits. The requested command count can exceed what this preview draws. Its readout declares the budget. A crown that looks finished may be the place where drawing stopped.

There is pleasure in finding a body among these variations. Stay too with the desired variation for which no control exists. Naming it gives us somewhere specific to continue writing.

<!-- @ -->

The tree, coral and paper studies remain among the authored platforms. Next, the cube returns. We will carry the question of replacement beyond sentences: a rule will select faces and change the mesh itself. The objects receiving the operation will change; we can still ask what continues and what stays behind.


---

<!-- hall: LSystems_Shape_Grammars -->

# A family the cube can become

<!-- @form_grammar_family -->

The cube has returned, small enough to look down on. A dark diagonal crosses its pink top. We met that division in Primitives: the square the eye gathers is two triangles in the mesh.

Until now, replacement acted on letters before a turtle read them. Here it acts on faces. We leave string rewriting behind while keeping the question of what receives the next operation.

Six specimens form a family. They stay where they are. You can walk around one and return to another without losing the comparison.

Beside the cube, each top triangle has drawn inward towards its centre. Mint borders join the smaller triangles to their old edges. The top remains flat. The next specimen lifts those inner faces and adds walls beneath them. Walk around it: what looked like one square lid has become two projections. The diagonal helped decide what the operation could take hold of.

![The cube, inset faces and first extrusion, built by the museum's mesh grammar](assets/reference-41824323310a.png)

*Pink marks the faces that receive the next operation; mint marks the inset borders.*

Further along, the pair of operations repeats. Only the new tips continue. Their shoulders stay behind. A tag follows those tips as their addresses in the face list change. Being next in the list is not what makes a face next in the construction.

Follow one projection down to the cube. Earlier steps remain in its surface. Beside it, a wider pair rises to the same height. The number of extensions stayed fixed; each inward movement became smaller. Another specimen begins on all twelve triangles, reaching sideways and down as well as up. Walk around to find the projections hidden from the entrance.

![Repeated operations with different inset amounts and starting faces](assets/reference-23f8799e4401.png)

*All use the same metre scale. Their lowest points sit above their plinths.*

Changing the amount gave another member of a family. Changing the selection changed where that family could go. Neither supplies a hole through the centre or a bridge joining the tips. Repetition cannot provide an operation that the recipe lacks.

<!-- @form_grammar_canopy -->

Further on, one triangle has left the cube. It rests on a narrow stem, its diagonal edge against the air.

Beside it, curved strips spread from the face's centre. Their tips lift and narrow; spaces remain between them. A different builder has entered. Its name, petal splay, brings a resemblance with it. Follow one strip closely enough to see the sampled turns in its surface.

![One retained triangle beside the curved strips added to it](assets/reference-d12d3ba291fc.png)

*A seed face and a small petal study. Their supports were added separately.*

Extrusion made walls behind a raised face. These strips have open edges. The renderer shows both sides, but it has filled no volume between them.

The last construction is the same surface, four times larger, with its support enlarged too.

Walk beneath it.

A moment ago we could look down into the arrangement. Now it occupies the sky above us. Move towards a gap. One strip passes out of view and another covers you. The form stays still; your movement changes what it offers.

![The enlarged surface seen from beneath at a camera height of 1.7 metres](assets/reference-9b2499733221.png)

*The same vertices, enlarged uniformly by four. The gaps remain open.*

The rule supplied neither the stem nor a floor to stand on. Those decisions allow this encounter. Recognising something like a flower did not settle how a body would approach it. Scale made that question harder to overlook.

These forms did not settle under weight; the gallery holds them fixed. We can enjoy what the construction permits before asking a score to choose among its results. In Assemblage, two marks will offer paths no generator has selected for us. The act of reading will enter the relation again.

<!-- @ -->


---

<!-- hall: Assemblage_Same_Desire -->

# Two marks, many paths

<!-- @ten_print_textile -->

When you see a path in this textile, who connected its pieces?

Follow several neighbouring diagonals. At a fork, notice which continuation you choose. Read the same area from the other end. The marks stay still; your route through them may change.

Hold a witness, then change the alphabet. The diagonals become horizontal and vertical bars. Has the path survived? Change again. Large and small blocks take their places. A route may begin to look like density, enclosure or scattered objects.

Each cell keeps its random sample and the decision made from it. We changed what that decision draws.

The textile takes its name from a one-line Commodore 64 program that chose between two diagonal characters.[^8-final-tenprint] Here the choices remain available for another reading. In the grammar rooms, we separated a sentence from the turtle that interpreted it. There is no L-system rewriting these rows. The distinction travels: a retained record can acquire another appearance.

That does not make appearance incidental. The marks give us different relations to follow.

Return to diagonals and increase the odds. Some marks change sides. Now the decision has changed, although the underlying samples stay. A sample falls on one side or the other of the threshold we set. A halfway threshold does not require exactly half this small sheet to choose each outcome.

We can intervene at several places. Another seed supplies another set of samples. Another threshold changes which outcome they select. Another alphabet changes what the outcomes draw. The witness must keep those choices and its alphabet, or the old result could return wearing new marks.

Advance one row. The oldest leaves the bottom; another enters at the top. The surviving rows keep their samples as their addresses move. The smaller textile behind the study does this continuously. Its finite window lets us watch an ongoing process. A discarded row may have mattered to the route we were following.

Walk onto the pattern beyond the desk. Follow a diagonal, then cross it. The museum floor supports both movements. The marks invite a route without raising a wall along it. Architecture made that further decision explicit. Turning this pattern into a maze would require us to build boundaries and test its passages.

The paths are features we can find in the image even though the generator planned no route. Learning how the choices were made need not remove the pleasure of finding a way through. It gives us more places to intervene, including connections the present program never records.

<!-- @ -->

Stay with the rest of the room. The working loom determines which thread lies above another through related tables. The pattern galleries retain their maker names, including Kristina Torsson. These procedures and histories remain distinct beside the two-mark textile. The plaque and tilted scale also invite a question about formal limits; this pattern supplies no proof of incompleteness.

We began with a sentence and opened the decisions between a rule and a body. Now the viewer has found something the construction was never asked to represent. What can this way of making open, and where must we learn another way?

In the next sequence, a numerical score will compare generated forms. The cube gallery kept all six specimens. Here a path could matter because we chose to follow it. What changes when a program decides which result should continue?

[^8-final-tenprint]: Nick Montfort and nine co-authors, *10 PRINT CHR$(205.5+RND(1)); : GOTO 10* (MIT Press, 2012), a book about that one line. The two diagonals are PETSCII characters 205 and 206; RND decides which.

