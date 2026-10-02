<!-- Round two, point-one: the earlier content a Point One reader has.
Sources: doc/book/day-zero.md (1166 prose words) and commons/maps/Point_Zero/tutorial.md (650).
Compressed to the density of L2v2 (at most 60% of source words), in short-speak, with
REPORT.md section 5 changes 1-11 and its three amended rules.
Note for the experiment: context_types.md lists the course taxonomy's sections 1.1 and 1.2
(functional/ch01.md order). These two hall lessons differ from it: they never teach Vector3,
position, origin, axis, x, y, z, coordinate or point, and Point Zero already teaches var, :=,
+=, _process, text and str, which the taxonomy places at 1.6 and 1.8. What follows is what the
two lessons themselves give. -->
# Before Point One: Day Zero and Point Zero

## Day Zero — Hello, world

*Preface, before Point Zero*

from: nothing; this is the start.

"Hello, world."
Two words, often the start of programming.
First a computer needs somewhere to run them.
The sentence is small; its arrangement is not.

Day Zero is a day for that arrangement:
downloading, configuring, waiting, asking for help, trying again.
Readying tools is work; the first point should not quietly carry it.

By Point Zero you have accepted an inheritance.
Others made the editor, the renderer, the player controller, the code that follows a hand.
You use them before you can explain them.
"You arrive late": your first instruction joins instructions already at work.

Borrowing buys time for something smaller, and sets its conditions.
enters: a supplied camera chooses the view; a player controller, how movement is received; a pickup system, what can be held.
A *supplied* part is made for you, used before it is taught.
Named, these parts do not disappear.
→ The inheritance is named; next, one project running.

### Get one project running

Start with the desktop base: a scene, no headset.
The Quest route, below, adds a device.
Use **Godot 4.6 Standard** ([archive](https://godotengine.org/download/archive/4.6-stable/)) and GDScript, no .NET; keep the study's version.
Extract the [Day Zero project](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/day-zero.zip); keep a clean copy.
`project.godot` names the *project*, and which scene starts.
`base.tscn` is the prepared *scene*: camera, light, floor, environment, greeting.
It holds its own resources, so it can be copied [alone](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/base.tscn) into another project.

In the Project Manager, **Import** `project.godot`; let the first import finish ([guide](https://docs.godotengine.org/en/4.6/tutorials/editor/project_manager.html)).
There the *editor*, Godot's window, prepares the resources.
Open `base.tscn`; run it with **Run Project**, F5.
The room should show "Hello, world."; the Output panel should print it.
Stop; select **Welcome** in the Scene tree; set its **Text** in the Inspector.
Save; run: both should show your words.
You have changed the saved project and seen it reach the running scene.
F5 starts the main scene; **Run Current Scene**, F6, starts the open one.
Learn it, with stopping and saving, until it is ordinary ([first-script lesson](https://docs.godotengine.org/en/4.6/getting_started/step_by_step/scripting_first_script.html)).
→ A project runs; next, what came with it.

### Know what has been supplied

The base gives a lit floor and a fixed view; no player, no walking, hands or XR.
Point One's studies reuse `base.tscn`, greeting hidden, for small point comparisons.
The full *museum*, the course project walked in a headset, supplies more.
Its `project.godot` enables **Godot XR Tools 4.5.1** and starts `commons/scenes/vr_staging.tscn` [read].
enters: player, movement and pickup systems; working material to inherit.
Not here: their construction. It is no entrance examination for the point.
OpenXR reaches the XR runtime; XR Tools adds interaction parts above it ([project](https://github.com/GodotVR/godot-xr-tools)).
Installing a toolkit is not designing a player.
Keep the course project's add-ons together while learning.
→ The desktop base carries the first lessons; the headset is a second setup.

### The Quest route

Use the full XR course project: the desktop base has no tracked eyes or hands.
Check first that the view follows the head and the controls work ([XR setup](https://docs.godotengine.org/en/4.6/tutorials/xr/setting_up_xr.html)).
Learn to test this supplied arrangement before building one.
Export per the [Android setup](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html): templates, Java, Android SDK.
These tools do not change the lesson's algorithm.
Then the [XR deployment guide](https://docs.godotengine.org/en/4.6/tutorials/xr/deploying_to_android.html): preset, OpenXR mode, connection, developer access.
The vendor plug-in is optional but recommended; keep the configuration together.
On the headset, look around, move, pick up a supplied object.
An image proves less than these relations working.
Solve setup here, before the first *hall*, a museum room, must explain it.
Not checked in this edition: a standalone Quest starter, a fresh headset deployment.
→ Setup ends on relations working, not on an image.

### Leave Day Zero with a place to work

State: you can find the project, open its scene, change a value, save, run, stop and return; on the Quest, the supplied player answers.
Keep that state; later passages assume it.
If setup trouble returns, come back.
Hello, world: you have made contact with something you did not make from the beginning.
→ Next: Point Zero, the first room, adds your first instruction.

> **Types** (Day Zero) · *supplied* · *project* · *scene* · *editor* · *museum* · *hall*

## Point Zero — Hello, world. We are here.

from: scene, Scene tree, Run, *supplied* (Day Zero)

Day Zero gave a place to run; here code runs at ready, and keeps running.
Open [the Point Zero study](../../../../../studies/point-zero/README.md), then `hello_world.gd`.
enters: two supplied displays, `Greeting` and `Counter`, under the root `HelloWorld`.
Replace its finished counter with this greeting:
Your attention: when something happens.

### Say hello

```gdscript
extends Node3D

func _ready():
    $Greeting.text = "Hello, world."
```

Run: "Hello, world." appears above the floor.
A *node* is one part of a scene; `extends Node3D` scripts a 3D one.
`func` starts a *function*, named instructions; its *indented* lines belong inside.
`_ready()` runs once node and children are in the scene tree; not every frame.
`$Greeting` finds the child; `=` sets its `text`, changing a display, not building letters.
Change the words: you have chosen what this arrival says.
Ready is not the world's start: the engine worked to bring it here.
→ `_ready` runs once; next, a number that goes on.

### Let a number continue

Replace the script; the whole version:

```gdscript
extends Node3D

var count := 0

func _ready():
    $Greeting.text = "Hello, world."

func _process(_delta):
    count += 1
    $Counter.text = str(count)
```

The greeting stays; a number keeps changing.
`var count := 0` makes a *variable*; `:=` infers its type, an integer.
Outside the functions, `count` keeps its value between calls.
Godot calls `_process` each *frame* while processing is on.
`count += 1` adds one; `str()` makes it text for `Counter`.
`_delta`, seconds since the last update, goes unused on purpose.
It counts calls, not seconds: a hundred updates add a hundred, however long.
→ Two functions, two moments; next, move the count.

### Once, or repeatedly?

Move the two lines into `_ready`; remove `_process`.
The whole script:

```gdscript
extends Node3D

var count := 0

func _ready():
    $Greeting.text = "Hello, world."
    count += 1
    $Counter.text = str(count)
```

Run: one, and it stays; it counts only when the node becomes ready.
Restore: both functions.
Change `count += 1` to `count += 2`: it climbs by two.
You have changed what each call does, not when calls arrive.
Restore: `count += 1`.
→ What and when are separate choices; next, when a count began.

### Whose beginning?

Your count begins with this node; a restart begins it again.
enters: the museum panel's `Engine.get_process_frames()`, frames since engine startup; not your count.
It can include work before the panel entered the room.
They can differ, neither broken: their beginnings differ.
To compare numbers, know what each counts and when it began.

State: `hello_world.gd` with both functions and `count += 1`.
→ Next: Point One returns to `_ready()` to place a marker; new material: a position.

> **Types** (Point Zero) · *node* · *function* · *indent* · *variable* · *frame*
>
> **Code** · `var` · `:=` · `+=` · `_process` · `str()`
>
> **Supplied** · `Greeting`, `Counter` · the museum's frame panel
