# Functional text

Type-safe text, written in short-speak.
Named with Palle on 2 October 2026.
The voice is [SHORT_SPEAK.md](../SHORT_SPEAK.md).
This file adds the types.

Functional text is text that compiles.
Every technical element is declared once, in one file.
Every section is a function: it needs, and it gives.
A chapter is a module.
The book is a program.
It compiles when every need is given before it.
Its code runs, and what the lines claim, the run shows.
`check.py` proves both.

## 1 The hard taxonomy

One file holds every element the book may use:
[`doc/book/course/taxonomy.json`](../taxonomy.json).
Nothing outside it may appear as a technical element.

An entry:

```json
{
  "id": "shape", "kind": "concept",
  "forms": {"text": ["shape", "shapes"], "code": ["shape"]},
  "def": "What is touched.",
  "introduced_at": "1.3",
  "synonyms": ["collider", "colliders", "boundary", "hitbox", "hull"],
  "depends_on": []
}
```

| field | what it holds |
|---|---|
| `id` | the name signatures use; for code, the code itself (`Vector3`, `:=`, `$`) |
| `kind` | `concept`, `maths`, `gdscript`, `godot`, `supplied`, `name`, `plain`, `admin` |
| `forms.text` | the words it takes in prose |
| `forms.code` | the tokens it takes in code; a signature like `line(a, b)` too |
| `def` | one claim of short-speak, at most 14 words, no second colon |
| `introduced_at` | where it is given: `1.3`, `4.0`, `7.x`, `supplied:1.5`, `everyday` or `missing` |
| `opened_at` | for a supplied part: the section that finally teaches it |
| `synonyms` | forbidden words: the text must never use them |
| `depends_on` | the entries its def is explained with |
| `late_deps` | dependencies taught later, on purpose: a warning, not an error |
| `other_senses` | where the sketch uses a form in another sense |
| `note` | why it stands where it stands |
| `stub` | for a supplied call: GDScript that stands in for it when code runs |
| `host` | where the stub lives: `$Supplied` (a node of the base scene) or `res://supplied/x.gd` |
| `step_phrases` | an admin's words that would say its steps again; `{"phrase", "cues"}` counts only beside a cue |
| `calls` | an admin's call templates: `add a {node}` is "Add a `Node3D`" |

`introduced_at` has six values.

| value | means |
|---|---|
| `1.3` | section 1.3 gives it |
| `4.0` | chapter 4 gives it; no section names it yet |
| `7.x` | a name chapter 7's examples give: chapter 7's own, an error anywhere else |
| `supplied:1.5` | handed out at 1.5, before it is taught |
| `everyday` | a plain word or a name: nobody teaches it |
| `missing` | used, and never taught: every use is reported |

`missing` is the honest value.
It never invents a teaching place.
A chapter writer replaces it with a section.

An `other_senses` item:

```json
{"words": ["index"], "at": ["3.4"], "sense": "a loop's counter"}
```

`at` lists sections; `4.0` is chapter 4's code_new.
In the sketch, that word there is no order break: a `sense` warning.
In a chapter it changes nothing: one word, one meaning.

How prose is read:

- A text form with a capital matches as written: `Inspector`, `P1`.
- So "p1" in a formula is no type. An admin's labels match the same way: `Play`, never the verb "play".
- An acronym form right after a number is a unit: "3 PM" is no wallpaper group.
- Every other text form matches in any case.
- The words of a phrase may be joined by a hyphen: "dot-product" is *dot product*.
- A form of a technical word is that word: "accelerates", "frictionless", "pseudorandom", "re-shaped", "signalling".
- Before the entry's section, such a form is an order error.
- After it, an unlisted form is a warning: list it, or pin it plain.
- A plain entry pins an everyday word: `lined up`, `forced`, `selected`.
- One word, one entry: "degree" in one entry and "degrees" in another is a taxonomy error.
- A def is text too: its terms are its dependencies.
- A dependency is introduced no later than the entry, or `late_deps` declares it.
- The graph of `depends_on` has no cycle.

## 2 Sections are functions

Every section declares a signature.

| field | what it lists |
|---|---|
| `needs` | entries the section uses, all given before it |
| `gives` | entries it introduces: exactly those with `introduced_at` here, plus any part `opened_at` here |
| `borrows` | supplied parts handed out here: exactly those with `introduced_at: supplied:` here |
| `admin` | admin procedures defined here: exactly those of kind `admin` with `introduced_at` here |

A section gives only what its lines declare.
A type it gives needs one declaring line: "A frame is ...", "... is a frame", "frame: ...".
A code element it gives needs a line that says what it does: naming is not explaining.
In round two six of seven readers stalled on `-> void` and `.new()`, which a section listed and never explained.
The checker sees that the line exists; whether it explains is the reviewer's.
A section uses only what it needs, gives or borrows.
Everyday words need no listing.
Names the code declares are its own: `count`, `gap`, `$Ball`.
They stay in their chapter, like a module's private names.
A declared name may not spell a later element: `var velocity` in chapter 1 is an error.
A file the chapter saves is its own: "Save this script as `cup.gd`."
A name used across chapters is an entry.

## 2a Admin is said once

Admin is the scaffolding around the teaching.
Running the project, adding a node, saving a script under a name.
Palle, 2 October 2026: "how to run the project can be described once. after that we can just say run the project."
He added: "not everything should be linked back I mean not the teaching of that tutorial but admin".

Admin is a kind of entry: `admin`.

```json
{
  "id": "run_the_project", "kind": "admin",
  "forms": {"text": ["run the project", "ran the project", "running the project", "runs the project"], "code": []},
  "def": "Press Play, at the top right. If Godot asks for a main scene, choose Select Current.",
  "introduced_at": "1.1",
  "synonyms": ["press Play", "hit Play", "press F5", "run it", "play the scene", "start the game", "..."],
  "step_phrases": ["Play", "F5", "Cmd+B", "Select Current",
                   {"phrase": "main scene", "cues": ["asks", "Select"]},
                   {"phrase": "top right", "cues": ["Play", "button", "arrow", "triangle"]}],
  "unless": ["animation", "AnimationPlayer", "AudioStreamPlayer", "clip"],
  "depends_on": ["scene"]
}
```

The entry is abridged here; `taxonomy.json` holds it whole.
Its first text form is its name, an imperative: *run the project*.
Its other text forms are the name in another tense: "You ran the project." is a call too.
Its def is its steps, one sentence a line; each step is measured as a line.
Its synonyms are its other wordings, matched in any case: "press play" and "Hit PLAY" are "press Play".
A synonym may be a template: `create a {node}` reads "Create a `Node3D`", and the advice is "Add a `Node3D`."
Its step phrases would say its steps again.
A step phrase with cues counts only on a line that holds a cue: "top right" beside Play.
Cues are read with the code spans: the cue `.gd` finds `bell.gd`.
`unless` lists words of a line about another Play: "Press Play in the animation panel" is no step of it.
A label that opens a sentence is the button only as a noun: "Play, at the top right", "Play is the button".
"Play a sound" and "Play around" are the verb.
A key in code style is read as words: "Press `F5`" is "press F5". So is "F 5".
It has no code form.
It is given in one section, or it is `missing`.
It stays out of the Types box: the page links each call to it.

The defining section lists it under `admin:`, not `gives:`.
It writes it once: the bold name, a colon, the first step.
The other steps follow, one a line.

```markdown
<!-- section 1.1
gives: supplied, node, scene, ...
admin: run_the_project
borrows: base_scene
-->
...
**Run the project**: press Play, at the top right.
If Godot asks for a main scene, choose Select Current.
```

An argument in code style may stand between the name and the colon: "**Save this script as** `field.gd`: click Script, at the top."
After that the text says only the name, as a step line: "Run the project."
A call may carry what follows: "Run the project: the number climbs."
A section that calls it lists it in `needs`.
A call template finds the calls that carry arguments.
`add a {node}` reads "Add a `Node3D` named `Here`".
`{node}` holds a node class: an entry of Godot whose `depends_on` reaches *node*.
`{n}` holds a number; `{code}` and `{file}` hold a code span.
"Add a `Vector3`" is no call.

A call is an instruction to the student.
It opens its clause, or follows *then*, *and*, *you*, *to*, *when*: "Set it in the Inspector, then run the project."
A sentence about code holds no call: "`add_child()` is how code can add a node" teaches `add_child`.
So does "add twelve `MeshInstance3D` nodes by code".
Neither is a use of *add a node*, and the page links neither.
A wording that opens with a verb counts the same way: "a waiting thread will run it" runs a function.
"run it" counts only where it ends its clause or goes on to *again*: "then run it once from `_ready`" is no step.

Teaching is never a call.
The test, Palle's: if the step were done for the student, would they still learn what the section teaches?
Then it is admin. If not, it is teaching, and it stays written out.
Giving `Seen` a `SphereMesh` in 1.3 is the lesson: a mesh is what is seen.
Later chapters use its terms in their own lines, unlinked.

Every text the student reads is read for admin.
Lines, headings, figures, captions, image alt text, a `<summary>`, a quote, a list item.
A string in code, a `text` block, the Types box, and every def in the taxonomy.
An inline tag hides no word: "Pl<span></span>ay" is "Play".
Not read: an HTML comment, and a name the code declares (`func run_it()` describes no step).

| rule | finds |
|---|---|
| `order` | a call before the defining section; a call in the chapter's head before it; a call before the bold line, in the defining section itself |
| `admin` | a synonym or step phrase outside the defining section: `'press Play' describes run the project again: say "Run the project." (1.1)` |
| `admin` | the same before the definition: `'Press Play' describes run the project before its definition (1.1)`; for a `missing` admin, `which no section defines yet` |
| `admin` | a defining section with no bold line, or steps that differ from the def, or stop short |
| `admin` | in the defining section: a second definition; another wording of it on a line apart from the definition; an "Or ..." line right after its steps |
| `admin` | a definition anywhere else, in any shape: `**Run the project** — ...`, a list item, `**Run project**:` |
| `admin` | an `admin:` list that differs from the taxonomy; an admin listed in `gives:` |
| `admin` | a typed link to a definition, in any form: a fragment that names it (`#run_the_project`), a link whose words call it, a reference definition, an `href` |
| `taxonomy` | an admin with a code form, no section, a step over 14 words, a step phrase that is another entry's form, a bad template; step phrases, calls or unless on any other kind; a def of any other entry that says an admin's steps |

The sketch is planning prose.
It may describe an admin in the admin's own chapter.
Elsewhere it gets an `admin` warning.
An admin needs no naming in the sketch, and no `unused` warning there.

Each rule can be switched off for a test: `FT_OFF=admin-again`.
The switches: `admin-taxonomy`, `admin-order`, `admin-again`, `admin-define`, `admin-signature`, `admin-calls`, `admin-link`.
`test_check.py` switches each off and proves its planted fault then passes.

The admin entries, 2 October 2026:

| entry | defined | calls in ch01 and ch18 |
|---|---|---|
| *run the project* | 1.1 | 1.1 (once, after its steps), 1.3, 1.6 (twice), 18.1, 18.3, 18.6 |
| *add a node* | 1.3 | 1.4, 1.7 (and six in 1.3 itself) |
| *save this script as* | 18.1 | 18.2 to 18.8, seven |
| *run the scene* | `missing` | none |

*Run the scene* is F6: the open scene alone, where F5 runs the main scene.
No section defines it yet: every chapter written so far runs the base scene.
Its wordings ("press F6", "Run Current Scene", "run only the open scene") are reported as described before any definition.
The first section that runs a second scene by itself defines it, no earlier than 3.1.

## 2b The page's devices

A chapter uses these devices and no others.
Each is declared here, once, so the page never has to explain its own markup.

| device | what it is |
|---|---|
| `*[...]*` | a figure line: what the picture shows |
| `**Example N.M: name**` | the caption of a runnable example |
| a fenced block | code, tagged `gdscript`, `gdshader` or `text` |
| `1.` `2.` ... | numbered steps, for an algorithm too long for lines |
| one equation per line | each with its own figure |
| `**Why**` | a folded box: the one place for compressed prose |
| `**What it hides**` | a few lines of the critical layer |
| `Restore:` | after an experiment that changed the code, how to put it back |
| the **Types** box | the chapter's declared terms, code and supplied parts |
| `N.x` | the chapter's exercises |

Round one proposed more (arrows, `enters:`, `from:`, provenance tags).
Round two measured them: 11–36 % more words, no score moved, and readers stalled where a page used one undeclared.
They are not devices. A pointer into the course is generated from the taxonomy, never typed.

## 3 The chapter file

One file per chapter: `doc/book/course/functional/chNN.md`.
Signatures and code options sit in HTML comments: the student never sees them.
The Types box is all the student sees of types.
[`functional/ch01.md`](../functional/ch01.md) and [`functional/ch18.md`](../functional/ch18.md) pass.

The parts, in order:

| part | form |
|---|---|
| chapter comment | `<!-- chapter 1 ... -->` (optional) |
| title | `# 1 Points Build Bodies` |
| head lines | a preview: may name the chapter's own terms, nothing later |
| signature | `<!-- section 1.3` then `needs:`, `gives:`, `borrows:`, `admin:` lines, then `-->` |
| heading | `## 1.3 A position needs a body`; the number matches the signature |
| figure | `*[what the picture shows]*` on its own line, at most 30 words |
| label | `**Example 1.1: three stations**` on its own line |
| equation | a line that is one code span: `` `t = (level - at[a]) / (at[b] - at[a])` `` |
| lines | one sentence per line, ending in . ! ? or : |
| code | a fenced `gdscript` block; options in `<!-- code: ... -->` just before it |
| exercises | signature `<!-- section 1.x needs: ... -->`, heading `## Exercises`; gives nothing |
| Types box | a blockquote at the end: `**Types**`, `**Code**`, `**Supplied**` |

Every fence says `gdscript`, `gdshader` or `text`.
A `text` block is read as prose.
Every other fence is an error, and is read as code anyway.

Code options:

| option | meaning |
|---|---|
| (none) | run it headless for 60 frames, with the section's other blocks; any error is an error |
| `nodes=Ball:MeshInstance3D:SphereMesh,Ball/Shadow:Node3D` | the scene the text has the student build; a path puts a node under another |
| `frames=120` | run this many frames |
| `until="task == -1"` | after the frames, run on until this is true (30 seconds at most) |
| `claim="values.size() == 1331"` | true at the end of the run; may repeat |
| `prints="27 inside"` | the run prints this whole line; may repeat |
| `alone` | its own script, apart from the section's other blocks |
| `parse` | parse it, never run it: a warning, since nothing it shows is checked |
| `fails` | it must fail to parse (a lesson that breaks on purpose) |
| `skip` | not code Godot sees: a warning |

A block of statements is wrapped into `func _ready():`.
A block with `func` or members stays at script level.
A block with no `extends` takes the last one the book showed.
None before it is an error.
A supplied call lives where its `host` says.
`$Supplied.line(a, b)` reaches the base scene's node `Supplied`.
`var table := preload("res://supplied/triangle_table.gd")` reaches a supplied script.
A bare `line(a, b)` fails in Godot, as it would for the student.
Every stub notes its calls in `_ft_calls`, so a claim can count them.
A stub may refuse bad input: `line()` with two equal points is an error.

A number the lines of a run section state must be shown.
It is a literal in the section's code, a printed line, or in a claim.
Digits count, and number words from ten up.
An instruction's numbers, before its colon, are inputs: "Set `tall` to 5: the spire grows."
References are no numbers: Example 1.2, section 1.6.

### One section, complete

Chapter 1's section 1.3, as the file has it.

````markdown
<!-- section 1.3
needs: position, point, scene_tree, node, editor, Node3D, supplied, func, _ready, $, =, Vector3, run_the_project
gives: mesh, shape, body, Inspector, MeshInstance3D, SphereMesh, StaticBody3D, CollisionShape3D, SphereShape3D
admin: add_a_node
borrows: feeler
-->
## 1.3 A position needs a body

*[three stations in a row: an empty label, a white sphere, a sphere that stops the cyan feeler]*

A position is a point.
It has no size: nothing shows.

**Add a node**: select the node it goes under.
Press + above the scene tree.
Choose its kind, then Create.
Double-click the new node to name it.
The Inspector is the editor's panel of a node's numbers.
Build three stations in a row under the top node.
Add a `Node3D` named `Here`: a position, nothing else.
Add a `MeshInstance3D` and name it `Seen`.
In the Inspector, give `Seen` a `SphereMesh`.
Add a `StaticBody3D` and name it `Solid`.
`StaticBody3D` is Godot's node for a body that stays put.
Under `Solid`, add a `MeshInstance3D` with a `SphereMesh`.
Under `Solid`, add a `CollisionShape3D` with a `SphereShape3D`.
Under the top node, add one more `Node3D`.
Attach the supplied `contact_probe.gd` to it.
It is the feeler, a cyan rod that moves.

**Example 1.1: three stations**

<!-- code: nodes=Here:Node3D,Seen:MeshInstance3D:SphereMesh,Solid:StaticBody3D,Solid/MeshInstance3D:MeshInstance3D:SphereMesh,Solid/CollisionShape3D:CollisionShape3D:SphereShape3D claim="$Solid.get_child_count() == 2 and $Solid/CollisionShape3D.global_position == $Solid.global_position" -->
```gdscript
func _ready():
	$Here.position = Vector3(-1.5, 1.12, 0)
	$Seen.position = Vector3(0, 1.12, 0)
	$Solid.position = Vector3(1.5, 1.12, 0)
```

Run the project.
The feeler runs along the three stations.
At `Here`, it meets nothing.
At `Seen`, a white sphere: the feeler passes through.
At `Solid`, the same sphere: the feeler stops.

A mesh is what is seen.
A shape is what is touched.
Each station is a body, a node you place.
The nodes under `Solid` go where `Solid` goes.
The feeler meets the shape, never the mesh.
````

Node names go in code style: `Point` is a node.
*point* is a type.

### The Types box

```markdown
> **Types** (chapter 1) · *mesh*: what is seen · *shape*: what is touched · ...
>
> **Code** · `MeshInstance3D` · `SphereMesh` · `$` · `:=` · ...
>
> **Supplied** · *feeler* · `line(a, b)` · `mouse_point()` · ...
```

**Types** lists concepts, maths and names, each with its def.
**Code** lists its GDScript and Godot elements.
**Supplied** lists the parts it borrows.
The checker compares all three with the signatures.
A def in the box is the taxonomy's def, word for word.
It is order-checked like any line.

### Rendering

The source keeps one line per line.
The encyclopedia keeps them too: `/course/sketch/1` shows chapter 1.
It hides the signatures and shows the Types box apart.
An admin's defining line gets an id: `/course/sketch/1#run-the-project`.
Every later call links there; within its chapter, to `#run-the-project`.
Calls in the defining section itself stay plain: the steps stand above them.
The page finds a call as the checker does: an instruction, never a sentence about code.
The link covers the call's words before its first argument: "Add a" in "Add a `Node3D`", "Add" in "Add five ...".
The count, the class and the name are the lesson's, and stay outside the link.
The link is light: the line keeps its colour, a dotted rule marks the call.
A call never breaks across two lines: at phone width it moves down whole.
The page makes the links from `taxonomy.json` and the signatures' `admin:`.
The source never types one. No concept or term gets a link.
`/course/sketch/order` shows the order report.

## 4 What the checker verifies

| pass | rule | verifies |
|---|---|---|
| a | `taxonomy` | unique ids and forms; one word, one entry; synonyms are no form; kinds and sections valid; every stub has a host; every dependency known, introduced no later (or in `late_deps`), never `missing`, no cycle; each def uses only its dependencies |
| b | `gives` | each section gives and borrows exactly what the taxonomy puts there; each type it gives has a declaring line; each code element a naming line |
| c | `order` | every form, derived form and declared name is used at or after its section |
| c | `never` | an element marked `missing` is used |
| c | `unknown` | every identifier, operator and string in code, and every code-shaped or watch-listed word in prose, is an entry or the chapter's own name; a func named `_x` is an entry |
| c | `style` | a code name in prose is in code style, and so is a setting: "Set the size" |
| c | `chars` | no invisible character, no look-alike letter inside a word |
| c | `form` | a derived form of an introduced word is listed (a warning) |
| c | `signature` | every use is in `needs`; nothing needed is introduced later |
| d | `synonym` | no forbidden synonym, in prose, in a string, or in a name the code declares; an admin's wordings are the admin rule's, and a declared name is not read for them |
| d | `admin` | an admin is defined once, as its bold name and its steps; elsewhere it is only called, never described, in any text the student reads (2a) |
| e | `unused` | every introduced entry is used after its section (an error once all chapters are checked) |
| f | `length` | lines: warning over 10 words, error over 14; a sentence over several lines counts whole; figures: 20 and 30; a code span weighs half a word per name, and more than 8 names is an error |
| f | `sentence` | every line ends its sentence; one sentence per line; no semicolon, no dash between claims, one colon at most |
| f | `filler` | none of: just, simply, now, basically, actually, note that, we will, let's, in order to, obviously, clearly, of course, very, really, quite, perhaps, maybe, probably, somewhat |
| f | `hedge` | none of: might, could, possibly, seems, appears to, likely, arguably, somehow, sort of, kind of, tends to, presumably, may be |
| f | `poetic` | no thing that remembers, dreams, whispers, sings, knows, owns, wants |
| f | `voice` | warning on we, our, us, I |
| — | `types` | the Types box matches the signatures and the taxonomy's defs |
| — | `number` | a number a run section states is in its code, a printed line or a claim |
| g | `code` | each `gdscript` block parses in Godot 4.6 |
| g | `run` | each block runs headless without an error, and prints what it must |
| g | `claim` | every claim holds at the end of its run, and every `until` comes true |

Inline code and fenced code are always technical.
An image's alt text, a link's title and an HTML title are read: the reader sees them.
The head of a chapter may preview its own terms.
Figures skip the sentence, filler, hedge and poetic rules.

## 5 Commands

From `doc/book/course/`:

```
python functional_text/check.py --taxonomy taxonomy.json functional/ch01.md functional/ch02.md
python functional_text/check.py --taxonomy taxonomy.json --godot functional/ch01.md
python functional_text/check.py --taxonomy taxonomy.json --sketch sketch/sketch.json --chapters 1
python functional_text/check.py --taxonomy taxonomy.json --sketch sketch/sketch.json \
    --report functional_text/sketch_report.md
python functional_text/test_check.py
```

Each finding prints as `file:line: rule: message`.
A warning prints as `file:line: rule: warning: message`.
The exit code is the error count, at most 255.
Without `--godot`, pass g is skipped, and says so.
`--godot-exe` or `GODOT` names the executable.
`--keep --workdir <dir>` keeps the scratch Godot project.
`--quiet-warnings` prints errors only.
`FT_OFF=admin-again` (an environment variable) switches a rule off, for a test.

`--sketch` checks the course plan before any chapter exists.
`code_new` is what a chapter gives.
Titles, ideas, figures, examples, exercises, project step: uses.
`borrowed` is what it supplies.
An entry unnamed where it is introduced: a warning.
A synonym in the sketch is a warning, and so is a derived form.
Code forms that are English words (`if`, `for`) are skipped.
Code shapes are read first: `Input.is_action_pressed()` is code.
A formula's own names (`m1`, `dE`) are not unknown.
Chapter references (`ch5`) and hall names (`Point_Zero`) are not code.

Sketch mode adds four rules.

| rule | finds |
|---|---|
| `twice` | an element taught again in a later chapter |
| `unplaced` | an element at `N.0`: its section is not named |
| `listing` | code a section teaches that code_new leaves out |
| `sense` | a declared other sense: not an order break |

`twice` has two readings.
A later code_new lists it at a clause's head.
Or a later idea defines it: "A pin is ...".
In a formula, after a preposition, or plural: a use.
A back-reference declares a return: `(met in ch13)`, `(the field of 6.5)`.

`--report` writes the order report as Markdown.
By chapter, it lists each element used before its teaching.
Then every element never taught, and every element taught twice.
It counts them at the top.
`sketch_report.md` beside this file is its output.

## 6 What it cannot see

Meaning.
A form used in the wrong sense passes.
The taxonomy pins one meaning; the writer keeps it.
Clashes known so far:

| word | the senses |
|---|---|
| line | between two points (1.5) · a line of code (pinned plain: `line of code`) |
| shape | what is touched (1.3) · a form ("L-shaped" passes as a form of it) |
| body | a node you place (1.3) · the "Body" in `StaticBody3D`, `RigidBody3D` |
| Point | the base scene's node · the concept *point* |
| cell | one place of a grid (5.1) · the cube between eight samples (18.3) |
| degree | the everyday angle · the graph's count, here *vertex degree* (22.1) |
| stack, field, level, return, step | see the `other_senses` and `note` fields |

Code names carry words: `add_child` says *child* in chapter 1, before 2.7.
The checker does not split them.

The watch-list is not a lexicon.
A technical word that is on no list and in no entry still passes.
Claims prove only what they say: a writer can claim too little.
A run is finite: an error after the frames, and after any `until`, passes.
Each `class_name` is declared once per checked run, so the whole book cannot yet be run as one.
Code runs in a scratch project, without the repository's autoloads.
Names are global: a chapter's local may not spell any later element.
An admin's steps said in new words, which no synonym or step phrase holds, pass: "Press the green arrow", "Or press Ctrl+Shift+S" without its "Or".
"Play it again" passes: the checker cannot tell whether *it* is the scene or a sound.
"run it" as a call is read as running the project, never as running the scene.
A key named in passing is read as its step: "F5 among them" is an `admin` error.
A call template sees only the calls it spells: "add five `MeshInstance3D` nodes" needs `add {n} {node}`.
The call rule reads position and a few words (*by code*, `add_child`), not meaning: a sentence about code that names neither is read as a call.
