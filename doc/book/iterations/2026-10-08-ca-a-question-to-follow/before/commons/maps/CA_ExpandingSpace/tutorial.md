# The surface includes you

## Learning elements

- An external position becomes input to a cellular rule.
- A dictionary pairs each grid address with a fractional state.
- Four axial neighbours and a bounded field.
- Separate thresholds for recovery and physical support.
- Snapshot updates compared with a directional scan.

## Bring the same point

In the previous hall, carrying the point changed nothing in the cells. It carried STEP. Here **where you hold it matters**. The bridge and its wall frieze show the same field. Take the black point beside the desk, bring it near a tile and press its trigger. Each press selects HAND and advances one tenth of a simulated second. A nearby tile loses health. Release the point and STEP again: recovery now depends on what remains around the tile.

Try the installed bridge first. Its desk also offers a fixed PROBE and the actual VISITOR as input, RUN for repeated steps, and a full RESTORE. The gold address W appears on both floor and wall. Below 0.2, its floor tile loses collision support. The basin catches you; the ramps return you to the museum floor. A wall panel can show the same value without opening a hole in the wall.

We reconstruct this operation at one-fifth scale, with the same PointBody and rule. Save the previous lesson. Attach `presence.gd` to your existing `PointStudy` Node3D in the museum. Keep unit scale, about 2 × 3 metres clear, and face its positive Z side. Place the unchanged `point_body.gd` beside it. Day Zero's museum still supplies the player, camera, light and XR Tools. These two files create all study geometry; no prepared child nodes are needed. The small model has manual steps, one point input and a tray beneath its tiles. Walk on the installed bridge, not this table.

## An address keeps a fraction

`current[Vector2i(x, y)]` holds a number from 0 to 1. The dictionary makes the address explicit; it replaces the flat Boolean array used in Life. All 80 addresses exist throughout the experiment. A disappearing tile does not delete its entry.

Logical Y runs along the bridge, becoming physical Z in `cell_position`. `view_position` shrinks that simulation position and places it on the table. `input_position` reverses the conversion: world position → study-local position → simulation position. This lets the smaller model use the installed rule's distances. Moving or rotating the entire study does not alter those local relations.

The radius is 1.35 simulation metres, which appears as 0.27 metres on this model. Distance uses all three coordinates, including height. The input is the held point's centre. In the installed VISITOR mode it is the tracked body's origin. Neither measures weight or contact pressure.

## One update

For each address, `evolve` makes one choice. If the point is held and its centre is nearer than `RADIUS`, health falls by 0.04. Otherwise each healthy axial neighbour adds 0.01. The four directions are north, south, east and west; diagonals and the centre are excluded. Missing neighbours at the boundary contribute nothing. This field does not wrap as Life did.

`maxf` and `minf` keep the result between 0 and 1. Near the input, decay takes the whole branch: recovery is not added at the same time. Moving the point while the clock is stopped changes no cell. Trigger or Enter commits one update.

| Health | Helps neighbours recover? | Tile supports a body? |
| --- | --- | --- |
| Greater than 0.5 | Yes | Yes |
| 0.2 through 0.5 | No | Yes |
| Below 0.2 | No | No |

`redraw` uses the new value to change colour and collision. Each wall panel shares its floor tile's material. The wall backing and lower tray stay solid. Changing a state and deciding what that state permits remain separate operations.

## Complete study — presence.gd

Read `input_position`, `neighbours`, `evolve` and `step` first. They contain the new operation. `make_display` builds the two views and their support; it is included so the reconstruction is complete. There is one `_ready`, and every reference is created or declared here.

```gdscript
extends Node3D
const PointBody = preload("point_body.gd")
const WIDTH := 5
const LENGTH := 16
const PITCH := 0.6
const RADIUS := 1.35
const DT := 0.1
const LIMIT := 300
const VIEW_SCALE := 0.2
const VIEW_ORIGIN := Vector3(0, 1.02, 0)
const W := Vector2i(2, 6)
const DIRECTIONS := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
var current: Dictionary = {}
var materials: Dictionary = {}
var supports: Dictionary = {}
var point: XRToolsPickable
var reading := Label3D.new()
var ticks := 0
var chain := false
var synchronous := true
var backwards := false

func _ready() -> void:
	for y in LENGTH:
		for x in WIDTH:
			current[Vector2i(x, y)] = 1.0
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): step())
	park()
	reset()

func cell_position(site: Vector2i) -> Vector3:
	return Vector3((site.x - 2) * PITCH, -0.1, site.y * PITCH)

func view_position(site: Vector2i) -> Vector3:
	return VIEW_ORIGIN + cell_position(site) * VIEW_SCALE

func input_position() -> Vector3:
	return (to_local(point.global_position) - VIEW_ORIGIN) / VIEW_SCALE

func neighbours(old: Dictionary, site: Vector2i) -> int:
	var count := 0
	for direction in DIRECTIONS:
		var other: Vector2i = site + direction
		if old.has(other) and old[other] > 0.5:
			count += 1
	return count

func evolve(old: Dictionary, at: Vector3, present: bool) -> Dictionary:
	var next := old.duplicate()
	var read: Dictionary = old if synchronous else next
	var order := old.keys()
	if backwards:
		order.reverse()
	for site: Vector2i in order:
		var health: float = old[site]
		if present and cell_position(site).distance_to(at) < RADIUS:
			next[site] = maxf(0.0, health - 0.08 * DT * 5.0)
		else:
			next[site] = minf(1.0, health + 1.0 * DT * 0.1 * neighbours(read, site))
	return next

func step() -> void:
	if ticks == LIMIT:
		return
	current = evolve(current, input_position(), point.held() and not chain)
	ticks += 1
	redraw()

func reset() -> void:
	ticks = 0
	for site in current:
		current[site] = 0.0 if chain else 1.0
	if chain:
		current[Vector2i(1, 6)] = 0.6
		current[W] = 0.495
	redraw()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(-0.65, 1.12, 0.3)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: step()
			KEY_R: chain = false; reset()
			KEY_C: chain = true; reset()
			KEY_O: synchronous = not synchronous; reset()
			KEY_V: backwards = not backwards; reset()
			_: return
		get_viewport().set_input_as_handled()

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var finish := StandardMaterial3D.new()
	finish.albedo_color = colour
	node.material_override = finish
	add_child(node)
	return node

func solid(node: MeshInstance3D, size: Vector3) -> CollisionShape3D:
	var body := StaticBody3D.new()
	var boundary := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	boundary.shape = shape
	node.add_child(body)
	body.add_child(boundary)
	return boundary

func make_display() -> void:
	var tray := box(Vector3(0.72, 0.04, 2.0), Vector3(0, 0.86, 0.9), Color("354650"))
	solid(tray, Vector3(0.72, 0.04, 2.0))
	box(Vector3(0.1, 0.84, 0.1), Vector3(0, 0.42, 0.9), Color("bf9469"))
	var wall := box(Vector3(0.04, 0.38, 2), Vector3(0.55, 1.28, 0.9), Color("20373a"))
	solid(wall, Vector3(0.04, 0.38, 2))
	for site: Vector2i in current:
		var tile := box(Vector3(0.114, 0.04, 0.114), view_position(site), Color.WHITE)
		materials[site] = tile.material_override
		supports[site] = solid(tile, Vector3(0.12, 0.04, 0.12))
		var panel := box(Vector3(0.02, 0.058, 0.106), Vector3(0.52, 1.15 + site.x * 0.064, site.y * 0.12), Color.WHITE)
		panel.material_override = materials[site]
	var at := view_position(W) + Vector3.UP * 0.025
	for side in [-1, 1]:
		box(Vector3(0.124, 0.008, 0.008), at + Vector3(0, 0, side * 0.062), Color("ffd484"))
		box(Vector3(0.008, 0.008, 0.124), at + Vector3(side * 0.062, 0, 0), Color("ffd484"))
	reading.position = Vector3(0, 1.8, 0.6)
	reading.font_size = 28
	reading.pixel_size = 0.0014
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	reading.outline_size = 4
	add_child(reading)

func redraw() -> void:
	for site: Vector2i in current:
		var health: float = current[site]
		var finish: StandardMaterial3D = materials[site]
		finish.albedo_color = Color("a86c88").lerp(Color("8cd9be"), health)
		finish.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if health < 0.2 else BaseMaterial3D.TRANSPARENCY_DISABLED
		finish.albedo_color.a = 0.18 + health if health < 0.2 else 1.0
		supports[site].set_deferred("disabled", health < 0.2)
	reading.text = "W (2,6) / HEALTH %.3f / SUPPORT %s\n%s / %s / %.1f s\nTRIGGER / ENTER: STEP   R: FULL   C: CHAIN\nO: SYNC/SCAN   V: REVERSE" % [current[W], "ON" if current[W] >= 0.2 else "OFF", "SYNC" if synchronous else "SCAN", "REVERSE" if backwards else "FORWARD", ticks * DT]
```

## Unchanged carried object — point_body.gd

This is the same PointBody file used in the previous hall. It keeps its small dark sphere, pickup behaviour and action signal. Copy it only if it is not already beside the new script.

```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

## Let the edge recover

Hold the point's centre about 0.05 metres above W and STEP 21 times without moving it. The value reaches 0.16; the faint tile no longer supplies support. Release the point. Each later Enter press advances recovery without a proximity input. The outer edge of the depleted patch recovers first because it still has healthy neighbours. A wholly empty field has none and will not repair itself merely because you leave.

Now hold the point directly above W but more than 0.27 metres from its centre. Predict the next update before pressing. Height alone can take it outside the radius. Lower it and repeat. You are testing a three-dimensional distance, not painting onto a two-dimensional grid. Desktop learners can use the museum's established grab operation and Enter while holding the point.

## Does the order count?

This comparison returns to the old-to-next agreement; it does not add another input. Press C. The field begins at zero except (1,6) = 0.600 and W = 0.495. Hand influence is disabled for this comparison. In SYNC, all recovery counts read `old`. STEP once: W becomes 0.505, but (3,6) remains zero because it read W's old value.

Press O to select SCAN and reset that same beginning. Now counts read `next`, including answers already written. STEP: (3,6) becomes 0.01. W's newly healthy value was available before the loop reached its neighbour. Press V to reverse the scan and reset; STEP again. That neighbour now stays at zero. SYNC gives the same answer in either order.

Make one independent edit: change W's CHAIN beginning from 0.495 to **0.49**. Predict whether the third cell gains anything in forward SCAN, then run it. W reaches exactly 0.5. The condition is strictly greater than 0.5, so the third cell still gains nothing. The threshold, not the rounded appearance of the colour, decides.

R restores the full field and permits hand input again. O and V preserve the chosen beginning while resetting time. At 300 steps—30 simulated seconds—the study holds its state until reset. Releasing the point does not advance time by itself.

You leave with an input connection you can name, and two consequences you can distinguish: a value can cease to help its neighbours before it ceases to hold you. The next room asks what happens when the neighbourhood offers more than a count above a threshold.
