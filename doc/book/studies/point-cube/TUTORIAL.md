# Point Cube — when things go wrong: the drafter is a machine

Plane left us with three moves of `SurfaceTool`, normals, a collider, and three instruments: a marble for the body, a second camera for the far side, and a sheet that measures stills. We also learned what a counter-clockwise triangle looks like from the front: nothing. Here we build a cube from 8 corners and 12 triangles. We write one face ourselves. We hand the other five to a drafter, with a written instruction, and then we do the real work of this chapter: we check what comes back, repair it, and ship it as a build.

In the hall, [the reading](../../../../commons/maps/Point_Animatedcube/final.md) lets you pull one corner of a cube and find the crease: "The diagonal was already there." A square face is two triangles, stored as two triples of corner numbers. This study uses the hall's eight corners and the hall's numbering.

The drafter can be an AI assistant. This study does not need one. The download holds two answers, `drafted_cube.gd` and `drafted_vague.gd`. Both were written for this kit, as examples of typical faults; no assistant produced them. You may put the same instruction to a real assistant and check its answer the same way.

The workshop [Break it on purpose](../../course/opening/W01_break_it_on_purpose.md) is the catalogue of Godot's messages and how to read them. This chapter is its companion: there the message was the clue, and here most faults give no message.

This study takes two sessions. The first builds a face, asks, debugs and repairs. It ends at **Stop here**. The second compares two answers on a sheet, exports a build, and takes the cube to your room.

Every message and number on this page comes from running the study in Godot 4.6. Parts marked *(editor)* describe the editor's own windows and were not watched.

## Open the study

Open the [Point Cube study](README.md), then `cube.tscn`. It inherits `plane.tscn`, the finished Plane study. The root still runs `plane.gd`, so the walk, Enter, F, the marble on M and the view from below on V are the ones we left there. There are no new keys.

`cube.tscn` adds two nodes. `Cube` is an empty mesh node with an orange material, standing at (1.05, 1.37, 0.6). `Body`, its child, is a static body with an empty collision shape. `Cube` runs `cube.gd`.

Run it. An orange cube, half a metre on every edge, stands to the right, at the height B walks at. Walk B under it: hold D, then S, until the cube hides B. Press M. The marble falls from one metre above B and stays on the cube; the Record reads `marble at 1.71 m`. Hold V: we look at the cube's dark underside.

`cube.gd` is ours. The download holds the finished version. We will take it apart and build it again.

## Eight corners

Replace everything in `cube.gd` with this:

```gdscript
extends MeshInstance3D

var corners: Array[Vector3] = [
	Vector3(-0.25, -0.25, -0.25),   # 0 bottom back left
	Vector3(0.25, -0.25, -0.25),    # 1 bottom back right
	Vector3(0.25, 0.25, -0.25),     # 2 top back right
	Vector3(-0.25, 0.25, -0.25),    # 3 top back left
	Vector3(-0.25, -0.25, 0.25),    # 4 bottom front left
	Vector3(0.25, -0.25, 0.25),     # 5 bottom front right
	Vector3(0.25, 0.25, 0.25),      # 6 top front right
	Vector3(-0.25, 0.25, 0.25),     # 7 top front left
]

func _ready() -> void:
	print(corners.size(), " corners; corner 6 is at ", corners[6])
```

Run it. The cube is gone, and the Output panel reads `8 corners; corner 6 is at (0.25, 0.25, 0.25)`.

A list can be written out between square brackets, one entry after another. This one holds eight positions, numbered from 0 as every list is. Each is one of the eight ways to combine −0.25 and 0.25. The comments name them for a viewer at our camera: left is −x, bottom is −y, back is −z.

The positions are measured from the `Cube` node's own origin, as local positions were in Coordinates. So the cube's middle is the node, and the node stands at a height of 1.37 m: the bottom corners lie at 1.12 m, the height of the walk.

Nothing is drawn. Eight positions are not a surface. The list does not say which corners belong together.

## One triangle, then one face

Replace `_ready()` with this:

```gdscript
var triangles: Array = [
	[4, 7, 5],
]

func _ready() -> void:
	build()

func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(triangles.size()):
		var triangle: Array = triangles[t]
		surface.add_vertex(corners[triangle[0]])
		surface.add_vertex(corners[triangle[1]])
		surface.add_vertex(corners[triangle[2]])
	mesh = surface.commit()
```

Run it. One orange triangle stands where the front of the cube was: half a square.

`triangles` is a list of lists. Each inner list is a triple: three corner numbers. `triangles[t]` is one triple, `triangle[0]` is its first number, and `corners[triangle[0]]` is the position that number names. The three moves are Plane's: begin, three calls of `add_vertex()` for each triangle, commit. The mesh goes to `mesh`, this node's own property; in Plane we wrote `$Face.mesh` from outside.

The front face has the corners 4, 5, 6 and 7. Seen from the camera, 4 is bottom left, 7 is top left, 5 is bottom right: `[4, 7, 5]` runs clockwise, so it faces us.

Now write the second triangle yourself. The corner still missing is 6. Add a triple to the list so that the square is whole, and run. If half is still missing, your triple runs the other way: swap two of its numbers. Two triangles of one face share an edge. Ours share 5 and 7:

```gdscript
var triangles: Array = [
	[4, 7, 5], [5, 7, 6],   # front
]
```

The hall stores this face as `[4, 5, 7]` and `[5, 6, 7]`. Try those two for one run: nothing appears. In our stills the face covered 0.55% of the frame from above in our order and 0.00% in the hall's; a camera behind the cube saw the hall's face on 2.03%. The same corners in the other order face away from us. The hall's builder can use that order because it hands over every triangle twice, once each way round. Put our triples back.

## Normals and a body

Replace `build()` with this. It has three new lines:

```gdscript
func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for t in range(triangles.size()):
		var triangle: Array = triangles[t]
		surface.add_vertex(corners[triangle[0]])
		surface.add_vertex(corners[triangle[1]])
		surface.add_vertex(corners[triangle[2]])
	surface.generate_normals()
	mesh = surface.commit()
	$Body/CollisionShape3D.shape = mesh.create_trimesh_shape()
```

Run it. The face looks as it did: rendered before and after, the two stills differed on 0.00% of the frame. The lines are for the cube it will become.

`generate_normals()` and `create_trimesh_shape()` are Plane's. `set_smooth_group(-1)` is new: it lets every triangle keep its own direction. Without it, `generate_normals()` blends the directions of triangles that meet at a corner. On a plane they all agree, so we never saw it. On a cube three faces meet at each corner. We rendered the finished cube both ways: the two stills differed on 0.60% of the frame, where the whole cube covers 1.31%. With blended normals the faces shade into one another and the edges go soft.

One line of Plane's is missing on purpose. There we switched `backface_collision` on, so that the plane held a body from both sides. A cube is closed, and nothing should reach its faces from behind. We leave the collider at its default, where the body's side is the eye's side. That makes the marble an instrument for this chapter: it falls through a face that is inside out.

## Three lines before we ask

Five faces are missing: ten triples. That is copying work with one rule, and we will give it away. Before we ask, we write three lines:

```
Change:    add ten triples to `triangles`, so that the cube has six faces of two triangles each.
Keep:      my eight corners and their numbers, my two front triples, and build().
           Godot draws the side from which the corners run clockwise.
Wrong if:  a marble dropped over the top does not come to rest on it, at about 1.72 m,
           or I can see into the cube from any side.
```

The first line says what should change, and nothing more. The second says what must not change, and gives the one fact about our engine the drafter cannot see from the script. The third is for us. It names one observation that would show the result is wrong, and it must be one we can make with what we have: the marble, Under, the sheet. 1.72 m is the top of the cube, 1.62 m, and the marble's radius.

We send the three lines with the whole script. An assistant sees what we send. It does not see the scene tree, the running study or the marble.

## The first answer

Open `drafted_cube.gd` and read it against our script. The corners are ours. `build()` is ours. The first two triples are ours. The second line was kept. The list has ten more:

```gdscript
var triangles: Array = [
	[4, 7, 5], [5, 7, 6],   # front (yours, unchanged)
	[1, 2, 0], [0, 2, 8],   # back
	[0, 3, 4], [4, 3, 7],   # left
	[5, 6, 1], [1, 6, 2],   # right
	[2, 3, 6], [3, 7, 6],   # top
	[0, 4, 1], [1, 5, 5],   # bottom
]
```

It reads well: six faces, two triples each, every face named. Copy this list into `cube.gd` in place of ours, and leave `drafted_cube.gd` as it is: it is the first answer, and we keep it. Predict before you run: will there be a cube?

Run it. No cube, not even our face. Godot reports:

```
SCRIPT ERROR: Invalid access of index '8' on a base object of type: 'Array[Vector3]'.
   at: build (res://cube.gd:34)
   GDScript backtrace (most recent call first):
       [0] build (res://cube.gd:34)
       [1] _ready (res://cube.gd:24)
```

Read it as the workshop taught. A `SCRIPT ERROR` stops its function, so `commit()` never ran and there is no mesh at all. Line 34 is the third `add_vertex` line. The index is 8, and eight corners are numbered 0 to 7.

Line 34 is our own line, and it is right. Its input is wrong. The message names the place where Godot noticed, not the triple that asked. To find the triple, print the loop's index. Under the `var triangle` line, add:

```gdscript
		print(t, " ", triangle)
```

Run it. The Output panel reads:

```
0 [4, 7, 5]
1 [5, 7, 6]
2 [1, 2, 0]
3 [0, 2, 8]
```

and then the same error, one line further down. The last line printed is the pass that failed: triple 3, `[0, 2, 8]`.

The debugger finds the same thing without the extra line. Run from the editor, the study pauses at line 34 and the Debugger panel lists the variables of that moment *(editor)*. We asked Godot's command-line debugger, which attaches as the editor's does: it stopped at `cube.gd:34` in `build` and showed `t: 3` and `triangle: [0, 2, 8]`. To watch a loop pass by pass, click in the margin beside the `var triangle` line to set a breakpoint, run, and press Step Over, F10: `t` and `triangle` change in the panel each time round *(editor)*.

Before we repair the triple, we make the loop say this itself. Remove the `print` line and put three lines in its place:

```gdscript
		if triangle.max() >= corners.size():
			push_error("triangle %d asks for a corner that is not there: %s" % [t, triangle])
			continue
```

Run it:

```
ERROR: triangle 3 asks for a corner that is not there: [0, 2, 8]
```

and a cube appears. Under the message Godot names our line 33, as it named line 34 before. `max()` gives the largest entry of a list. `push_error()` prints a message of our own as an `ERROR`. `continue` leaves this pass of the loop and goes on with the next, so one bad triple no longer costs us the other eleven. An `ERROR` is not a `SCRIPT ERROR`: the function runs to its end.

Now the repair. Triple 3 belongs to the back face, whose corners are 0, 1, 2 and 3. Its partner is `[1, 2, 0]`. They share 0 and 2, so the corner still missing is 3. Change `[0, 2, 8]` to `[0, 2, 3]` and run: no message.

## Check it against the third line

The cube looks almost right, and Godot is silent. Now we do what the third line says.

Look from above. The front is there, and a sliver of the left side. The top is not: we see the floor through the cube. In our stills this cube covered 0.69% of the frame, where a whole one covers 1.31%. Walk B under it and press M. The marble falls through the cube to the floor: `marble at 0.10 m`. The third line has failed twice.

The top face has the corners 2, 3, 6 and 7, so its triples are `[2, 3, 6]` and `[3, 7, 6]`. Seen from above, 3 is back left, 2 is back right, 6 is front right. `[2, 3, 6]` goes from back right to back left to front right: counter-clockwise. Both triples face into the cube. Swap two numbers in each:

```gdscript
	[2, 6, 3], [3, 6, 7],   # top
```

Run it. The top is there. M: `marble at 1.71 m`. Drop it from a few more places. Over the top we made 81 drops on a grid, and 75 stayed. The six that rolled off had all landed 3.5 cm from the top's diagonal, on the same side of it. The square is two triangles for the marble too.

Hold V. From below, half of the bottom is missing: one dark triangle, and beside it the background. The cube covered 5.14% of that frame; a whole one covers 5.98%. The marble could not have found this, and neither could the camera above. The bottom face has the corners 0, 1, 4 and 5, and its triples are `[0, 4, 1]` and `[1, 5, 5]`. The second names corner 5 twice. A triangle with two corners in one place has no area: nothing to draw and nothing to rest on. Godot said nothing about it. Its partner shares 1 and 4, and the corner still missing is 5:

```gdscript
	[0, 4, 1], [1, 4, 5],   # bottom
```

Run it and hold V: the bottom is whole. Had we written `[1, 5, 4]`, the triangle would exist and face into the cube, and V would show the same hole, at 5.14% again. We tried it.

Three faults, and three ways of finding them: a message, the marble, the camera below. None was found by reading. Two faces we have still not looked at. The back and the right face no camera of ours, and no marble can land on them. We leave that open until the sheet.

## Stop here: what we have

This is the end of the first session. Run the study and check five things:

- An orange cube stands at the height of the walk. Nothing is printed.
- From above we do not see into it. Hold V: nor from below.
- M with B under the cube: the marble comes to rest at 1.71 m.
- M with B beside the cube: 0.10 m.
- `drafted_cube.gd` is unchanged.

If one of them fails, compare your script with this one:

```gdscript
extends MeshInstance3D

var corners: Array[Vector3] = [
	Vector3(-0.25, -0.25, -0.25),   # 0 bottom back left
	Vector3(0.25, -0.25, -0.25),    # 1 bottom back right
	Vector3(0.25, 0.25, -0.25),     # 2 top back right
	Vector3(-0.25, 0.25, -0.25),    # 3 top back left
	Vector3(-0.25, -0.25, 0.25),    # 4 bottom front left
	Vector3(0.25, -0.25, 0.25),     # 5 bottom front right
	Vector3(0.25, 0.25, 0.25),      # 6 top front right
	Vector3(-0.25, 0.25, 0.25),     # 7 top front left
]

var triangles: Array = [
	[4, 7, 5], [5, 7, 6],   # front
	[1, 2, 0], [0, 2, 3],   # back
	[0, 3, 4], [4, 3, 7],   # left
	[5, 6, 1], [1, 6, 2],   # right
	[2, 6, 3], [3, 6, 7],   # top
	[0, 4, 1], [1, 4, 5],   # bottom
]

func _ready() -> void:
	build()

func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for t in range(triangles.size()):
		var triangle: Array = triangles[t]
		if triangle.max() >= corners.size():
			push_error("triangle %d asks for a corner that is not there: %s" % [t, triangle])
			continue
		surface.add_vertex(corners[triangle[0]])
		surface.add_vertex(corners[triangle[1]])
		surface.add_vertex(corners[triangle[2]])
	surface.generate_normals()
	mesh = surface.commit()
	$Body/CollisionShape3D.shape = mesh.create_trimesh_shape()
```

## The argument: how much did the instruction fix?

The second session starts with a second answer. `drafted_vague.gd` is what came back for an instruction of one line: `make a cube`. Read it against ours. The corners are not ours: each lies twice as far from the middle, so the cube is 1 m. Our front triples are gone. There are twelve triples, in another order. Nothing was kept, because nothing was asked to be. Its numbers are the ones the hall's own builder stores.

To put the answers side by side, add two lines at the top of `cube.gd`, under `extends MeshInstance3D`:

```gdscript
# 0 my one face   1 the one-line draft   2 the three-line draft   3 repaired
@export_enum("my one face", "one-line draft", "three-line draft", "repaired") var draft := 3
```

and replace `_ready()` with:

```gdscript
func _ready() -> void:
	if draft == 0:
		triangles.resize(2)
	if draft == 1:
		read("res://drafted_vague.gd")
	if draft == 2:
		read("res://drafted_cube.gd")
	build()

func read(path: String) -> void:
	var answer = load(path).new()
	corners = answer.corners
	triangles = answer.triangles
	answer.free()
```

The script is now the `cube.gd` in the download. `resize(2)` cuts a list down to its first two entries: our face. `load()` gave us a mesh file in Plane; given a script file, it gives back the script, and `.new()` makes one object from it, as it made a `SurfaceTool`. That object never enters the scene. We read its two lists and `free()` it. Our own loop builds the cube from whichever lists it holds. At 2 it reads the first answer as it came back, with its `8`: our loop reports triple 3 and builds the rest.

**Write your prediction before you render.** Four cubes: our one face, the one-line draft, the three-line draft, the repair. Which two will look most alike from above? From below? From behind? Which of the four will hold the marble on its top? Write it down, with a reason for each.

Then look. Select `Cube`, choose **Draft** in the Inspector and run *(editor)*. For stills of all four from three standpoints, run `sheet.gd` as the [README](README.md) says. It brings a third camera, behind the cube, which faces the back and the right. This is what our sheet measured: the share of the frame the cube covers, and where the marble ended.

| `draft` | from above | from below | from behind | marble dropped over the top |
| --- | --- | --- | --- | --- |
| 0 my one face | 0.55% | 3.45% | 0.00% | 0.10 m: the floor |
| 1 one-line draft | 5.34% | 24.67% | 19.44% | 0.97 m: inside the cube |
| 2 three-line draft | 0.69% | 5.14% | 2.84% | 0.10 m: the floor |
| 3 repaired | 1.31% | 5.98% | 4.84% | 1.71 m: on the top |

From above, the closest pair is our one face and the three-line draft: they differ on 0.36% of the frame. With its top missing, the draft shows little more than the face we wrote. From below and from behind, the closest pair is the three-line draft and the repair, at 0.95% and 2.03%. No standpoint shows all three faults. The top is missing from above and from behind, half the bottom only from below, half the back only from behind. The back was the face nobody had looked at.

The one-line draft is the surprise. From above it looks like a whole cube, twice the size, with a shadow. Every one of its twelve triangles faces inward. What we see are the insides of its far walls. From behind it is an open room: two walls and a floor. The marble says the same: it falls in through the top and rests on the inside of the bottom, at 0.97 m. An inside-out cube is a room.

The claim: an instruction fixes what it names. The three lines named the corners, the front face and the winding, and the answer kept the first two. The one line named nothing, and size, order and side came back as somebody's habit. But naming is not checking. The careful answer still had three faults, and the careless one looked best from the camera we happened to stand at. Only the third line found anything, and each instrument found only what faced it.

## Ship it: the first build

So far the study has run inside the editor. A build is the project packed to run without it.

Open **Project > Export…**, press **Add…** and choose your desktop system. If the list says the export templates are missing, follow its link to download them; they are large. Press **Export Project…**, choose an empty folder outside the project, and save *(editor)*. The download already holds a preset named `Windows Desktop`, in `export_presets.cfg`.

We made our build from the command line, with that preset, into a folder outside the project:

```
godot --headless --path . --export-debug "Windows Desktop" <folder>/point-cube.exe
```

It took three seconds and wrote three files. `point-cube.exe`, 100,557,824 bytes, is the engine: about 96 MB. `point-cube.pck`, 84,700 bytes, is our project: every scene and script of this study. `point-cube.console.exe`, 50,176 bytes, starts the build from a terminal so that printed lines can be read there; a build has no Output panel.

We started the build on the machine that made it. It opened its window, drew 240 frames and closed with no message. The `.exe` copied alone into another folder does not start. It answers: `Error: Couldn't load project data at path "…". Is the .pck file missing?` Both files travel together.

## What the cube owes

The first debt is to other people's code. The one-line answer came back as a cube of 1 m around its own origin, wound counter-clockwise. We wrote that answer for this kit, and we did not invent it. It is the cube the museum's own builder stores, and that builder hides the winding by drawing every triangle twice and switching culling off. An assistant learns from other people's code, and where our instruction was open it had nothing else to go on. Godot knows its own older habits too. We gave 4.6 two lines in the spelling of version 3. `extends MeshInstance` got `Parse Error: Could not find base class "MeshInstance".` and `export var size = 0.5` got `Parse Error: The "export" keyword was removed in Godot 4. Use an export annotation ("@export", "@export_range", etc.) instead.`

The second debt is to reading. Wendy Hui Kyong Chun's word for it is sourcery: taking the sight of source code for knowledge of what it does (*Programmed Visions*). We read the first answer and it read well. One of its faults Godot announced; two it did not. And the instruments can be fooled in turn. We switched `backface_collision` on for the three-line draft, and the marble came to rest at 1.71 m, on a top that faces into the cube. From above, the draft that was wrong in every triangle looked whole.

The third debt is the build's. It is a second machine, and it does not behave as the editor's run does. A save like Plane's, `ResourceSaver.save(mesh, "res://my_plane.tres")`, ran in our Windows build and returned `OK`, and the file appeared beside the `.exe`, not in any project; the next build will not contain it. `assert()`, a stricter cousin of `push_error()`, stopped its function in our debug build with `SCRIPT ERROR: Assertion failed`; a release build skipped the line and ran on. `push_error()` printed in both, and in the release build without its line number. A headset build is said to differ again: a project folder that cannot be written to at all, and a screen that runs at another rate. We checked neither here.

## Stand in it somewhere else

The place this chapter asks for is another machine: your build on a classmate's laptop, or on a headset. It is the first time the room exists outside your editor.

Here is what was checked. The export ran. The build started on the machine that made it, with a window and without one. A build of a room like yours, with a walked plane and the cube, started without a window and ran 300 frames with no message.

Here is what was not. No build was copied to another computer. No headset build was made: that needs the Android preset, its own tools, and a scene with an XR player, which this fixed-camera study does not have. Day Zero names that route.

On a classmate's laptop the keys are the same, and nothing of the editor is there: no Inspector, no Output panel. Take the marble and Under with you. They are part of the build.

## Try

Walk D, S, A, W around the cube, press Enter and F. The cube stands on your plane. Hold V: in our stills the plane was gone from below and the cube showed on 5.98% of the frame, as much as without a plane.

Set **Draft** to 2 and walk the same plane. Drop the marble over the cube. Ours fell through the top and the bottom and came to rest on the plane, inside the cube, at 1.22 m.

Remove the `set_smooth_group(-1)` line for one run.

Put the three lines and the Stop-here script to a real assistant. Then ask again with `make a cube`. Check both answers against the third line before you read them.

In the hall you pull corner 6. Here, change its position in the list. Before you run: which faces will follow?

## In your room

SYNTHESIS I: your room leaves the editor.

Copy `room.tscn`, `room.gd` and `my_plane.tres` from your Plane folder into this one. Open `cube.tscn`, select `Cube` and copy it; open `room.tscn`, select the root and paste; save *(editor)*. `Body` comes with it. In the Inspector, give `Cube` the position where your walk ended. Run `room.tscn`. We made the same room by writing its scene file. There the marble came to rest on the cube at 1.71 m, on the plane beside it at 1.22 m, and on the floor outside the walk.

Make the room the main scene, in **Project > Project Settings > Application > Run** *(editor)*, and export. Our room's build started without a window and ran with no message. In the short track your teacher adds the scans from day 4 to your room before this export; importing them is the collage chapter's subject, and they are not part of this download.

Your room so far: the plane you walked, three points, one line and the repaired cube, as a build. Stand in it on another machine. In your README, keep three things: your three lines, the first answer as it came back, and your repair.

## What we borrowed

| Part | From | How far we go |
| --- | --- | --- |
| `plane.tscn`, `plane.gd` and all they inherit | Point Plane | Inherited. The root runs last chapter's script unchanged. |
| `Marble`, `marble.gd`; `Under` | Point Plane | Use: M drops, V looks. Here they are the instruments. |
| `Cube` and its orange material | Supplied in `cube.tscn` | Use: we fill its mesh. We make materials in the chessboard chapter. |
| `Body` and its empty shape | Supplied in `cube.tscn` | Use: we fill the shape. |
| `drafted_cube.gd` | Supplied here | The first answer, for the three lines. Read it; never edit it. `cube.gd` reads its lists at `draft` 2. |
| `drafted_vague.gd` | Supplied here | The second answer, for one line. Read at `draft` 1. |
| `sheet.gd` | Supplied here | Use: it renders the four values from above, from below and from behind, and measures them. |
| `export_presets.cfg` | Supplied here | Use: one desktop preset, `Windows Desktop`. |

What we made is `cube.gd`: eight corners, twelve triples, a loop that reports a bad triple, normals, a collider and an axis.

## What we carry forward

We leave with a body built around its own origin, from a list of positions and a list of triples; a protocol of three lines; the habit of checking an answer before reading it; a loop that says what is wrong with its input; and a build.

The next stop, *The organism: bone, tendon, muscle*, makes a limb of three segments. Each segment is a body like this cube, placed by its node and not by its corners. So far the node has only stood still. There it turns, and what it turns around is its origin: the point our eight corners were measured from.
