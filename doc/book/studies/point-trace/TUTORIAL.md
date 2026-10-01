# Point Trace — let positions remain

Lines ended on a question. The same two ends give the same displacement, however we travel between them. Our script read both positions again each frame and kept no journey. Here we keep positions in order, and decide which ones.

In the hall, [the reading](../../../../commons/maps/Point_Trace/final.md) begins with pens you draw with in the air. This study keeps one decision from that encounter: when a position is worth keeping. The pens stay in the museum.

This study takes two sessions. The first keeps positions in a list, asks before keeping one, and draws what was kept. It ends at **Stop here**, with a check of what we have. The second measures the route, gives the list a capacity, moves the keeping into a function of our own, and adds a pause.

## Open the study

Open the [Point Trace study](README.md), then `trace.tscn`. It inherits `line.tscn`, the finished Lines study, so A, B, the segment and the distance readout are the ones we made there. The download also contains `line.tscn` and `line.gd` unchanged; `line.tscn` still runs on its own.

`trace.tscn` changes five things. The root runs `trace.gd` instead of `line.gd`. B carries `mover.gd`, a supplied hand. A new node, `Strip`, carries `trace_strip.gd`, a supplied display. A second label, `Record`, sits above the readout. The borrowed camera is raised so we look down at the floor.

Run it. Press W, A, S and D, or the arrow keys. B moves parallel to the floor, at its height of 1.12 m. The segment stretches from A and the distance follows, as in Lines. A pink line stays behind B. The Record label counts the kept positions and gives two lengths. Stop moving: the count stops. Press Space, move, and press Space again: the line waits, then jumps.

`trace.gd` is ours. The download holds the finished version. We will take it apart and build it again.

Every message and number on this page comes from running the study in Godot 4.6. Where the page describes the editor's own windows and buttons, it is marked *(editor)*: those runs had no editor window, so that part is described, not watched.

## A hand with names

Open `mover.gd`. This part answers the keys:

```gdscript
func _process(delta: float) -> void:
	if autopilot:
		_drive(delta)
		return
	# x: left -1 .. right +1; y: forward -1 .. backward +1. A diagonal is no longer than 1.
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	position.x = clampf(position.x + input.x * speed * delta, -area.x, area.x)
	position.z = clampf(position.z + input.y * speed * delta, -area.y, area.y)
```

`Input.get_vector()` takes four action names, in the order negative x, positive x, negative y, positive y, and returns a `Vector2`. Holding D gives `(1, 0)`. Holding W gives `(0, -1)`; we add its y to B's z, so B moves away from the camera. Holding D and S together gives about `(0.71, 0.71)`. Its length stays 1, so a diagonal is no faster than a straight move.

Point Zero's counter ignored `_delta`. Here we use it. `delta` is the time since the last frame, in seconds, so `speed * delta` is this frame's share of 1.2 metres a second. Held for half a second, a key moves B 0.6 metres, however many frames arrive in between. `clampf()` keeps each coordinate inside `area`, the part of the floor we can see.

`speed`, `autopilot` and `area` are declared at the top of the file with `@export` in front. `@export` makes a value editable in the Inspector: select B, and the three appear there with their values.

The four names are defined in the project, not in the script. Open **Project > Project Settings** and its **Input Map** tab. `move_left` lists A and Left; `move_right`, D and Right; `move_forward`, W and Up; `move_backward`, S and Down. There is a fifth, `pause`, with Space. We will come back to it.

Point One's `contact_probe.gd` asked for the key itself:

```gdscript
if event.physical_keycode == KEY_SPACE:
```

That line can only ever mean Space. A named action means whatever the Input Map binds to it. Bind `move_left` to another key there, and `mover.gd` follows without an edit.

For hands-off running, select B and tick **Autopilot** in the Inspector. B then runs a slow figure-eight from where it stands: 2.5 seconds moving, 1 second still, again and again. The keys do nothing while it is ticked.

We borrow the rest of `mover.gd`. Read all of it; change `speed`, `area` or the figure-eight's numbers. Writing input handling of our own waits for a later room.

## Start with an empty list

Replace everything in `trace.gd` with this. It is the Lines script and two new lines.

```gdscript
extends Node3D

var trace: Array[Vector3] = []

func _ready() -> void:
	$A.position = Vector3(-0.75, 1.12, 0.0)
	$B.position = Vector3(0.75, 1.12, 0.0)
	print(trace.size())

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var b: Vector3 = $B.position
	var displacement := b - a
	var distance := displacement.length()
	$Segment.show_between(a, b)
	$Readout.text = "%.2f m" % distance
```

Run it. The Output panel shows `0`. B still moves and the segment follows. The pink line and the Record label have gone: nothing tells them what to show.

`Array[Vector3]` is a list that holds `Vector3` values in order. `[]` is a list with nothing in it yet. Like Point Zero's `count`, `trace` is declared outside the functions, so it belongs to the node and keeps its contents between calls. `size()` counts the entries.

The kit's scripts are indented with tabs, and so is the code on this page. Godot accepts spaces or tabs, but not both in one file. If a line disagrees with the rest of the file, running it stops with `Parse Error: Used space character for indentation instead of tab as used before in the file.`, or `Used tab character for indentation instead of space as used before in the file.` Make the indentation match. The script editor may convert the indentation for us when it saves the file *(editor)*.

## Keep every frame

Under the readout line in `_process`, add:

```gdscript
	trace.append(b)
	$Record.text = "%d kept" % trace.size()
```

Run it and leave the keys alone. The count climbs while B stands still: one position per frame. `append()` puts a value at the end of the list. `_process` runs once a frame, and nothing stops the append. `%d` writes a whole number, as `%.2f` wrote the distance in Lines.

How fast it climbs depends on the machine, not on B. Add `Engine.max_fps = 20` to `_ready()` and run again: the count now climbs by about twenty a second. Remove the line. A recorder that keeps a position every frame records the frame rate as much as the movement. This is a gate of zero. We will meet it again.

The list checks its type as it grows. Add `trace.append("here")` to `_ready()` and run. Godot reports two errors:

```
ERROR: Attempted to push_back a variable of type 'String' into a TypedArray of type 'Vector3'.
ERROR: Condition "!_p->typed.validate(value, "push_back")" is true.
```

The first is written for us: a `String` cannot go into a list of `Vector3`. The second names a check inside the engine's own code; when one message follows another like this, the first is the one about our script. Nothing is added, and the study keeps running. Remove the line. (Here and below we leave out the lines under each message that name files inside the engine.)

## Ask before keeping

Replace `trace.append(b)` with a condition:

```gdscript
	if trace.is_empty() or b != trace[-1]:
		trace.append(b)
```

Run it. Standing still, the count stays at 1. Moving, it climbs one per frame again.

This is the first `if` we write. `if` runs the indented line under it only when its condition is true. `!=` means "is not equal to".

Entries in a list are numbered from 0: `trace[0]` is the first, `trace[1]` the second. A negative index counts back from the end, so `trace[-1]` is the last. The condition reads: keep `b` if the list is empty, or if `b` is not where we last kept it.

An empty list has no last entry. Swap the two sides of `or`, so that the line reads `if b != trace[-1] or trace.is_empty():`, and run. At once Godot reports `SCRIPT ERROR: Out of bounds get index '-1' (on base: 'Array[Vector3]')` and names the `if` line. A `SCRIPT ERROR` stops the function it happens in, so nothing is ever kept. Run from the editor, the game also pauses on that line and the Debugger panel shows the message *(editor)*. Stop the game and swap the sides back.

`or` stops as soon as its left side is true. With `trace.is_empty()` on the left, the first frame never reads `trace[-1]`.

## Far enough

Under `var trace`, add a member:

```gdscript
var gate := 0.1
```

and change the condition to a distance:

```gdscript
	if trace.is_empty() or (b - trace[-1]).length() >= gate:
		trace.append(b)
```

Run it. Standing still adds nothing. Moving adds one position for every ten centimetres or so. Hold D for about a second: B moves about 1.2 m, and the count reaches about 11 or 12, counting the position B started on. The count follows the distance travelled, not the time. (In our runs, stepped at 30, 60, 120 and 144 frames a second, one second of D moved B 1.20 m and left 11 or 12 kept.)

The measurement is the one we wrote in Lines: subtract, then take the length. `b.distance_to(trace[-1])` returns the same number. We keep the subtraction because we already know what it does, and it names both ends. The gate is measured from the last kept position, not from where B was a frame ago. Many small steps add up until one crosses it.

Now set `gate` to `0.0`. The count climbs while B stands still again: a distance of zero passes `>=`. That is the recorder from the last section. Change `>=` to `>` and run: standing still adds nothing, and moving adds one per frame, as with `!=`. Put back `>=` and `0.1`.

Stand still for a while, then move on. The list does not show that you waited. It holds positions, not times.

## Draw what was kept

After the `if` block, add:

```gdscript
	$Strip.draw(trace)
```

Run it. A pink line follows B.

`draw()` belongs to `trace_strip.gd`, which we use without opening. Its contract is one sentence: give it the whole list each frame, and it joins each position to the next with a straight segment. Fewer than two positions draw nothing. The positions are in the root's frame, and the strip sits unmoved at the root's origin, so no conversion is needed. We open its code in Point_Triangle_Context, when we build a surface from points.

Set `gate` to `0.4` and draw a curve. Corners appear: the line is straight pieces between kept positions. Over one autopilot figure-eight, stepped at 60 frames a second, a gate of 0.1 m kept 79 positions and a gate of 0.4 m kept 21. Return to `0.1`.

## Stop here: what we have

This is the end of the first session. Run the study once more and check four things:

- The Output panel shows `0` as the study starts.
- Standing still, the count does not change.
- Moving, the count grows by about one for every ten centimetres.
- A pink line follows B, made of straight pieces between the kept positions.

If one of them fails, compare your script with this one, which is where the first session ends:

```gdscript
extends Node3D

var trace: Array[Vector3] = []
var gate := 0.1

func _ready() -> void:
	$A.position = Vector3(-0.75, 1.12, 0.0)
	$B.position = Vector3(0.75, 1.12, 0.0)
	print(trace.size())

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var b: Vector3 = $B.position
	var displacement := b - a
	var distance := displacement.length()
	$Segment.show_between(a, b)
	$Readout.text = "%.2f m" % distance
	if trace.is_empty() or (b - trace[-1]).length() >= gate:
		trace.append(b)
	$Strip.draw(trace)
	$Record.text = "%d kept" % trace.size()
```

Save the project. The second session starts from this script.

## The route and the straight line

Add two functions at the end of the script:

```gdscript
func route_length() -> float:
	var total := 0.0
	for i in range(1, trace.size()):
		total += (trace[i] - trace[i - 1]).length()
	return total

func straight_length() -> float:
	if trace.is_empty():
		return 0.0
	return (trace[-1] - trace[0]).length()
```

and replace the Record line:

```gdscript
	$Record.text = "%d kept\nroute %.2f m\nstraight %.2f m" % [trace.size(), route_length(), straight_length()]
```

`-> float` says the function gives back a number, and `return` gives it. Point One's `-> void` said a function gives back nothing.

`for i in range(1, trace.size()):` runs the indented line once for each `i` from 1 up to, but not including, the list's size. Each pass measures one piece, from entry `i - 1` to entry `i`, and adds it to `total`. With fewer than two entries the loop does not run, and the total stays 0.

`straight_length()` measures from the first kept position, `trace[0]`, to the last, `trace[-1]`. `\n` starts a new line in the label. With several values, `%` takes them in a list, in order.

Run it. Walk B along a straight line: route and straight agree. Walk a corner, or go out and come back: the route grows and the straight distance does not.

For a closer look, stop and run the study again, so that the list starts fresh. Hold D for a little under a second, then W for as long. With two legs of 1 m, the ideal reading is route 2.00 m and straight 1.41 m. The label will be close: a run stepped at 60 frames a second read route 1.97 m, straight 1.41 m. Out 1 m and back again read route 1.92 m, straight 0.00 m. The route falls a little short because a position is kept only once B is ten centimetres from the last one, so the corner itself, or the turning point, may never be kept, and the route cuts across it.

This answers the question Lines left. The displacement from first to last is the same however we travel. The route is the sum of the pieces we kept. They agree only when every piece points the same way along one line.

The route is measured along the kept positions, not along B's movement. A wide gate cuts corners, so it measures less: over the same figure-eight, 8.52 m at a gate of 0.1 and 8.16 m at 0.4. A narrower gate adds almost nothing: 8.51 m at 0.02.

## Give the list a capacity

Under `var gate`, add:

```gdscript
var capacity := 32
```

and inside the `if` block, under the append:

```gdscript
		if trace.size() > capacity:
			trace.pop_front()
```

Run it and keep moving. After 32 positions the count stays at 32, and the far end of the line begins to leave. `pop_front()` removes the first entry, which is the oldest; `append()` always puts the newest at the end. The route and straight distance now describe only what the list still holds. Thirty-two positions make 31 pieces of at least ten centimetres, so the route holds at least 3.1 m; our run held 3.58 m.

Stand still. Nothing leaves. The capacity counts positions, not seconds.

## A function of our own

The lines that keep a position now sit four deep inside `_process`. We give them a name. Add this function under `_process`, before `route_length()`:

```gdscript
func keep(p: Vector3) -> void:
	if trace.is_empty() or (p - trace[-1]).length() >= gate:
		trace.append(p)
		if trace.size() > capacity:
			trace.pop_front()
```

In `_process`, replace the whole `if` block, all four lines, with one call:

```gdscript
	keep(b)
```

Run it. Nothing changes: the same lines run, called from a new place.

`p` is a parameter. The value we write between the brackets when we call `keep(b)` arrives inside `keep` under the name `p`. Inside `keep`, `b` is unknown: it belongs to `_process`. So the function says `p` wherever the old lines said `b`. `-> void` says `keep` gives nothing back; its work is the change it makes to `trace`.

Compare `route_length()`. It takes nothing in, and gives back a `float`. `keep(p)` takes a position in, and gives nothing back.

For one run, change the call to `keep(a)`. A does not move, so the count stays at 1 and no line is drawn: `keep` kept what it was handed. Put back `keep(b)`.

## Pause the recorder

Now the fifth action. The download lists `pause` so that the finished script runs. Remove it from the Input Map first: in **Project > Project Settings > Input Map**, find `pause` and click the remove button, a bin, at the end of its row *(editor)*. We will add it back ourselves.

Under `var capacity`, add:

```gdscript
var recording := true
```

and in `_process`, replace `keep(b)` with:

```gdscript
	if Input.is_action_just_pressed("pause"):
		recording = not recording
	if recording:
		keep(b)
```

Remove `print(trace.size())` from `_ready()`; the Record label shows the count now.

Run it. Godot reports `ERROR: The InputMap action "pause" doesn't exist.`, once per frame. It is an `ERROR`, not a `SCRIPT ERROR`: the study keeps running, B moves and the recorder keeps recording, but Space does nothing. The script asks for a name the project does not define.

Stop the study. In the Input Map, type `pause` into the **Add New Action** field and press **Add**. Click the **+** at the end of the new row, press Space when the window asks for an input, and click **OK** *(editor)*. Run again. The errors are gone.

Press Space and move B. The segment and the distance still follow; the pink line waits. Press Space again. The line jumps straight to where B is: the first position after the pause is far from the last one kept, so it passes the gate at once, and the strip joins the two with one straight piece. The route counts that piece as if B had walked it.

`is_action_just_pressed()` is true only in the frame in which the key went down. `recording = not recording` turns true into false, or false into true. `is_action_pressed()` is true in every frame while the key is held; with it, the recorder switches on and off each frame for as long as you hold Space. Try it, then put `just` back.

The whole script now reads as the `trace.gd` in the download:

```gdscript
extends Node3D

var trace: Array[Vector3] = []
var gate := 0.1
var capacity := 32
var recording := true

func _ready() -> void:
	$A.position = Vector3(-0.75, 1.12, 0.0)
	$B.position = Vector3(0.75, 1.12, 0.0)

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var b: Vector3 = $B.position
	var displacement := b - a
	var distance := displacement.length()
	$Segment.show_between(a, b)
	$Readout.text = "%.2f m" % distance

	if Input.is_action_just_pressed("pause"):
		recording = not recording
	if recording:
		keep(b)
	$Strip.draw(trace)
	$Record.text = "%d kept\nroute %.2f m\nstraight %.2f m" % [trace.size(), route_length(), straight_length()]

func keep(p: Vector3) -> void:
	if trace.is_empty() or (p - trace[-1]).length() >= gate:
		trace.append(p)
		if trace.size() > capacity:
			trace.pop_front()

func route_length() -> float:
	var total := 0.0
	for i in range(1, trace.size()):
		total += (trace[i] - trace[i - 1]).length()
	return total

func straight_length() -> float:
	if trace.is_empty():
		return 0.0
	return (trace[-1] - trace[0]).length()
```

## Try

Choose your own recorder. Set `gate` to `0.4` and `capacity` to `8`: a short, angular tail that forgets quickly. Or a gate of `0.02` and a capacity of `400`. Bind `pause` to a second key in the Input Map; the script does not change.

## Carry it elsewhere

Record A instead. Take `mover.gd` off B: select B, find **Script** at the bottom of the Inspector, open its menu and choose **Clear** *(editor)*. Then drag `mover.gd` from the FileSystem dock onto A in the Scene tree *(editor)*. Change `keep(b)` to `keep(a)`. Run it. A moves, the segment and the distance follow, and the pink line follows A. Nothing new was needed: `keep` does not know which point it is handed. The checkpoint after the next workshop carries the recorder further, into another study.

Then decide what your recorder loses. Every choice here drops something: the gate drops small movements, the capacity drops the oldest positions, the pause drops a stretch of route, and the list drops time. Choose a gate, a capacity, and one loss you want. Write a comment at the top of `trace.gd` that says what your recorder forgets, and why.

## What we borrowed

| Part | From | How far we go |
| --- | --- | --- |
| `base.tscn`: floor, light, camera | Day Zero | Used as it is. `trace.tscn` raises the camera. |
| `line.tscn`, `segment.gd` | Point Lines | Inherited. The rotation in `show_between()` stays borrowed. |
| `mover.gd` | Supplied here | Understand: read it, change its numbers, rebind its actions. |
| `trace_strip.gd` | Supplied here | Use: call `draw(points)`. Opened in Point_Triangle_Context. |
| Input Map actions | `project.godot` | Use by name. We add `pause` ourselves. |

What we made is `trace.gd`: a typed list, a condition, a gate, a loop with a job, a function that takes a value in, a capacity and a pause.

## What we carry forward

We leave with an ordered, capped `Array[Vector3]`, a gate we chose, a summed route length, a function that keeps whatever position it is handed, and named input actions. The next workshop, *Break it on purpose*, breaks copies of Point Zero, Point Lines and this recorder, one fault at a time, and reads Godot's messages. Point_Line_Grid then snaps a copy of a recorded list to a spacing we choose and compares it with the original. The list holds no times, so no later room can recover how long a pause lasted.
