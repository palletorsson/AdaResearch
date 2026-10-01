# Break it on purpose, then look it up

*Workshop after Point Trace · desktop · works in fresh copies of the Point Zero, Point Lines and Point Trace studies*

So far every study has run. Here we break three of them, one fault at a time, on purpose. Before each run we say what we expect: will the scene start, what will it show, which line will the message name? Then we run, read what Godot actually reports, go to the line, and fix it. Only one fault is in the file at a time.

Start every numbered case from a fresh copy of the study it names: copy the kit folder again, or copy the one script back from the kit. The kits are [point-zero](../../studies/point-zero/README.md), [point-lines](../../studies/point-lines/README.md) and [point-trace](../../studies/point-trace/README.md). Keep your own working copies as they are. The line numbers below are the line numbers of the kit's file, so a copy that still carries an earlier case will not match them.

A note on the messages: each one below was copied from a real Godot 4.6 run of the broken file. Under most messages Godot prints a line that names a file inside the engine, such as `at: get_node (scene/main/node.cpp:1963)`; we left those lines out. Where Godot prints a whole second message from inside the engine, we show it and say so. Those runs had no editor window. Where this page says what the editor shows, it is marked *(editor)*: that describes the editor and was not watched for this page.

## 1. A name that is not there

Use a fresh point-zero copy. Open `hello_world.gd`. Misspell the display's name on line 6:

```gdscript
func _ready():
    $Greetng.text = "Hello, world."
```

Predict before you run. Does the scene start? Does the counter count?

Run it. Godot prints two messages:

```
ERROR: Node not found: "Greetng" (relative to "/root/HelloWorld").
   GDScript backtrace (most recent call first):
       [0] _ready (res://hello_world.gd:6)
SCRIPT ERROR: Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'null instance'.
   at: _ready (res://hello_world.gd:6)
```

One mistake, two messages. Read the first one first. `$Greetng` asks for a child named `Greetng`, relative to our root `HelloWorld`. There is no such child, so `$` gives back `null`: nothing. The second message is the consequence. We tried to set `text` on nothing, and nothing is what "null instance" means.

`res://hello_world.gd:6` is the file and the line; `res://` is the project's own folder. The backtrace lists the functions that were running, the most recent first. Here there is only one, `_ready`.

The two messages are of two kinds, and they behave differently.

- A **`SCRIPT ERROR`** stops the function it happens in. Run from the editor, it also pauses the game at that line and opens the Debugger panel with the message *(editor)*. Its Continue button lets the game go on.
- An **`ERROR`** does not stop the function and does not pause the game. The engine refuses one thing, prints the message, and carries on.

We checked both with Godot's command-line debugger, which attaches to the game as the editor's debugger does. Here it reported `Debugger Break` at `hello_world.gd:6`, in `_ready`. After we told it to continue, the game ran on and did not stop there again: `_ready()` runs once. In our run without a debugger, the greeting stayed empty and the counter kept counting: `_ready()` stopped at line 6, and `_process()` still ran every frame.

Fix the name. The name to match is the one in the Scene tree.

## 2. A missing colon

Still in `hello_world.gd`, take away the colon at the end of line 5:

```gdscript
func _ready()
    $Greeting.text = "Hello, world."
```

Predict: which line will the message name?

```
SCRIPT ERROR: Parse Error: Unexpected "Indent" in class body.
   at: GDScript::reload (res://hello_world.gd:6)
ERROR: Failed to load script "res://hello_world.gd" with error "Parse error".
```

A parse error is found while Godot reads the file, before any of it runs. The script is not loaded at all. The scene still started, but without its script: no greeting and no count.

The message names line 6, not line 5 where the colon is missing. Without the colon, line 5 does not open a function body. So when Godot reaches the indented line 6, that indent is still in the class body, where it does not belong. A parse error names the place where Godot noticed, and that can be a neighbour of the mistake. Read the named line and the lines around it.

Indentation is checked the same way. Put the colon back, then remove two of the four spaces before `$Counter.text` on line 10:

```
SCRIPT ERROR: Parse Error: Unindent doesn't match the previous indentation level.
   at: GDScript::reload (res://hello_world.gd:9)
```

This time the message names the line before. The script editor also lists parse errors at the bottom of its panel before you run *(editor)*.

## 3. A method a Vector3 does not have

Use a fresh point-lines copy and open `line.gd`. Line 11 measures the displacement's length. Replace it with something that reads well:

```gdscript
	var distance := a.distance(b)
```

Predict: will this fail before the run, or while it runs?

```
SCRIPT ERROR: Parse Error: Cannot find member "distance" in base "Vector3".
   at: GDScript::reload (res://line.gd:11)
SCRIPT ERROR: Parse Error: Function "distance()" not found in base Vector3.
   at: GDScript::reload (res://line.gd:11)
SCRIPT ERROR: Parse Error: Cannot infer the type of "distance" variable because the value doesn't have a set type.
   at: GDScript::reload (res://line.gd:11)
```

Three messages, one line. The first says it: a `Vector3` has no member called `distance`. The third follows from it. `:=` takes the variable's type from its value, and a call that does not exist has no type.

This is a parse error because line 8 says what `a` is: `var a: Vector3 = $A.position`. Knowing the type, Godot can check the call before anything runs.

Try the same mistake without types. Change lines 8, 10 and 11 to:

```gdscript
	var a = $A.position
	var b: Vector3 = $B.position
	var displacement = b - a
	var distance = a.distance(b)
```

Now the script loads, and the call fails only when line 11 runs. From the editor, the game pauses at line 11 and the Debugger panel shows the message *(editor)*:

```
SCRIPT ERROR: Invalid call. Nonexistent function 'distance' in base 'Vector3'.
   at: _process (res://line.gd:11)
```

Press Continue. `_process()` runs again on the next frame, reaches line 11 again, and the game pauses there again. Our command-line debugger did exactly that after each continue. Without a debugger, the game does not pause: the same message is printed every frame, and nothing after line 11 ever runs. In our run the segment stayed as the scene made it, a 2 m upright cylinder centred on the middle of the floor, and the readout kept the scene's own text, `1.50 m`. That number looks right, but no line of ours wrote it.

With the debugger attached, Godot also printed a warning: `The local variable "displacement" is declared but never used in the block.` It names line 10. That is true: line 11 no longer reads `displacement`. A warning is not an error, but it is worth reading.

A type moves the error from the run to before the run. Put the types back on lines 8 and 10 and keep the broken call on line 11. Keep this copy: *Look it up* comes back to it.

## 4. A variable filled when the node is ready

In Point Zero, `count` was a member variable: declared outside the functions, it kept its value between calls. We can keep a node in a member variable too, so that we find it once instead of every frame. Try that with a plain `var` first. In a fresh point-lines copy, put this line between `extends Node3D` and `func _ready()`, with an empty line on each side, so that it is line 3:

```gdscript
var readout: Label3D = $Readout
```

```
SCRIPT ERROR: Parse Error: The default value uses "$" which won't return nodes in the scene tree before "_ready()" is called. Use the "@onready" annotation to solve this. (Warning treated as error.)
   at: GDScript::reload (res://line.gd:3)
```

A member's starting value is taken when the script is created. At that moment our node is not yet in the scene tree, so `$Readout` could not find it. `@onready` waits: the value is taken when the node is ready, just before `_ready()` runs. Here is the whole script with `@onready`, and with the path misspelled on purpose:

```gdscript
extends Node3D

@onready var readout: Label3D = $Readuot

func _ready() -> void:
	$A.position = Vector3(-0.75, 1.12, 0.0)
	$B.position = Vector3(0.75, 1.12, 0.0)

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var b: Vector3 = $B.position
	var displacement := b - a
	var distance := displacement.length()
	$Segment.show_between(a, b)
	readout.text = "%.2f m" % distance
```

Predict which line the game will stop on, and which line the fault is on.

```
ERROR: Node not found: "Readuot" (relative to "/root/LineStudy").
   GDScript backtrace (most recent call first):
       [0] @implicit_ready (res://line.gd:3)
SCRIPT ERROR: Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'null instance'.
   at: _process (res://line.gd:15)
```

The first message is an `ERROR`. It comes once, names line 3, and does not pause the game. `@implicit_ready` is the moment Godot fills the `@onready` variables. The second is a `SCRIPT ERROR` on line 15, where `readout` is used. That is where the game pauses, and where the editor highlights *(editor)*; press Continue and it pauses at line 15 again, every frame. Without a debugger, the second message repeats every frame instead.

The fault is on line 3. The game stops twelve lines further down, and only the first message, printed once before the pause, points at the cause. Scroll up to it. Fix the spelling and the readout returns.

## 5. The wrong type

Use a fresh point-lines copy. Drop the formatting on line 13:

```gdscript
	$Readout.text = distance
```

```
SCRIPT ERROR: Invalid assignment of property or key 'text' with value of type 'float' on a base object of type 'Label3D'.
   at: _process (res://line.gd:13)
```

From the editor, the game pauses at line 13, and again at each Continue *(editor)*; without a debugger the message repeats every frame. `text` holds a `String`. `distance` is a `float`, a number with a fractional part. `"%.2f m" % distance` made text from it, as `str(count)` did for a whole number in Point Zero. This error waited for the run because `$Readout` has no declared type. Put line 13 back, and give the variable a wrong type instead, on line 11:

```gdscript
	var distance: String = displacement.length()
```

```
SCRIPT ERROR: Parse Error: Cannot assign a value of type float to variable "distance" with specified type String.
   at: GDScript::reload (res://line.gd:11)
```

Declared, the mismatch is found before the run.

A list has a type too. Use a fresh point-trace copy and open `trace.gd`. Line 3 declares the recorder's list. Put the wrong kind of value into the declaration:

```gdscript
var trace: Array[Vector3] = ["here"]
```

Predict: before the run, or during it?

```
SCRIPT ERROR: Parse Error: Cannot include a value of type "String" as "Vector3".
   at: GDScript::reload (res://trace.gd:3)
SCRIPT ERROR: Parse Error: Cannot have an element of type "String" in an array of type "Array[Vector3]".
   at: GDScript::reload (res://trace.gd:3)
```

Before it. Read the first message first: the value `"here"` is a `String`, and it cannot be a `Vector3`. The second says the same thing about the list as a whole. In Trace we met the other half: `trace.append("here")` is refused only when it runs, with an `ERROR` that does not stop the game.

One more list fault. Put the declaration back to `= []`. On line 28, inside `keep()`, take away the question the recorder asks first, so that the line reads:

```gdscript
	if (p - trace[-1]).length() >= gate:
```

```
SCRIPT ERROR: Out of bounds get index '-1' (on base: 'Array[Vector3]')
   at: keep (res://trace.gd:28)
   GDScript backtrace (most recent call first):
       [0] keep (res://trace.gd:28)
       [1] _process (res://trace.gd:23)
```

An empty list has no last entry, and the list is empty on the first frame. From the editor, the game pauses at line 28, and again at each Continue *(editor)*: the list stays empty, so every frame asks again. Without a debugger, the message repeats every frame and nothing is ever kept.

This backtrace has two entries. `[0]` is where the error happened, in `keep`. `[1]` is the line that called `keep`: line 23, in `_process`. Our command-line debugger listed the same two frames when we asked it for the backtrace, and the editor's Debugger panel lists them as its stack frames *(editor)*. When the failing line is right and its input is wrong, the caller is the next place to look.

Put back `trace.is_empty() or`. It is the reason the recorder asks whether its list is empty before it reads `trace[-1]`.

## A fault with no error

Use a fresh point-lines copy. On line 13, format the wrong number:

```gdscript
	$Readout.text = "%.2f m" % displacement.x
```

Run it. The readout shows `1.50 m`, as before. Now give B the position `Vector3(-0.75, 2.62, 0.0)` in `_ready()`. The segment stands upright and is still 1.5 m long. The readout shows `0.00 m`. No error is printed.

There is one clue. With a debugger attached, Godot printed a warning: `The local variable "distance" is declared but never used in the block.` It names line 11. The editor shows the same kind of warning in the script editor *(editor)*. `distance` is never used because line 13 now reads `displacement.x` instead.

A wrong type can be just as quiet. Restore line 13 and change line 11 to `var distance: int = displacement.length()`. The readout shows `1.00 m`: an `int` keeps only the whole number. Again no error, and again a warning with the debugger attached: `Narrowing conversion (float is converted to int and loses precision).`, at line 11. Warnings are worth reading.

Some faults leave no warning either. In a fresh point-trace copy, change `trace.pop_front()` on line 31 to `trace.pop_back()`, and walk B for a while. Once 32 positions are kept, the count stays at 32 and the pink line stops following B. Its end stays where the 32nd position was kept. `pop_back()` removes the last entry, which is the one just appended, so each new position is thrown away as it arrives. Nothing is printed, with or without a debugger.

These are found only by watching a value. That is what `print()` and the debugger are for.

## Look it up

### The class reference

Go back to case 3's copy, where `a.distance(b)` does not exist. Open Search Help, F1, and look up `Vector3` *(editor)*. Its page lists every method a `Vector3` has. Find the one that gives the distance between two vectors: `distance_to`. Ctrl+click on a name in the script editor opens its page too *(editor)*. The same reference is online at [docs.godotengine.org/en/4.6/classes/class_vector3.html](https://docs.godotengine.org/en/4.6/classes/class_vector3.html).

```gdscript
	var distance := a.distance_to(b)
```

Run it. The readout shows `1.50 m` again: `distance_to` gave 1.5 for A and B in our run. Now open the page for `Array` and find one method Trace did not use. Say what it returns before you try it.

### print()

Add one line at the end of `_ready()`:

```gdscript
	print("A is at ", $A.position, " and B is at ", $B.position)
```

The Output panel receives:

```
A is at (-0.75, 1.12, 0.0) and B is at (0.75, 1.12, 0.0)
```

`print()` joins its values into one line. In `_ready()` it prints once. In `_process()` it would print every frame.

### A breakpoint

Remove the `print` line again, so that the line numbers are the kit's. Then put the word `breakpoint` on its own line after line 11:

```gdscript
	var distance := a.distance_to(b)
	breakpoint
	$Segment.show_between(a, b)
```

Run it. The game stops at line 12, before the segment is drawn. Godot's command-line debugger reported:

```
Debugger Break, Reason: 'Breakpoint Statement'
*Frame 0 - res://line.gd:12 in function '_process'
```

and the local variables at that moment:

```
_delta: 0.01666666666667
a: (-0.75, 1.12, 0.0)
b: (0.75, 1.12, 0.0)
displacement: (1.5, 0.0, 0.0)
distance: 1.5
```

In the editor, the Debugger panel shows these as the stack frames and the stack variables, and its Continue button lets the game go on *(editor)*. You can also set a breakpoint by clicking in the margin beside a line number *(editor)*. The breakpoint is inside `_process()`, so the game stops again on the next frame: in our run, each continue ran one more frame and stopped at line 12 again. Remove it when you are done.

The debugger listed `displacement` among the variables, and Godot warned once more that it is declared but never used, on line 10. With `distance_to`, line 11 no longer needs it. Deleting line 10 would be the tidy fix.

## Your own fault

Plant one fault of your own in a copy of one of your studies. Give it to someone. Ask them to predict before they run, and time how long they take to find it.

## What we carry

Predict, run, read the first message, go to its line and look at its neighbours, change one thing, run again. A `SCRIPT ERROR` stops its function and pauses the game at its line; an `ERROR` is printed and the game goes on; a warning is a clue. When the line that fails is not the cause, scroll up to the first message, or read down the backtrace to the caller. When a name is unknown, the class reference is the first place to look. When there is no message, watch a value.

At the checkpoint, one of the tasks is to find a planted error from its message alone.
