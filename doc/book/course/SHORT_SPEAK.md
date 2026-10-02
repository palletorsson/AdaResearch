# Short-speak and type-safe text

The form every lesson of the Godot course is written in. Agreed with Palle on 2 October 2026:
"a compressed poetic technical form", a little less poetic than the first draft.

## Short-speak

- Lines, not paragraphs. One claim per line.
- A line is short: aim for seven words, rarely more than ten.
- Three kinds of line, in this order when they occur: what to do, what you see, why it is so.
- Code first, then the lines about it. A section is one idea, one picture, the code, a few lines.
- Parallel lines may repeat with one change ("Give it a mesh: it shows." / "Give it a shape: it stops things."). That is the only ornament.
- A section ends on its technical point, not on an image.
- No filler: just, simply, now, basically, actually, note that, we will, let's, in order to.
- No hedging and no measurement reports in the lesson. Numbers the student needs stay; caveats and "not checked" go to the README or the teacher notes.
- Second person, present tense.

## Type-safe text

- A term that matters is a type. It is declared once, where it is first needed, and listed in the chapter's **Types** box.
- A declared term keeps one meaning for the whole book and is never replaced by a synonym. If *shape* is what is touched, it is never called a collider, a boundary or a hitbox elsewhere.
- A term is used only after it is declared.
- Names from the code appear exactly as the code spells them, in code style. The text never names something the code does not have.
- A word the student already knows from everyday language stays everyday; only words that carry a technical meaning in this course are types.

## Admin is said once

Admin is the scaffolding around the teaching: running the project, adding a node, saving a script under a name.
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

## Example

**1.2 A position needs a body**

*[three stations: empty · a sphere · a sphere that stops the feeler]*

A position is three numbers.
It has no size. Nothing shows.

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

> **Types** (chapter 1) · *position*: where something is, a `Vector3` · *mesh*: what is seen · *shape*: what is touched · *body*: a node you place · *frame*: one turn of the loop · *variable*: a name for a value
