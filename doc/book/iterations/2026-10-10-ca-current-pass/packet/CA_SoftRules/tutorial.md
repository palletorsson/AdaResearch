# What a neighbour offers

## Learning elements

- Two fractional values at each address: U and V.
- A neighbour contributes a difference, rather than a count above a threshold.
- A small model class keeps state separate from its display.
- Matched beginnings isolate one changed operation.
- The carried point chooses an address for a shared intervention.

## Reading route

Read `Field.laplacian` and `next_pair`, then `plant` in the host. The new question is what exchange contributes when the local reaction is held fixed. The complete files also include the display and controls; keep those working while investigating the named functions.

## Bring the point to the tables

In the previous room a healthy neighbour contributed to recovery. Here **how much it differs matters**. Two tables begin with the same square. Each table's field also covers a curved wall. A exchanges with its neighbours; B starts with exchange off. Both still perform the same local reaction.

Find W, the gold address just beside the starting square. At the side desk, press STEP. A receives a little V at W; B receives none. Press +100 to see that small difference develop. EXCHANGE B enables the missing operation and restores both beginnings. Step again: they now agree.

Take the black point beside the desk. Hold its centre just above either table and use its trigger. You plant the same small patch at the corresponding address in both fields. Moving the point without triggering does nothing. Release returns it to its shelf; use the desk to advance time. The floor crossing and INJECT offer a fixed patch instead. These are interventions in a running field, not a different rule.

## Reconstruct the comparison

Save the previous study. Put `field.gd`, `exchange.gd` and the unchanged `point_body.gd` together. Attach `exchange.gd` to the existing `PointStudy` Node3D in your Day Zero museum. Keep unit scale and about 3.3 × 2.4 metres clear, facing its positive Z side. The museum supplies the player, camera, lighting and XR Tools. These files create every child used by this study.

The compact reconstruction has two tables and two flat upright displays. The installed walls are larger and curved; they use the same operation. Use Enter for one step, Space for 100, E to change B's exchange and restart both fields, R to replay, and V to view U or V. In VR the point's trigger plants a seed. The compact model's clock and comparison controls use the keyboard; the installed exhibit has nearby VR desk controls. Desktop learners use the museum's pickup and I while holding the point.

## Return to the Shader field

Shaders already introduced a retained U/V field. Here we expose neighbour exchange by switching it off in one matched copy. This CPU model uses four axial neighbours, a 32 × 32 grid, Du = 0.16, Dv = 0.08, F = 0.037 and K = 0.060. The Shader study used a weighted eight-neighbour stencil, a 96 × 96 grid and different rates. We carry the distinction between state and image, not its texture or exact trajectory. Compare A and B within this lesson; do not expect their pictures to reproduce the Shader wall.

## A field stores two values

`Field` is a small class extending `RefCounted`. Each instance owns two arrays, one for U and one for V. It needs no position or mesh because its job is calculation. `left` and `right` are separate instances, not two names for the same arrays.

The grid has 32 × 32 addresses. `index(x, y)` turns two coordinates into one array index. `posmod` wraps either coordinate to 0–31: the neighbour left of x = 0 is x = 31. This periodic boundary differs from the bounded bridge in the previous hall. The starting 6 × 6 square holds U = 0.5 and V = 0.25; elsewhere U = 1 and V = 0.

## Receive a difference

`laplacian` adds the four axial neighbours and subtracts four copies of the centre. Equivalently, it adds four neighbour-minus-centre differences. A uniform field gives zero. A higher neighbour contributes positively; lower neighbours contribute negatively. The centre is not an extra fifth neighbour.

The supplied Gray–Scott reaction in `next_pair` uses U × V × V to remove U and add V. Feed replenishes U; feed plus kill removes V. Exchange adds 0.16 times U's neighbour difference and 0.08 times V's. B can set just that exchange contribution to zero. `clampf` bounds both results to 0–1. The lesson uses this fixed reaction to compare exchange; deriving the chemical model and choosing a stable numerical scheme are later work.

One call is one numerical step with dt = 1, not one second of real time. `step` reads only the old arrays, writes both answers into new arrays, then replaces the old state. This keeps the simultaneous-update agreement from the earlier halls. A fresh pair of arrays makes that agreement visible; the larger installation reuses its spare buffers.

W is (12,15), just outside the square. Its U neighbours sum to 3.5 and its V neighbours to 0.25. Its own U = 1 and V = 0, so the reaction contributes nothing there. After one step:

| Field | U at W | V at W |
| --- | --- | --- |
| A, exchange on | 0.92 | 0.02 |
| B, exchange off | 1.00 | 0.00 |

That first difference is small enough to predict before watching it spread.

## Complete model — field.gd

<!-- student-code:field.gd -->
```gdscript
extends RefCounted
const N := 32
const FEED := 0.037
const KILL := 0.060
var u := PackedFloat32Array()
var v := PackedFloat32Array()
var exchange := true
var ticks := 0

func _init() -> void:
	u.resize(N * N)
	v.resize(N * N)
	reset()

func index(x: int, y: int) -> int:
	return posmod(y, N) * N + posmod(x, N)

func reset() -> void:
	u.fill(1.0)
	v.fill(0.0)
	ticks = 0
	for y in range(13, 19):
		for x in range(13, 19):
			u[index(x, y)] = 0.5
			v[index(x, y)] = 0.25

func seed_at(site: Vector2i) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			u[index(site.x + dx, site.y + dy)] = 0.5
			v[index(site.x + dx, site.y + dy)] = 0.25

func laplacian(values: PackedFloat32Array, x: int, y: int) -> float:
	return values[index(x - 1, y)] + values[index(x + 1, y)] + values[index(x, y - 1)] + values[index(x, y + 1)] - 4.0 * values[index(x, y)]

func next_pair(a: float, b: float, lap_u: float, lap_v: float) -> Vector2:
	# Supplied Gray–Scott model. One numerical step has dt = 1.
	var coupling := 1.0 if exchange else 0.0
	var uvv := a * b * b
	return Vector2(
		clampf(a + coupling * 0.16 * lap_u - uvv + FEED * (1.0 - a), 0.0, 1.0),
		clampf(b + coupling * 0.08 * lap_v + uvv - (KILL + FEED) * b, 0.0, 1.0)
	)

func step() -> void:
	var next_u := PackedFloat32Array()
	var next_v := PackedFloat32Array()
	next_u.resize(N * N)
	next_v.resize(N * N)
	for y in N:
		for x in N:
			var i := index(x, y)
			var answer := next_pair(u[i], v[i], laplacian(u, x, y), laplacian(v, x, y))
			next_u[i] = answer.x
			next_v[i] = answer.y
	u = next_u
	v = next_v
	ticks += 1
```

## A position becomes an address

The point keeps its pickup behaviour. `target_site` converts its world position into the study's local space, checks whether it is near either tabletop, and divides its offset into 0.04-metre cells. Logical grid Y becomes tabletop Z. An invalid target returns (-1,-1), so an unheld point or a trigger away from the tables plants nothing.

`seed_at` replaces a 3 × 3 patch with U = 0.5, V = 0.25. It does not add concentrations and does not advance the clock. Both fields receive the same intervention, but can retain different histories elsewhere. R restores the original square. E changes B's exchange and resets both histories for a fair comparison; R alone keeps that choice.

`paint` reads state without changing it. Each table and its upright display share one texture. The initial palette maps V × 2 into colour, clamped at one; U has another palette. V changes the view, not the simulation. A saturated colour need not mean a stored concentration of one. These surfaces are pictures of the field; the tables keep their physical support.

## Complete study — exchange.gd

Read `target_site`, `plant`, `advance` and `paint` first. `box` and `make_display` provide the complete staging. There is one `_ready`, and no required child is hidden in a scene reference.

<!-- student-code:exchange.gd -->
```gdscript
extends Node3D
const Field = preload("field.gd")
const PointBody = preload("point_body.gd")
const LIMIT := 2400
const W := Vector2i(12, 15)
var left := Field.new()
var right := Field.new()
var point: XRToolsPickable
var reading := Label3D.new()
var textures: Array[ImageTexture] = []
var show_u := false
var injections := 0

func _ready() -> void:
	right.exchange = false
	make_display()
	point = PointBody.new()
	add_child(point)
	point.action_pressed.connect(func(_body): plant())
	park()
	reset()

func reset() -> void:
	left.reset()
	right.reset()
	injections = 0
	paint()

func advance(count: int) -> void:
	for i in mini(count, LIMIT - left.ticks):
		left.step()
		right.step()
	paint()

func change_exchange() -> void:
	right.exchange = not right.exchange
	reset()

func target_site() -> Vector2i:
	if not point.held():
		return Vector2i(-1, -1)
	var at := to_local(point.global_position)
	for cx in [0.85, -0.85]:
		if absf(at.x - cx) < 0.64 and absf(at.z - 0.5) < 0.64 and absf(at.y - 1.01) < 0.35:
			return Vector2i(floori((at.x - cx + 0.64) / 0.04), floori((at.z - 0.5 + 0.64) / 0.04))
	return Vector2i(-1, -1)

func plant() -> void:
	var site := target_site()
	if site.x < 0:
		return
	left.seed_at(site)
	right.seed_at(site)
	injections += 1
	paint()

func _physics_process(_delta: float) -> void:
	if not point.held():
		park()

func park() -> void:
	point.position = Vector3(0, 1.12, -0.35)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER: advance(1)
			KEY_SPACE: advance(100)
			KEY_R: reset()
			KEY_E: change_exchange()
			KEY_V: show_u = not show_u; paint()
			KEY_I: plant()
			_: return
		get_viewport().set_input_as_handled()

func tint(value: float) -> Color:
	if show_u:
		return Color("241e46").lerp(Color("bce8bc"), value)
	return Color("122d3d").lerp(Color("edb1cb"), clampf(value * 2.0, 0.0, 1.0))

func paint() -> void:
	for side in 2:
		var field = left if side == 0 else right
		var data: PackedFloat32Array = field.u if show_u else field.v
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				image.set_pixel(x, y, tint(data[y * 32 + x]))
		textures[side].update(image)
	var i := left.index(W.x, W.y)
	reading.text = "TICK %d / W (12,15)\nA: U %.3f  V %.3f\nB: U %.3f  V %.3f\nB EXCHANGE %s / VIEW %s / SEEDS %d\nENTER: STEP   SPACE: +100   R: REPLAY\nE: EXCHANGE B   V: VIEW   TRIGGER / I: PLANT" % [left.ticks, left.u[i], left.v[i], right.u[i], right.v[i], "ON" if right.exchange else "OFF", "U" if show_u else "V x2", injections]

func box(size: Vector3, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("263744")
	node.material_override = material
	add_child(node)
	return node

func make_display() -> void:
	for side in 2:
		var cx := -0.85 if side == 0 else 0.85
		var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		var texture := ImageTexture.create_from_image(image)
		textures.append(texture)
		var title := Label3D.new()
		title.text = "A" if side == 0 else "B"
		title.position = Vector3(cx, 2.42, -0.4)
		title.font_size = 52
		title.pixel_size = 0.0015
		add_child(title)
		var finish := StandardMaterial3D.new()
		finish.albedo_texture = texture
		finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		var table := box(Vector3(1.36, 0.08, 1.36), Vector3(cx, 0.96, 0.5))
		box(Vector3(0.5, 0.92, 0.5), Vector3(cx, 0.46, 0.5))
		var body := StaticBody3D.new()
		var boundary := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.36, 0.08, 1.36)
		boundary.shape = shape
		table.add_child(body)
		body.add_child(boundary)
		for wall in [false, true]:
			var display := MeshInstance3D.new()
			var plane := PlaneMesh.new()
			plane.size = Vector2(1.28, 1.28)
			display.mesh = plane
			display.material_override = finish
			display.position = Vector3(cx, 1.7, -0.4) if wall else Vector3(cx, 1.01, 0.5)
			if wall:
				display.rotation.x = PI / 2.0
			add_child(display)
		var mark := box(Vector3(0.038, 0.004, 0.038), Vector3(cx + (W.x + 0.5 - 16) * 0.04, 1.014, 0.5 + (W.y + 0.5 - 16) * 0.04))
		var gold := StandardMaterial3D.new()
		gold.albedo_color = Color("ffe49a")
		gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gold.albedo_color.a = 0.3
		mark.material_override = gold
	reading.position = Vector3(0, 2.65, 0.5)
	reading.font_size = 30
	reading.pixel_size = 0.0013
	reading.modulate = Color("213639")
	reading.outline_modulate = Color("f5f0e8")
	add_child(reading)
```

## The same carried object — point_body.gd

This file is unchanged from the previous hall. Keep your existing copy. It appears here so the three-file example is complete.

<!-- student-code:point_body.gd -->
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

## Predict, intervene, compare

Replay with B's exchange off and step once. Check W's two answers against the table above. Press V: the colours change while the tick and stored values remain the same. Press E and step once: with exchange on for both, every address should agree.

Now restore B's exchange-off comparison. Carry the point to a different address, outside the starting square, and plant. Step 100 times. Find a site just beyond that second patch. Can anything make its first V arrive without exchange? At an untouched site, V = 0 makes the local reaction product zero. An address can receive its first V from its neighbours.

Make this guided edit: in `reset`, after `right.reset()`, add `left.seed_at(Vector2i(0, 0))` and `right.seed_at(Vector2i(0, 0))`. Predict all nine addresses before replaying. The patch appears at x = 31, 0, 1 and y = 31, 0, 1. Its split appearance is one neighbourhood crossing the periodic boundary, not four unrelated seeds. After replay, find which side can send V into an adjacent unseeded address. Remove those two added lines to return to the original beginning.

Both clocks stop at 2,400 steps. Reset to make another comparison. You leave with a field class that can be shown on more than one surface, a point that can intervene without replacing the rule, and a distinction between what happens at an address and what can arrive from elsewhere. The next hall compares a cellular history with recursive construction: similar forms can have different ways of becoming.

## Your own test

Choose an untouched address beside a seed of your own. Calculate its first U/V pair with exchange on and off before stepping. Keep both beginnings identical. Keep your prediction, the observed values and a runnable assertion in a separate test script. If they disagree, identify whether the prediction, test or study needs changing.

