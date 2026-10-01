# Point Plane — when the line closes

Trace left us with an ordered list of positions, a gate, a route length and a straight distance. It also left a pink line we drew without opening the code that draws it. Here we walk back to where we began and close the list. We do it in three separate steps: first an outline, then a face, then a body. Each step adds something the one before did not contain.

In the hall, [the reading](../../../../commons/maps/Point_Triangle_Context/final.md) closes three edges by hand and only then shows a fill: "Something can close without becoming a surface." This study keeps that order. The hall's triangle shows both of its sides and stops nothing. Ours will have one side, and a marble will rest on it.

Every message and number on this page comes from running the study in Godot 4.6. Where the page describes the editor's own windows and buttons, it is marked *(editor)*: those runs had no editor window, so that part is described, not watched. A run without a window draws no pictures, so what the face looks like was measured from stills rendered by `sheet.gd`, which the download includes.

## Open the study

Open the [Point Plane study](README.md), then `plane.tscn`. It inherits `trace.tscn`, the finished Trace study, so A, B, the segment, the readout, the mover on B, the pink strip and the Record label are the ones we left there. `trace.tscn` and `line.tscn` are in the download unchanged and still run on their own.

`plane.tscn` changes one thing and adds four. The root runs `plane.gd` instead of `trace.gd`. `Face` is an empty mesh node with a pale material. `FaceBody` is a static body whose collision shape is empty. `Marble` is a supplied ball that waits on the floor. `Under` is a second camera, below the height B moves at, looking up.

The Input Map has four new actions beside Trace's five: `close` (Enter), `fill` (F), `drop` (M) and `look` (V).

Run it. Walk a loop with B: hold D, then S, then A, then W, a little under a second each. That is right, towards you, left, away: clockwise on the screen. Press Enter. The pink line joins its end to its start, and the count stops. Press F. A pale face fills the outline. Move B over the face and press M. The marble falls from one metre above B and stays on the face. Hold V. We look from below: the face is gone, and the marble rests on nothing.

`plane.gd` is ours. The download holds the finished version. We will take it apart and build it again.

## Open the strip

In Trace we called `$Strip.draw(trace)` and promised to open its code here. This is `trace_strip.gd`:

```gdscript
func _ready() -> void:
	mesh = ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.3, 0.6)
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func draw(points: Array[Vector3]) -> void:
	var strip := mesh as ImmediateMesh
	strip.clear_surfaces()
	if points.size() < 2:
		return
	strip.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in points:
		strip.surface_add_vertex(point)
	strip.surface_end()
```

`_ready()` makes an empty mesh and a pink material that ignores light. `.new()` makes a fresh object of the kind named before the dot. `draw()` does three things: begin, hand over the positions in order, end.

The word after `surface_begin` matters most. `Mesh.PRIMITIVE_LINE_STRIP` tells the renderer how to read the positions: join each one to the next. The positions do not say that themselves. The same twelve positions, begun with another word, are read another way. That is the whole of today's making: the same three moves, and another word.

## Start from the recorder

Replace everything in `plane.gd` with this. It is the finished Trace script with two changes.

```gdscript
extends Node3D

var trace: Array[Vector3] = []
var gate := 0.1
var capacity := 128
var recording := true
var closed := false

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

Run it. It behaves as Trace did: B moves, the pink line follows, the Record counts. Enter and F do nothing yet.

The first change is `capacity`, raised from 32 to 128. A walk we mean to close must still hold its start. Thirty-two positions at a gate of ten centimetres held 3.58 m of route in Trace; the loop we walked above was 4.72 m around. With 32, the oldest positions, the start among them, would have left before we came back. The second change is a new member, `closed`, which nothing reads yet.

## Close the walk

In `_process`, under the two `pause` lines, add:

```gdscript
	if Input.is_action_just_pressed("close") and trace.size() >= 3:
		closed = true
		recording = false
```

Change `if recording:` to:

```gdscript
	if recording and not closed:
```

Replace the last two lines of `_process` with:

```gdscript
	$Strip.draw(outline())
	$Record.text = "%d kept\nroute %.2f m\nstraight %.2f m\n%s" % [trace.size(), route_length(), straight_length(), status()]
```

And add two functions at the end of the script:

```gdscript
func outline() -> Array[Vector3]:
	var loop: Array[Vector3] = trace.duplicate()
	if closed:
		loop.append(trace[0])
	return loop

func status() -> String:
	if not closed:
		return "open"
	return "closed, %.2f m around" % (route_length() + straight_length())
```

Run it. Walk the loop: D, S, A, W. The Record's last line reads `open`. Press Enter. The pink line runs from the last kept position back to the first, and the line reads `closed`, with a length. Move B: nothing more is kept. In a run stepped at 60 frames a second, with D, S and A held for one second each and W for 0.9, the Record read 40 kept, route 4.52 m, straight 0.20 m, closed, 4.72 m around.

`and` is true only when both sides are true. Enter closes the walk only if the list holds three positions or more. Run the study again and press Enter at once, with one position kept: nothing happens. Two positions make a line there and back. A loop needs three edges.

`outline()` gives the strip one position more than the list holds. `duplicate()` makes a copy of the list; we add the first position to the end of the copy, and the list itself stays as it was. With 12 kept, the strip receives 13, and the last equals the first.

The edge that closes the loop is one we already measured. `straight_length()` is the distance from the first kept position to the last. In Trace it was the straight line the route did not take. Now it is the last edge of the route, so the length around is `route_length() + straight_length()`.

Look through the loop. The floor shows inside it. Closing made a boundary. It did not make a surface.

One loss is worth trying once. If a walk is longer than the capacity, its start has already left the list, and Enter joins the end to the oldest position still held. With a capacity of 5 and 8 positions kept, the outline closed to the fourth.

## Add the face

In `_process`, under the three `close` lines, add:

```gdscript
	if Input.is_action_just_pressed("fill") and closed:
		build_face()
	if Input.is_action_pressed("look"):
		$Under.current = true
	else:
		$Camera3D.current = true
```

and add this function above `status()`. Its loop header is the one from `route_length()`:

```gdscript
func build_face() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, trace.size()):
		surface.add_vertex(trace[0])
		surface.add_vertex(trace[i])
		surface.add_vertex(trace[i + 1])
	$Face.mesh = surface.commit()
```

Run it. Walk the loop, press Enter, press F. No face appears. Godot reports:

```
SCRIPT ERROR: Out of bounds get index '12' (on base: 'Array[Vector3]')
```

and names the line `surface.add_vertex(trace[i + 1])`. The number is the size of your list: ours held 12 positions, numbered 0 to 11, and there is no entry 12. A `SCRIPT ERROR` stops the function it happens in, so `commit()` never ran and `Face` has no mesh.

We borrowed the header from `route_length()`. That loop reads entries `i - 1` and `i`, so it may run up to the last entry. This one reads `i` and `i + 1`: the last entry has no next. Change the header:

```gdscript
	for i in range(1, trace.size() - 1):
```

and let `status()` count what we make:

```gdscript
func status() -> String:
	if not closed:
		return "open"
	var around := route_length() + straight_length()
	if $Face.mesh == null:
		return "closed, %.2f m around" % around
	return "closed, %.2f m around, %d triangles" % [around, trace.size() - 2]
```

Run it: walk, Enter, F. A pale face fills the outline, and the Record adds a count: 38 triangles for our 40 positions, 10 for a walk of 12.

`SurfaceTool` builds a mesh in the same three moves as the strip. `begin()` takes the word: `Mesh.PRIMITIVE_TRIANGLES` reads every three positions as one triangle. `add_vertex()` hands over one position. `commit()` ends the work and gives back the mesh, which we hand to `Face`. `null` means "nothing": before the first F, `$Face.mesh` is `null`.

Each pass of the loop hands over three positions: the first kept position, then two neighbours. Every triangle shares `trace[0]`, like the ribs of a fan. A list of n positions makes n − 2 triangles.

`look` is ours to use now. `is_action_pressed()` is true for as long as the key is held; `else` runs its line whenever the condition above it is false. `current` says which camera the window shows.

Hold V. From below, the face is gone. The outline, A, B and the segment are still there. Release V: the face is back.

A triangle is drawn on one side only: the side from which its three corners run clockwise. We walked D, S, A, W, which is clockwise seen from above, so the face looks up. Run the study again and walk the other way round: D, W, A, S. Enter, F: nothing appears. Hold V: there it is. The direction we walked decided which side the face has. (We ran the same twelve positions in both orders. In one the front faces up, in the other down.)

## Give the face a direction

In `build_face()`, above the `commit()` line, add:

```gdscript
	surface.generate_normals()
```

Run it: walk clockwise, Enter, F. The face looks as it did. Rendered with and without this line, the two stills differed on 0.00% of the frame.

Something did change. A normal is a direction stored with each corner: the way the surface faces there. Before this line our surface held none. Now it holds one for each of its corners, and for a clockwise walk each points straight up.

To see what a normal is for, turn it over. For one run, change the line to `surface.generate_normals(true)`. Walk, Enter, F: the face is there, and it is grey. In the stills its brightness fell from 1.00 to 0.80. It covers the same part of the frame, because its corners run in the same order. But its normals now point down, away from the light above, and that light adds nothing to it. The grey that is left is the even light of the room. Put the line back.

So a face makes two promises. The order of its corners says from which side it is drawn. Its normals say which way it faces the light. They usually agree, and nothing forces them to.

Without any normals, this renderer still lit our face as though it faced up. We measured that; we did not arrange it. A missing normal is a default, and somebody else chose it.

`generate_normals()` belongs to triangles. Begun with the strip's word, `Mesh.PRIMITIVE_LINE_STRIP`, the same call reports `ERROR: Condition "primitive != Mesh::PRIMITIVE_TRIANGLES" is true.` and adds nothing. A line has no side to face with. (Here and below we leave out the lines under each message that name files inside the engine.)

## Give the face a body

First, a way to test. In `_process`, under the two `fill` lines, add:

```gdscript
	if Input.is_action_just_pressed("drop"):
		$Marble.drop(b + Vector3.UP)
```

and replace the Record line, so that it shows the marble's height:

```gdscript
	$Record.text = "%d kept\nroute %.2f m\nstraight %.2f m\n%s\nmarble at %.2f m" % [trace.size(), route_length(), straight_length(), status(), $Marble.position.y]
```

`drop()` belongs to `marble.gd`, which we use without opening. Its contract is one sentence: give it a position, and the marble starts there with no speed and falls. `Vector3.UP` is one metre straight up, so the marble starts one metre above B.

Run it: walk, Enter, F. Move B over the face and press M. The marble falls through the face and lands on the floor. The Record reads `marble at 0.10 m`: the marble's radius. A mesh is something to look at. Nothing in it stops a body.

Try the obvious repair. At the end of `build_face()`, add:

```gdscript
	$FaceBody/CollisionShape3D.shape = $Face.mesh
```

Run it and drop the marble. It still falls to the floor, and Godot reports nothing. A collision shape must be a `Shape3D`, and a mesh is not one. The assignment is refused in silence and the shape stays empty. While the study runs, the Remote scene tree shows it: select `FaceBody/CollisionShape3D` and its Shape is empty *(editor)*. Remove the line. When something that should work does nothing and says nothing, look at what the property holds.

Now add these three lines at the end of `build_face()`:

```gdscript
	var shape: ConcavePolygonShape3D = $Face.mesh.create_trimesh_shape()
	shape.backface_collision = true
	$FaceBody/CollisionShape3D.shape = shape
```

Run it: walk, Enter, F, move B over the face, M. The marble stops on the face. The Record reads `marble at 1.22 m`: the height B walks at, 1.12 m, and the marble's radius.

`create_trimesh_shape()` makes a collision shape from the triangles of the mesh. It is a second object built from the same corners. `FaceBody` is a `StaticBody3D`, a body that does not move; its child `CollisionShape3D` was empty, and now holds the shape.

`backface_collision` is there because a collider has a side too. With it off, which is the default, the body's side is the eye's side. We measured both directions. Under a face walked counter-clockwise, a marble dropped from above fell through to the floor, and a ray sent up from below was stopped. Over a face walked clockwise, the ray from above was stopped and the ray from below passed. With `backface_collision` on, the plane stops a body from both sides, whichever way we walked.

Now the eye and the body can disagree. Drop the marble on the face and hold V. From below nothing is drawn, and the marble rests on it.

Walk B to the edge of the face and drop from there. With the marble's centre 2 cm inside the outline, it stayed, at 1.22 m. With its centre 2 cm outside, it came off the edge and ended on the floor, 1.65 m from where we dropped it. The body the marble meets ends where our walk ended.

## What we have

Run the study once more and check five things:

- Enter does nothing until three positions are kept. Then the pink line closes and the count stops.
- F does nothing before Enter. After it, a face fills the outline and the Record counts its triangles: two fewer than the positions kept.
- Walked clockwise, the face shows from above. Hold V: it is gone from below.
- M drops the marble from above B. Over the face it comes to rest at 1.22 m; beside it, at 0.10 m.
- Dropped before F, the marble falls through the outline.

## The argument: which side?

Add two lines at the top of the script, under `extends Node3D`:

```gdscript
# 0 clockwise   1 clockwise with flipped normals   2 counter-clockwise   3 counter-clockwise double-sided
@export_enum("clockwise", "clockwise flipped normals", "counter-clockwise", "counter-clockwise double-sided") var side := 0
```

and replace `build_face()` with:

```gdscript
func build_face() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, trace.size() - 1):
		surface.add_vertex(trace[0])
		if side < 2:
			surface.add_vertex(trace[i])
			surface.add_vertex(trace[i + 1])
		else:
			surface.add_vertex(trace[i + 1])
			surface.add_vertex(trace[i])
	if side == 1:
		surface.generate_normals(true)
	else:
		surface.generate_normals()
	$Face.mesh = surface.commit()
	if side == 3:
		$Face.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		$Face.material_override.cull_mode = BaseMaterial3D.CULL_BACK
	var shape: ConcavePolygonShape3D = $Face.mesh.create_trimesh_shape()
	shape.backface_collision = true
	$FaceBody/CollisionShape3D.shape = shape
```

In Trace, `mover.gd` put `@export` in front of three values so that the Inspector could change them. `@export_enum` does the same and offers a list of names. The member holds a whole number: 0 for the first name, 3 for the last. Select the root node, `PlaneStudy`, and **Side** appears in the Inspector as a list *(editor)*. A name may not contain a comma. We tried one in the second name, and the script did not load: `Parse Error: Argument 2 of annotation "@export_enum" contains a comma. Use separate arguments instead.`

The four values change three things. From 2 up, the two neighbours are handed over in the other order, so every triangle runs counter-clockwise. At 1, the normals are flipped. At 3, the material's `cull_mode` is set to draw both sides; at every other value it draws the front only. `material_override` is the pale material the scene supplies on `Face`; we change one of its properties and leave the rest.

The whole script now reads as the `plane.gd` in the download:

```gdscript
extends Node3D

# 0 clockwise   1 clockwise with flipped normals   2 counter-clockwise   3 counter-clockwise double-sided
@export_enum("clockwise", "clockwise flipped normals", "counter-clockwise", "counter-clockwise double-sided") var side := 0

var trace: Array[Vector3] = []
var gate := 0.1
var capacity := 128
var recording := true
var closed := false

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
	if Input.is_action_just_pressed("close") and trace.size() >= 3:
		closed = true
		recording = false
	if Input.is_action_just_pressed("fill") and closed:
		build_face()
	if Input.is_action_just_pressed("drop"):
		$Marble.drop(b + Vector3.UP)
	if Input.is_action_pressed("look"):
		$Under.current = true
	else:
		$Camera3D.current = true
	if recording and not closed:
		keep(b)
	$Strip.draw(outline())
	$Record.text = "%d kept\nroute %.2f m\nstraight %.2f m\n%s\nmarble at %.2f m" % [trace.size(), route_length(), straight_length(), status(), $Marble.position.y]

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

func outline() -> Array[Vector3]:
	var loop: Array[Vector3] = trace.duplicate()
	if closed:
		loop.append(trace[0])
	return loop

func build_face() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, trace.size() - 1):
		surface.add_vertex(trace[0])
		if side < 2:
			surface.add_vertex(trace[i])
			surface.add_vertex(trace[i + 1])
		else:
			surface.add_vertex(trace[i + 1])
			surface.add_vertex(trace[i])
	if side == 1:
		surface.generate_normals(true)
	else:
		surface.generate_normals()
	$Face.mesh = surface.commit()
	if side == 3:
		$Face.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	else:
		$Face.material_override.cull_mode = BaseMaterial3D.CULL_BACK
	var shape: ConcavePolygonShape3D = $Face.mesh.create_trimesh_shape()
	shape.backface_collision = true
	$FaceBody/CollisionShape3D.shape = shape

func status() -> String:
	if not closed:
		return "open"
	var around := route_length() + straight_length()
	if $Face.mesh == null:
		return "closed, %.2f m around" % around
	return "closed, %.2f m around, %d triangles" % [around, trace.size() - 2]
```

**Write your prediction before you render.** For a walk made clockwise, seen from above: which two of the four values will look most alike? Which one will be missing? Then the same four from below. Write it down, with a reason for each.

Then look. Run the study, walk clockwise, Enter, F. While it runs, open the Remote scene tree, select `PlaneStudy`, change **Side** in the Inspector and press F again: the face is built again with the new value *(editor)*. Hold V for the view from below. For stills of all four from one fixed walk, run `sheet.gd` as the [README](README.md) says; it writes eight pictures to `stills/` and the measurements to `sheet.json`.

This is what our sheet measured, on a walk of twelve positions:

| `side` | from above | from below |
| --- | --- | --- |
| 0 clockwise | face on 5.53% of the frame, brightness 1.00; its shadow on 0.78% | no face; its shadow on the undersides of A, B and the segment, 0.10% |
| 1 clockwise, flipped normals | face on 5.52%, brightness 0.80; shadow on 0.79% | no face; the same shadow, 0.10% |
| 2 counter-clockwise | nothing: 0.00%, and no shadow | face on 15.24%, brightness 0.80 |
| 3 counter-clockwise, double-sided | face on 5.54%, brightness 1.00; no shadow | face on 15.25%, brightness 0.80 |

From above, the closest pair is 0 and 3. They differ on 0.82% of the frame, and nearly all of that is the shadow on the floor, which 0 casts and 3 does not. The face itself is the same white in both. Value 2 is the missing one: its still differs from the outline's still on 0.00% of the frame. Values 0 and 1 cover the same pixels and differ on all of them, 5.54% of the frame: one is white, one is grey.

The body did not follow any of this. At each of the four values the marble came to rest at 1.22 m, and rays from above and from below were both stopped. At value 2, seen from above, the marble rests in the air inside a pink outline.

The claim: a surface has a side. What we see of a plane is a promise made by the order of its corners and by its normals. Godot draws the side from which the corners run clockwise. The order decides whether the face is drawn, the normals decide how the light counts, and the collider decides what a body meets. We wrote all three. The shadow was a fourth decision, and nobody asked us.

## What the plane owes

The first debt is to the eye. Before anything is drawn, a renderer decides which surfaces to leave out. Hidden-surface algorithms decide what exists for the eye (Jacob Gaboury, *Image Objects*, "Culling Vision"). Our value 2 is such a decision. From above, the face is not hidden behind something. It is not drawn. The marble rests on it all the same, because we switched the collider's back on. Had we left `backface_collision` at its default, the body would have shared the eye's side, and the marble would have fallen through what it could not see.

The same split runs the other way in the next hall. In [Polyhedra](../../../../commons/maps/Primitives_Polythedra/tutorial.md), an open corner of three faces has a collision hull that includes the missing fourth. There a body meets a surface that nothing draws.

The second debt is to the shape. Every triangle of a fan shares the first kept position. For a walk that bulges outwards everywhere, that fills what we enclosed. For a walk with a dent it can fill more. We gave the study an L of six corners and dropped the marble into its notch. With the fan starting at the L's outer corner, the marble fell through to the floor. Starting one corner further on, the same six corners made four triangles again, and the marble came to rest in the notch at 1.22 m, on a face our walk never enclosed. The fan is an approximation, and it owes the shape its dents. The Record's count cannot tell the two apart.

Smaller debts were paid before we arrived. The gate cut our corners. The mover never let B leave its height, so the walk was flat before we asked for a plane; a hand would not have been.

## Stand on it

The place this chapter asks for is to stand on your walk: the plane made from your own trace becomes floor, and you walk to its edge and look under it. This study has no visitor's body. It has stand-ins, and they are honest about what they can check.

The marble stands for the body. It meets collision shapes and never meshes, and its height is a number in the Record. B stands for the feet: walk it to the edge and drop from there. `Under` stands for the eyes: hold V and look under the plane without moving.

Our checks run without a window. They prove that the collider holds a falling body at the plane's height, that it ends at the outline, and that it holds at every value of `side`. They cannot prove that standing on it feels like standing.

In the museum a visitor has a body: a walker on the desktop, your own in a headset. Two things change there. Your eyes go under the plane because you crouch, and no key is involved. And the plane has to come down. It lies at 1.12 m, the height B has had since Lines. To become floor it must be lowered. In a scene of our own we set the height of `Face` and of `FaceBody` to −1.0, and the marble then came to rest at 0.22 m, on a plane 12 cm above the floor. The hall's own fill is the other choice: it shows both sides, and its reading says that this "does not give the face thickness or a collider." This study has not been tried in a headset.

## Try

Tick **Autopilot** on B and let it draw its figure-eight, then press Enter and F. Look from above, then hold V. Which loop of the eight shows from where? Say why.

Walk an L. Close it, fill it, and drop the marble into the notch. Then start the same L from another corner.

Set `side` to 2 and walk counter-clockwise. Before you press F, say which side you will see.

## In your room

From here on, every stop ends in a scene of your own, inside your copy of the kit. It grows through the track. This is its first day.

Keep the plane you walked. At the end of `build_face()`, add:

```gdscript
	ResourceSaver.save($Face.mesh, "res://my_plane.tres")
```

Run it, walk your loop, press Enter and F, and stop. The project now holds `my_plane.tres`: the mesh that `commit()` made, as a file. Remove the line again, or every F will write over it.

Make the room. In the FileSystem dock, right-click `plane.tscn` and choose **New Inherited Scene**. Select its root and clear its script, as we cleared B's in Trace. Attach a new script to the root, named `room.gd`, and save the scene as `room.tscn` *(editor)*. In `room.gd`, write:

```gdscript
extends Node3D

func _ready() -> void:
	$A.position = Vector3(-0.75, 1.12, 0.0)
	$B.position = Vector3(0.75, 1.12, 0.0)
	$Face.mesh = load("res://my_plane.tres")
	var shape: ConcavePolygonShape3D = $Face.mesh.create_trimesh_shape()
	shape.backface_collision = true
	$FaceBody/CollisionShape3D.shape = shape

func _process(_delta: float) -> void:
	var a: Vector3 = $A.position
	var b: Vector3 = $B.position
	$Segment.show_between(a, b)
	$Readout.text = "%.2f m" % (b - a).length()
	if Input.is_action_just_pressed("drop"):
		$Marble.drop(b + Vector3.UP)
	if Input.is_action_pressed("look"):
		$Under.current = true
	else:
		$Camera3D.current = true
```

Run `room.tscn`. `load()` reads a file from the project and gives back what it holds. The room has no recorder. It has the plane you walked, with its body; three points, A, B and the marble; and one line. Move B over your plane and press M. In our run the marble came to rest on the loaded plane at 1.22 m.

Your room so far: one plane you walked, three points and one line. Commit it. `commit()` turned a list of corners into a mesh. Saving turned the mesh into a file, and the arrangement into a scene. If your copy of the kit is under version control, commit there too.

## What we borrowed

| Part | From | How far we go |
| --- | --- | --- |
| `base.tscn`: floor, light, camera | Day Zero | Used as it is. |
| `line.tscn`, `segment.gd` | Point Lines | Inherited. |
| `trace.tscn`, `mover.gd` | Point Trace | Inherited. The mover was read there. |
| `trace_strip.gd` | Point Trace | Understand: opened here. Its three moves are SurfaceTool's. |
| `Face` and its pale material | Supplied in `plane.tscn` | Use: we fill its mesh and set one property, `cull_mode`. We make materials in the chessboard chapter. |
| `FaceBody` and its empty shape | Supplied in `plane.tscn` | Use: we fill the shape. |
| `Marble`, `marble.gd` | Supplied here | Use: call `drop(at)`. It starts at `at` with no speed and falls. |
| `Under`, the second camera | Supplied in `plane.tscn` | Use: set `current`. |
| `sheet.gd` | Supplied here | Use: it renders the four values from above and below and measures them. |
| Input Map actions | `project.godot` | Use by name: `close`, `fill`, `drop`, `look`. |

What we made is `plane.gd`: the recorder, a condition that closes it, an outline, a fan of triangles, normals, a collider and an axis.

## What we carry forward

We leave with a closed list, a face built from it by `SurfaceTool`, normals, a collider that holds a body, and four values of `side` we can tell apart. We also leave with three instruments: a marble for the body, a second camera for the far side, and a sheet that measures stills.

The next stop, *When things go wrong: the drafter is a machine*, builds a cube from 8 corners and 12 triangles. The moves are the ones we used here, 36 calls of `add_vertex()`, and each triangle must run clockwise seen from outside. An assistant drafts that code from our written instruction, and the chapter expects it to wind the other way. We now know what a counter-clockwise triangle looks like from the front: nothing. The hall adds one more thing to carry: a square face is two triangles, and they share an edge.
