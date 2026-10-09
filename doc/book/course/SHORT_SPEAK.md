# Short-speak and type-safe text

## Encounter-led progression, 3 October 2026

Teach a programming concept when the current encounter gives the learner a reason to use it. Point introduces variables through a position; Trace introduces an ordered one-dimensional list of positions and a for loop over that list. Later arrays and tiling chapters develop those skills rather than introduce them from nothing. Use Learning Processing and The Nature of Code as teaching references, with the Ada spine as the route.

tutorial.md teaches how to construct, change and inspect the encounter. final.md follows its critical, poetic and associative questions. They share artifacts and accurate claims, but need not carry the same explanations, pace or code. Adding a programming concept to a tutorial does not require adding it to final.md.

This supersedes the 2 October suggestion to leave Trace’s list entirely supplied, and the fixed allocation “loops first in Array, arrays first in Tiling.” Keep the movement and drawing infrastructure supplied; teach the short ordered list and its `for` traversal in Trace itself. Point Zero attends to ready/process; Point explains variables in a concrete construction. An early counter can preview a variable without carrying the full explanation.

Continue one tutorial at a time. The sketch and scaffold record this new progression; the written functional draft, its type declarations and runnable studies must be updated together when each lesson is rewritten. Do not silently change final.md to carry tutorial explanations.


## Spine-first correction, 2 October 2026

Use the current spine and each map’s tutorial.md as the scaffold. Programming prerequisites guide the size of each step, not a competing route. Record local exceptions: introduce one essential operation earlier, borrow an explicit component, or return to its implementation later. A reflective hall need not introduce a new coding feature.

The canonical source index and the first chapter's map-by-map decisions are in [sketch/SPINE_SCAFFOLD.md](sketch/SPINE_SCAFFOLD.md). All twelve Primitives tutorials exist. The 25 chapter order already matches the spine; the current chapter-internal draft does not yet. Start the next prose pilot with Point Zero (`_ready`, `_process`, counter), then Point One (code-created visible and solid marker), then Coordinates. Do not treat the earlier sphere-first draft as the final route or rewrite every lesson at once.


The form every lesson of the Godot course is written in. Agreed with Palle on 2 October 2026:
"a compressed poetic technical form", a little less poetic than the first draft.

## Short-speak

- Lines, not paragraphs. One claim per line.
- Lines are grouped by meaning: numbered steps for doing, a bullet tree for understanding. See "Lines in a tree", below.
- A line is short: aim for seven words, rarely more than ten.
- Three kinds of line, in this order when they occur: what to do, what you see, why it is so.
- Code first, then the lines about it. A section is one idea, one picture, the code, a few lines.
- Parallel lines may repeat with one change ("Give it a mesh: it shows." / "Give it a shape: it stops things."). That is the only ornament.
- A section ends on its technical point, not on an image.
- No filler: just, simply, now, basically, actually, note that, we will, let's, in order to.
- No hedging. A measured scope stays, as one plain line: "in our run", "from one seed", "in the editor, not the running game". Long measurement reports and "not checked" lists go to the README or the teacher notes.
- A decision says who made it: "we chose a tenth", not "a tenth is the threshold".
- Second person, present tense.

## Lines in a tree

Palle, 2 October 2026: "can we make it even more readable by indented point list the we can group related hieratical meaning?"
The lines stay short-speak. What changes is that they are grouped.

- **Numbered steps are for doing.** Two or more doing lines in a row: setup and admin calls, in the order the student does them. A step is an instruction.
- **A lone doing line stays plain.** "1." promises a "2.". One step alone is a plain line, unless it has children ("Add `walker.tscn` to the root node." in 2.5 keeps its number, for the two lines under it).
- **The run line stays plain, right under the code.** "Run the project: the cube rises." is a lone doing line, and what it shows follows its colon. The tree that explains the run comes after it. Where the script is put on a node after the code is written (chapter 18), the run is the last of those numbered steps.
- **A bullet tree is for understanding.** What you see, and why it is so.
- **A child explains its parent.** Indented under a bullet or a step, it says what the parent means, why, how much, or what to put back. If you cannot say which of these it does, it is a sibling.
- **Siblings are parallel.** Lines at one level stand side by side, so the parallel line, the one ornament, shows.
- **An experiment is a bullet.** "Change `speed * delta` to `speed`: the cube shoots away." Its children give the reason and end with `Restore:`. An experiment of two doing lines is two numbered steps.
- **Two levels at most.** A bullet and its children. Indentation never means emphasis.
- **The lead and the point stay plain.** The lead is the section's first claim, one or two lines; the point is its last line. A section reads lead, steps, code, tree, point; one whose script is put on a node after it is written reads lead, code, steps, tree, point.
- **The tree comes after the code.** Code first, then the lines about it. A lead runs past two lines only for what the steps or the code need first, and stays plain.
- **A section may open on its steps.** A step is no claim, so a section that begins with setup has no lead before it. It never opens on a bullet.
- **An admin definition stays plain.** Its bold line, and the steps of its def, stand unnumbered, a blank line apart from the lead: the definition is said once, as the taxonomy has it. The steps that use it follow, numbered.
- **An algorithm may be numbered.** "Marching cubes means six steps in every cell:" and then its steps, 1 to 6: an algorithm's order is its content.
- **The rest keeps its form.** Figures, example captions, code, the Why box, What it hides, the exercises and the Types box. Code stays outside lists. A caption sits on its code: the steps come before it.
- **One item, one line, one sentence.** A line right under an item, indented or not, joins that item in Markdown. So a blank line comes before the plain line after a list, and none inside a list.
- **A blank line does not split a tree.** Markdown reads two lists of one kind, a blank line apart, as one loose list. Group lines under parents instead; only a plain line parts two lists.
- **A child sits at its parent's content offset.** Two spaces under `- `, three under `1. `.
- **A short section may need no tree.** Lines alone still pass.
- **Grouping changes no content.** No claim is cut. None is added, except a parent that says what a group is about.

Refined the same day, after three structure reviews and a reading for harm of chapters 1 to 5 and 18.
The run line was a bullet in 2.1 and plain in 2.2 to 2.8: it is plain everywhere now, since a section may not open on a bullet.
A lone step reads as a promise of a second one: it is plain now.
Step 3 of 2.1 had merged two lines into one: they are back as they were, the first a child of step 2.

## Making the objects

Create the teaching nodes and their primitive meshes in code. Do not require editor-made Point, Cube or other mesh nodes or access them with dollar-sign paths. The starter supplies the room, camera and light. Additional supplied parts must be named explicitly; they are not prerequisites silently hidden in a scene.

Replace the example script between runs. Objects it creates exist in the running scene; stopping it removes them. Do not ask the learner to delete those runtime meshes from the editor.

The opening lesson creates one sphere. Give the learner a working result before expanding the terminology. Keep the six-part, 25-chapter order in `sketch/sketch.json`. Built-in classes and `_ready()` are used from the opening; writing reusable functions and a class is developed in Colour, chapter 4.

This changes the construction method across the written examples. Continue reviewing the language one lesson at a time.

## Type-safe text

- A term that matters is a type. It is declared once, where it is first needed, and listed in the chapter's **Types** box.
- A declared term keeps one meaning for the whole book and is never replaced by a synonym. If *shape* is what is touched, it is never called a collider, a boundary or a hitbox elsewhere.
- A term is used only after it is declared.
- Names from the code appear exactly as the code spells them, in code style. The text never names something the code does not have.
- A word the student already knows from everyday language stays everyday; only words that carry a technical meaning in this course are types.

## Admin is said once

Admin is the scaffolding around the teaching: running the project, adding a node, making a new script.
Agreed with Palle on 2 October 2026: "how to run the project can be described once. after that we can just say run the project."

- An admin procedure is described once, where it is first needed: its name in bold, then its steps.
- After that the text says only its name, as a step line. The page links the name back to the steps.
- Its other wordings and its steps never come back: not "press Play", not "F5", not "at the top right".
- Teaching is never replaced by a call or a link. It stays written out where it is taught, and later lines use its terms unlinked.
- The test, from Palle: if the step were done for the student, would they still learn what the section teaches? Then it is admin. If not, it is teaching.
- A call is an instruction to the student. A sentence about what code does is teaching: "code can add a node" teaches `add_child`, is no call, and gets no link.
- One procedure, one name. Running the open scene alone (F6) is not running the project (F5): it gets its own name when a section first needs it.

```markdown
**Run the project**: press Play, at the top right.
If Godot asks for a main scene, choose Select Current.
```

and in every later section, and every later chapter:

```markdown
Run the project: the number climbs.
```

"Add a `Node3D` named `Here`: a position, nothing else." calls *add a node*. Its steps (the + button, the name) are admin; which node, and why, is the lesson, and stays in the line.

## What compression keeps

Measured on 2 October 2026 by two rounds of compress, unfold, compare (`functional_text/round_trip/REPORT.md`).
Readers had the lesson open and, in half the cells, the course before it; blind judges scored understanding, not likeness to the original.

- **How short.** A lesson rewritten in this form lands at about half the old prose when the lesson is short, and at 35–45 % when it is long. Half and a third lost no understanding the test could see. Code is shown whole where it is needed and is not counted.
- **No extra markup.** No arrows, no `enters:`, no `from:`, no provenance tags. Round one proposed eleven such devices; they cost 11–36 % more words and moved no score, and the ones a page did not declare stalled the reader. The text's devices are the ones FUNCTIONAL_TEXT names, and no others.
- **Two devices stay.** After an experiment that changes the code, one `Restore:` line says how to put it back. A file is shown whole the first time it is met, and wherever the student is told to stop and compare. Each removed a recorded stall.
- **Cut words, not referents.** A short line keeps the thing its words point at. "Nothing was printed about it", not "nothing printed"; "those 3 came round the ring", not "via the ring".
- **A contrast states its ranking.** The one misunderstanding in round two came from a paragraph of the original whose contrast implied an order its own table refuted. One claim per line: say which pair is closer, or show the table and say nothing.
- **Naming is not explaining.** A code element a section introduces gets a line that says what it does. `-> void` and `.new()` were listed and never explained, and six of seven readers stalled on them.
- **A pointer into the course is never typed by hand.** "From chapter 9" is generated from the taxonomy or left out. The one hand-typed pointer in round two was false, and only readers who had the earlier chapters could see it.
- **Admin compresses; teaching does not.** An admin step becomes a call (above). A concept taught earlier is used by its name; it is not re-taught, and it is not linked.

## Example

**1.2 A position needs a body**

*[three stations: empty · a sphere · a sphere that stops the feeler]*

A position is three numbers.
It has no size: nothing shows.

```gdscript
var spot := Vector3(0, 1.12, 0)
```

Give it a mesh: it shows.

```gdscript
var look := MeshInstance3D.new()
look.mesh = SphereMesh.new()
look.position = spot
add_child(look)
```

Give it a shape: it stops things.

```gdscript
var solid := StaticBody3D.new()
var edge := CollisionShape3D.new()
edge.shape = SphereShape3D.new()
solid.add_child(edge)
solid.position = spot
add_child(solid)
```

What you see and what you touch are set apart.
Make the shape larger than the mesh.
The feeler stops before the sphere.

**1.5 Once, then every frame**

*[the counter, three stills a second apart]*

`_ready` runs once.
`_process` runs every frame.

```gdscript
var count := 0

func _process(_delta):
	count += 1
	$Counter.text = str(count)
```

The number climbs.
Move the two lines into `_ready`.
It stops at one.

Work that happens once goes in `_ready`.
Work that changes goes in `_process`.

> **Types** (chapter 1) · *position*: where something is, a `Vector3` · *mesh*: what is seen · *shape*: what is touched · *body*: a node you place · *frame*: one picture Godot draws before it draws the next · *variable*: a name for a value
