# Is the order right? The sketch, checked

The mechanical answer, by `check.py`, from `sketch/sketch.json` and `taxonomy.json`.
Regenerate from `doc/book/course/`:

```
python functional_text/check.py --taxonomy taxonomy.json --sketch sketch/sketch.json \
    --report functional_text/sketch_report.md
```

Sketch: The Godot Course, Sketched, 2026-10-02. Taxonomy: 631 entries. Run: 34 errors, 641 warnings.

## Counts

| finding | elements | uses |
|---|---:|---:|
| used before it is taught | 7 | 7 |
| used, never taught (`introduced_at: missing`) | 22 | 28 |
| never taught, named only inside a supplied part or a code_new | 3 | - |
| taught twice | 22 | 23 |
| explained by an element taught later (the taxonomy's depends_on) | 2 | 2 |
| the same word in another sense, declared (not an order break) | 17 | 41 |
| taught in a chapter's code_new, but no section names it | 4 | - |
| taught in a section, missing from the chapter's code_new | 58 | - |

A use is one line of the sketch that names the element: a section title, idea or figure,
an example, an exercise, a project step, or a code_new item. A section `N.x` is chapter N's
examples, exercises and project step. `chN code_new` is chapter N's list of new code.

## The largest gaps

First use of each element against where it is taught, the widest first.

| element | first used | taught at | chapters early |
|---|---|---|---:|
| damping | 9.x | 17.1 | 8 |
| queue | 16.x | 22.2 | 6 |
| reaction-diffusion | 12.x | 13.8 | 1 |
| genome | 15.x | 16.1 | 1 |
| wallpaper group | 5.4 | 5.7 | 0 |
| rate | 6.1 | 6.3 | 0 |

## By chapter

### Chapter 1: Points Build Bodies

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| surface | ch1 code_new, 1.x | the mesh: what is seen | surface | 9.5 |
| lines | 1.1 | a line of code | line | 1.5 |
| line | 1.1 | a line of code | line | 1.5 |

### Chapter 3: Many From One

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| index | 3.4 | a loop's counter: the third loop of a lattice | index | 5.1 |
| fields | 3.6, 3.7 | an area of colour or pattern | field | 6.5 |

### Chapter 4: Colour by Function

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| stack | 4.1, 4.2, 4.x | a pile of bodies | stack | 15.3 |
| level | 4.2 | flat, or a tier | level | 18.2 |
| stacks | 4.2 | a pile of bodies | stack | 15.3 |
| field | 4.5, 4.x | an area of colour or pattern | field | 6.5 |

### Chapter 5: A Source, Many Copies

**Used before it is taught**

| element | used at | taught at |
|---|---|---|
| wallpaper group | 5.4 | 5.7 |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| field | 5.4, 5.6, 5.8 | an area of colour or pattern | field | 6.5 |
| fields | 5.5 | an area of colour or pattern | field | 6.5 |

### Chapter 6: A Curve of Steps

**Used before it is taught**

| element | used at | taught at |
|---|---|---|
| rate | 6.1 | 6.3 |

**Used, never taught**

| element | used at | note |
|---|---|---|
| print | 6.x | used in a 6.x exercise and Example 13.1; never taught |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| wrap | 5.4 | ch6 code_new | wrapping at the edges with fposmod |

### Chapter 7: Arrows That Push

**Used, never taught**

| element | used at | note |
|---|---|---|
| `limit_length` | 7.x | used in a 7.x exercise; never taught |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| `length` | 2.5 | ch7 code_new | length() and normalized(); vector addition and subtraction as moves |

**Explained by an element taught later** (the taxonomy's depends_on)

| element | taught at | depends on | which is taught at |
|---|---|---|---|
| `body_entered` | 7.9 | signal | 24.7 |
| `body_exited` | 7.9 | signal | 24.7 |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| overrides | ch7 code_new | replaces, in everyday speech: a region that overrides gravity | override | 17.4 |
| pins | 7.1, 7.x | marker pins on the floor | pin | 8.4 |

### Chapter 8: Finding the Form

**Used before it is taught**

| element | used at | taught at |
|---|---|---|
| Mover | 8.x | chapter 7's own name, from its examples |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| velocity | 6.1 | ch8 code_new | Verlet integration: a Particle class keeps position and previous; the velocity is now minus before; a pinne... |
| rigid body | chapter 7, no section | ch8 code_new | a stillness test: RigidBody3D sleeping, timed |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| level | 8.6 | flat, or a tier | level | 18.2 |
| stack | 8.8 | a pile of bodies | stack | 15.3 |

### Chapter 9: What Returns

**Used before it is taught**

| element | used at | taught at |
|---|---|---|
| damping | 9.x | 17.1 |

**Used, never taught**

| element | used at | note |
|---|---|---|
| Lissajous | 9.x | named in a 9.x exercise |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| phase | 3.8 | ch9 code_new | amplitude, period, frequency, phase |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| wave | 9.4 | the shape one pendulum's record makes when laid out in time | wave | 9.6 |

### Chapter 10: Chance Enters the Grid

**Used, never taught**

| element | used at | note |
|---|---|---|
| accept-reject | 10.x | named in a 10.x exercise (NOC 0.5) |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| level | 10.3 | flat, or a tier | level | 18.2 |

### Chapter 11: Chance That Remembers

**Used, never taught**

| element | used at | note |
|---|---|---|
| `noise_type` | 11.x | used in an 11.x exercise; never taught |
| simplex | 11.x | named in an 11.x exercise |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| solid | 11.4 | firm, not empty | solid | 19.1 |

### Chapter 12: Every Pixel at Once

**Used before it is taught**

| element | used at | taught at |
|---|---|---|
| reaction-diffusion | 12.x | 13.8 |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| fractal sum | 11.5 | ch12 code_new | value noise and fBm inside a shader |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| graph | 12.2 | a drawn curve of values | graph | 22.1 |
| freeze | 12.x | stop a clock | freeze | 17.7 |

### Chapter 13: Rules in Time

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| cell | 5.3 | 13.1 | A cell is a number, 0 or 1, and a row of cells is an array. |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| spots | 13.8 | a round patch of a pattern | position | 1.1 |
| difference | 13.x | a change between two runs | difference | 19.4 |

### Chapter 14: Again, Smaller

**Used, never taught**

| element | used at | note |
|---|---|---|
| fractal | 14.x | used in 14.x exercises; no section or code_new of chapter 14 names it |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| boundary | 14.5 | the edge of a region | shape | 1.3 |

### Chapter 15: A Sentence Grows

**Used before it is taught**

| element | used at | taught at |
|---|---|---|
| genome | 15.x | 16.1 |

**Used, never taught**

| element | used at | note |
|---|---|---|
| Output panel | 15.x | named in Example 15.1; never taught, nor is print |

### Chapter 16: Rules Build Worlds

**Used before it is taught**

| element | used at | taught at |
|---|---|---|
| queue | 16.x | 22.2 |

**Used, never taught**

| element | used at | note |
|---|---|---|
| evolution | 16.x | Example 16.2 and chapter 21 use it; no section teaches the word |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| attraction | 7.7 | ch16 code_new | attraction: adding up unit vectors toward the nearest targets |
| reflection | 3.6 | ch16 code_new | reflection by index: n - 1 - x |

### Chapter 17: Matter That Yields

**Used, never taught**

| element | used at | note |
|---|---|---|
| feed and kill | 17.8, 17.x | used at 17.8 and 24.6; 13.8 never names them |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| pin | 8.4 | 17.2 | A pin is a point that may not move; change the pins and the same cloth hangs another way. |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| spots | 17.8 | a round patch of a pattern | position | 1.1 |

### Chapter 18: Bodies From Fields

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| field | 6.5 | 18.1 | A field is a function that returns one number for any point; sample it on a grid and draw the samples. |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| boundary | 18.2 | the edge of a region | shape | 1.3 |
| solid | 18.7 | firm, not empty | solid | 19.1 |

### Chapter 19: Three Verbs for Solids

**Used, never taught**

| element | used at | note |
|---|---|---|
| symmetric difference | 19.x | named in a 19.x exercise |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| child | 2.7 | ch19 code_new | child order is the order of the verbs |
| recursion | 14.1 | ch19 code_new | recursion that leaves holes by not building cells |

### Chapter 20: Many Bodies, Local Rules

**Used, never taught**

| element | used at | note |
|---|---|---|
| Physarum | 20.x | named in Example 20.2; no section names it |

### Chapter 21: Bodies That Learn

**Used, never taught**

| element | used at | note |
|---|---|---|
| chain rule | ch21 code_new | named in chapter 21's code_new as not needed; never taught |
| genetic algorithm | 21.1 | 21.1 calls chapter 16's breeding by this name; chapter 16 never does |
| evolution | 21.8, 21.x | Example 16.2 and chapter 21 use it; no section teaches the word |
| vehicle | 21.8 | 21.8 says your Chapter 20 vehicle; chapter 20 never calls it that |
| Huber | 21.x | named in a 21.x exercise |
| memory cell | 21.x | a 21.x exercise (ML_Sequence_Memory) |
| gate | 21.x | 21.x (memory gates) and Example 23.5 (a logic gate); never taught |
| token | 21.x | a 21.x exercise |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| gradient | 8.1 | ch21 code_new | the gradient by nudging (finite differences) and the learning rate |
| gradient descent | 8.1 | 21.3 | Nudge each number, see which way the error falls and step that way: that is gradient descent. |

### Chapter 22: What Connections Permit

**Used, never taught**

| element | used at | note |
|---|---|---|
| topological sort | 22.x | named in a 22.x exercise |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| `push_back` | 15.3 | ch22 code_new | a queue and a stack (push_back, pop_front, pop_back); a visited set; came_from and walking a path back from... |
| `pop_back` | 15.3 | ch22 code_new | a queue and a stack (push_back, pop_front, pop_back); a visited set; came_from and walking a path back from... |
| stack | 15.3 | ch22 code_new | a queue and a stack (push_back, pop_front, pop_back); a visited set; came_from and walking a path back from... |

### Chapter 23: Where Foundations Fail

**Used, never taught**

| element | used at | note |
|---|---|---|
| bifurcation | 23.x | named in a 23.x exercise |
| Penrose | 23.x | named in a 23.x exercise |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| dot product | 7.3 | ch23 code_new | the angle between directions (dot product, acos); great-circle sides with Vector3.slerp |
| bool | 2.4 | ch23 code_new | a Boolean with no consistent value |
| enum | 13.6 | ch23 code_new | an enum with a third value: TRUE, FALSE, NOT_YET |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| gate | 23.x | a logic gate: true when its inputs are | gate | never taught |

### Chapter 24: The QFEP Laboratory

**Used, never taught**

| element | used at | note |
|---|---|---|
| feed and kill | 24.6 | used at 17.8 and 24.6; 13.8 never names them |

**Taught twice**

| element | first taught | taught again | the sketch says |
|---|---|---|---|
| log | 14.7 | ch24 code_new | Shannon entropy from a probability (log base 2) |

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| spots | 24.6 | a round patch of a pattern | position | 1.1 |

### Chapter 25: Open the Room

**The same word in another sense** (declared in the taxonomy; not an order break)

| word | at | sense here | the type | taught at |
|---|---|---|---|---|
| node | ch25 code_new | a point of a graph | node | 1.1 |

## Never taught, named only inside a supplied part or a code_new

These are marked `missing` in the taxonomy, but no title, idea, figure, example or
exercise uses them, so they raise no error.

| element | note |
|---|---|
| `snapped` | used in a 3.x exercise; never taught, never borrowed |
| ray | named only inside supplied parts (chapters 4 and 5); never opened |
| quaternion | named inside draw_arrow (chapter 7's borrowed list): not taught |

## Taught in a chapter, no section named

The chapter's code_new names these; no section's title, idea or figure does, so the
taxonomy places them at `N.0`, the chapter's start.

| element | chapter | note |
|---|---|---|
| rigid body | 7 | chapter 7's code_new names it; no section does |
| `apply_central_force` | 7 | chapter 7's code_new names it; no section does |
| `MultiMesh` | 13 | chapter 13's code_new names it; no section does |
| `MultiMeshInstance3D` | 20 | chapter 20's code_new says met in chapter 13; chapter 13 names only MultiMesh |

## Taught in a section, missing from code_new

Code a section teaches that the chapter's code_new list leaves out.

| element | taught at | note |
|---|---|---|
| `extends` | 1.1 | restored from functional/ch01.md, which teaches extends Node3D at 1.1; the sketch teaches extends only with inheritance (17.3) |
| `Node3D` | 1.1 | restored from functional/ch01.md; the sketch never names it |
| `func` | 1.1 |  |
| `$` | 1.1 |  |
| `=` | 1.1 |  |
| `SphereMesh` | 1.3 |  |
| `SphereShape3D` | 1.3 |  |
| `BoxMesh` | 1.4 |  |
| `CylinderMesh` | 1.4 |  |
| `PrismMesh` | 1.4 |  |
| `TorusMesh` | 1.4 |  |
| `top_radius` | 1.4 | restored from functional/ch01.md; the sketch never names it |
| `radial_segments` | 1.4 |  |
| `Engine` | 1.6 |  |
| `get_process_frames` | 1.6 |  |
| `Label3D` | 1.6 |  |
| `text` | 1.6 |  |
| `str` | 1.6 |  |
| `-` | 1.8 |  |
| `/` | 1.8 | the sketch's 1.8 says 'arithmetic': + - * / |
| `height` | 1.8 | restored from functional/ch01.md; the sketch never names it |
| `ui_left` | 2.6 | 2.6: the arrows steer the cube while the walker keeps WASD. A Godot default action, so it exists in every project. |
| `ui_right` | 2.6 | 2.6, beside ui_left. A Godot default action. |
| quotes | 2.6 | 2 October 2026: chapter 2's 2.6 types the first string literals, the action names "ui_left" and "ui_right". Chapter 3's writer first proposed this entry at 3.1; 2.6 types an action name first, so it stands at 2.6 and chapter 3's patch dropped its copy (merge of chapters 2 to 5). The checker counts every string literal as the entry with the code form ""; String (15.1) teaches text as a value. |
| `$/` | 2.7 | inferred: 2.7 teaches parent and child; $A/B reaches B under A |
| `StandardMaterial3D` | 4.1 |  |
| `void` | 4.2 |  |
| `->` | 4.2 |  |
| `inverted` | 4.2 |  |
| `SpotLight3D` | 4.3 | taught by 4.3's idea; chapter 4's code_new does not list it |
| `light_color` | 4.3 | taught by 4.3's idea; chapter 4's code_new does not list it |
| `ui_accept` | 4.6 | 2 October 2026, student reading of chapter 2: 2.6 explained it and no code of chapter 2 used it. It moves to 4.6, where Space first reruns a rule; chapter 2's exercise 2 asks for ui_left instead. 4.7 and 18.8 use it after. The sketch never names it. 18.8's own line explaining it again was cut. |
| `new` | 4.1 | 4.1 makes each material in code: StandardMaterial3D.new(). 4.7 names the kind a class and the new one an object: SprayCan.new(). Moved from 4.8 by the chapter 4 writer, 2 October 2026; the old def needed class and object, which 4.7 gives. |
| `transparency` | 4.8 |  |
| `TRANSPARENCY_ALPHA` | 4.8 |  |
| `[]` | 5.1 |  |
| `create_empty` | 5.6 |  |
| `FORMAT_RGB8` | 5.6 |  |
| `create_from_image` | 5.6 |  |
| `albedo_texture` | 5.6 |  |
| `texture_filter` | 5.6 | TEXTURE_FILTER_NEAREST is its one value in the course: a 16 x 16 picture on a 16 metre floor stays sixteen sharp squares a side, not a blur. |
| `PlaneMesh` | 5.6 |  |
| `QuadMesh` | 5.7 |  |
| `get_noise_2d` | 11.1 | chapter 11's code_new writes get_noise_1d/2d/3d |
| `get_noise_3d` | 11.1 | chapter 11's code_new writes get_noise_1d/2d/3d |
| `SurfaceTool` | 11.7 | inferred: 11.7 builds an ArrayMesh from a grid of heights; SurfaceTool is how this course builds one |
| `begin` | 11.7 | inferred: 11.7 builds an ArrayMesh from a grid of heights; SurfaceTool is how this course builds one |
| `Mesh` | 11.7 | inferred: 11.7 builds an ArrayMesh from a grid of heights; SurfaceTool is how this course builds one |
| `PRIMITIVE_TRIANGLES` | 11.7 | inferred: 11.7 builds an ArrayMesh from a grid of heights; SurfaceTool is how this course builds one |
| `add_vertex` | 11.7 | inferred: 11.7 builds an ArrayMesh from a grid of heights; SurfaceTool is how this course builds one |
| `generate_normals` | 11.7 | inferred: 11.7 builds an ArrayMesh from a grid of heights; SurfaceTool is how this course builds one |
| `commit` | 11.7 | inferred: 11.7 builds an ArrayMesh from a grid of heights; SurfaceTool is how this course builds one |
| `Vector3i` | 18.1 |  |
| `add_task` | 18.8 |  |
| callable | 18.8 | 18.8 hands build to a thread: the function itself, not a call |
| `wait_for_task_completion` | 18.8 |  |
| `_exit_tree` | 18.8 |  |
| `WRITE` | 25.8 | 25.8 inferred: writing needs it; the sketch names it only in a 25.x exercise |

## Every finding of the run, by rule

| rule | errors | warnings | notes |
|---|---:|---:|---:|
| admin | 0 | 2 | 0 |
| gives | 0 | 102 | 9 |
| listing | 0 | 58 | 0 |
| never | 27 | 1 | 0 |
| order | 7 | 0 | 0 |
| sense | 0 | 41 | 0 |
| synonym | 0 | 36 | 0 |
| taxonomy | 0 | 6 | 0 |
| twice | 0 | 23 | 0 |
| unplaced | 0 | 4 | 0 |
| unused | 0 | 368 | 0 |

`unused` warnings say an element is taught and the sketch's own text never uses it
again; the chapters will. `gives` and `listing` warnings are about the sketch's lists,
not its order. Run the command with `--quiet-warnings` to see errors only.
