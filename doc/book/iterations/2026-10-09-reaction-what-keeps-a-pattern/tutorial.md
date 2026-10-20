# What keeps a pattern changing?

## Learning elements

- Local reaction, supply and removal
- Exchange and reaction as separate contributions
- Old state and next state
- Matched starts and equal step counts
- A concentration field and its colour display

<!-- @turing_pattern_generator -->

At the desk, press STEP, then 100 STEPS. The little patch changes slowly. RESET brings it back. REGIME changes two rates and restarts; SEEDING changes the starting arrangement. Compare one intervention at a time.

In the previous hall you changed the appearance of a saved surface without changing its data. Here the data change. Return to the two fields from **CA — What a neighbour offers**. Both contain U and V at every address. That lesson compared neighbour exchange while a supplied reaction ran in both. Now keep exchange in both and open that reaction function.

## Keep the field; open the local rule

Reuse the CA lesson's `field.gd`, two-table display and PointBody. Replace the field with the complete version below; use `reaction.gd` for this comparison. A keeps reaction, supply and removal. B begins with those local terms off, so it only exchanges with its neighbours. Both start from the same 6 × 6 patch and advance the same number of steps.

The new work is in `next_pair`. `conversion = a * b * b` removes an amount from U and adds the same amount to V. With no V present, this conversion is zero. `supply = FEED * (1 - a)` replenishes U toward one. `removal = (KILL + FEED) * b` removes V: in this model, feed also contributes to V's removal. These are the local Gray–Scott terms.[^model]

Neighbour exchange is added separately. The four-neighbour stencil, diffusion coefficients, wrapping boundary and starting square are carried from CA. The installed hall display uses weighted contributions from eight neighbours and different default rates. It demonstrates the same kind of model; it is not an identical numerical run. We keep the learner's known stencil so this lesson changes one part of their program.

One call remains one numerical step with dt = 1, not one second of physical time. Read old U and V, write next U and V, then replace both arrays. The clamp keeps the output in 0–1; it does not make arbitrary coefficients or larger timesteps accurate or stable.

## Predict one address

W is now (15,15), inside the patch. All four neighbours initially match its U = 0.5 and V = 0.25, so both neighbour differences are zero. This position isolates the local terms for the first step.

| Term | Amount |
| --- | --- |
| Conversion from U to V | 0.5 × 0.25 × 0.25 = 0.03125 |
| Supply of U | 0.037 × (1 − 0.5) = 0.0185 |
| Removal of V | (0.060 + 0.037) × 0.25 = 0.02425 |

After one step, A has **U = 0.48725, V = 0.257** at W. B stays **U = 0.5, V = 0.25** there. B still changes around the patch boundary through exchange. Turning off local terms does not freeze the whole field.

## Complete field.gd

<!-- student-code:field.gd -->
```gdscript
extends RefCounted
const N := 32
const FEED := 0.037
const KILL := 0.060
var u := PackedFloat32Array()
var v := PackedFloat32Array()
var exchange := true
var local_terms := true
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
	# Keep the CA lesson's four-neighbour exchange; one numerical step has dt = 1.
	var coupling := 1.0 if exchange else 0.0
	var du := coupling * 0.16 * lap_u
	var dv := coupling * 0.08 * lap_v
	if local_terms:
		var conversion := a * b * b
		var supply := FEED * (1.0 - a)
		var removal := (KILL + FEED) * b
		du += -conversion + supply
		dv += conversion - removal
	return Vector2(clampf(a + du, 0.0, 1.0), clampf(b + dv, 0.0, 1.0))

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

## Run the comparison in the museum

Use your existing museum project with its player, camera, lighting and XRTools. Keep the three files together. Attach `reaction.gd` to a Node3D at floor level and unit scale, facing its positive Z side, with about 3.3 × 2.4 metres clear. The downloadable `study.tscn` contains only that root and script attachment. Every display, material, label and control point used here is created in code.

The staging is carried from CA. W moves inside the patch; the comparison switch now controls local terms instead of exchange. The unchanged black point still selects an address. Hold it just above either table and trigger to replace a 3 × 3 patch at the corresponding address in both fields. Away from the table, or when unheld, it changes nothing. A new patch changes state without changing the rule or the clock. Release parks the point on its shelf.

- **Enter:** one step. **Space:** 100 steps, up to 2,400.
- **C:** enable/disable B's local terms and restart both fields together.
- **R:** replay from the starting square, preserving the comparison setting.
- **V:** display U or V. This changes the view, not the state.
- **Point trigger / I while holding:** plant the same patch in both fields.

The compact learner uses keyboard controls for time and comparison, with XR/desktop pickup for planting. The installed hall supplies its own nearby VR desk. This reconstruction does not claim that its clock is operated by the point trigger.

## Complete reaction.gd

Read `advance`, `change_local_terms` and `plant` first. The display helpers are the carried construction, not a second task to learn here. Each table and its upright panel share a texture. V is mapped through V × 2 before colouring: a saturated colour is not proof that the stored concentration is one.

<!-- student-code:reaction.gd -->
```gdscript
extends Node3D
const Field = preload("field.gd")
const PointBody = preload("point_body.gd")
const LIMIT := 2400
const W := Vector2i(15, 15)
var left := Field.new()
var right := Field.new()
var point: XRToolsPickable
var reading := Label3D.new()
var textures: Array[ImageTexture] = []
var show_u := false
var injections := 0

func _ready() -> void:
	right.local_terms = false
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

func change_local_terms() -> void:
	right.local_terms = not right.local_terms
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
			KEY_C: change_local_terms()
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
	reading.text = "TICK %d / W (15,15)\nA: U %.3f  V %.3f\nB: U %.3f  V %.3f\nB LOCAL TERMS %s / VIEW %s / SEEDS %d\nENTER: STEP   SPACE: +100   R: REPLAY\nC: LOCAL TERMS B   V: VIEW   TRIGGER / I: PLANT" % [left.ticks, left.u[i], left.v[i], right.u[i], right.v[i], "ON" if right.local_terms else "OFF", "U" if show_u else "V x2", injections]

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
		title.text = "A / REACTION + EXCHANGE" if side == 0 else "B / EXCHANGE + OPTIONAL REACTION"
		title.position = Vector3(cx, 2.42, -0.4)
		title.font_size = 22
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

## Make a comparison of your own

Set FEED to `0.050`, leaving KILL, the initial patch and exchange unchanged. Predict the first step at W: U should become **0.49375**, V **0.25375** in A, while B's first-step values stay unchanged. Feed appears in two places, so increasing it both supplies more U and removes more V.

Run from reset. Compare the numbers after one step before comparing the patterns after 100 or 1,000. To recover an identical pair, enable B's local terms and restart: every value in A and B should agree at the same step. If they do not, inspect their starting state, parameters and update order before interpreting the picture.

The next hall maps values into a three-dimensional surface. Carry a clear distinction: stored concentrations, a rule that changes them, and the display through which you see them.

## Carried point_body.gd — unchanged

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

<!-- @ -->

<!-- @reaction_diffusion -->

## Other encounters in this hall

The second reaction–diffusion display has its own implementation and clock. It is a comparison to explore, not a synchronized copy of this study. The soft-body samples, bulge and Confessing Body remain wider encounters. The tutorial follows one pair of fields; no additional artifact has to become a prerequisite.

<!-- @ -->

[^model]: John E. Pearson, [“Complex Patterns in a Simple System”](https://arxiv.org/abs/patt-sol/9304003), 1993, studies numerical Gray–Scott patterns. This tutorial uses the project's reduced discretization. Its two concentration variables and colour map are not measurements of chemicals in the room.
