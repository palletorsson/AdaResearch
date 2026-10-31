extends Node3D
class_name PocketTest
## THE POCKET TEST (Palle, 2026-10-31, after "Comparative Topological Flow Analysis Using Perlin and Related Noise
## Fields", Torsson 2025): a button on the slot's front edge releases a hundred balls over the surface - half a metre
## across, in random bright colours, steel-heavy, hardly bouncy - and they fall and roll. Some settle in the surface's pockets, some run out to the flat rim,
## some keep rolling. The counts are a reading of the surface: a random ground pockets more than a sine ground, which
## pockets in its troughs. Beside the counts stands the surface's SHANNON ENTROPY of normals in bits (256 equal-area
## bins on the upper hemisphere), the paper's complexity measure. Jolt is the engine. Placed by a receiving place
## (place_builder: activity "test": "balls") over the same slot as the surface, or by hand with slot_size set.

signal settled(result: Dictionary)

@export var count := 100
@export var diameter := 0.5            ## Palle: "the size of the balls matters - like 50 cm"; radii vary a little around it
@export var radius_min := 0.22
@export var radius_max := 0.28
@export var bounce := 0.1
@export var friction := 0.5
@export var drop_height := 1.5          ## above the slot's rim height
@export var settle_seconds := 8.0       ## the reading is final this long after the release
@export var slot_size := Vector2(10, 8)
@export var slot_depth := 1.0
@export var rim_width := 0.5
@export var surface_name := ""          ## the sibling surface the entropy is read from ("" = the nearest TopologySpace sibling)
@export var seed_value := 7

const LAYER := 1 << 25
var balls: Array[RigidBody3D] = []
var since_release := -1.0
var result: Dictionary = {}
var readout: Label3D
var button: Node3D
var rng := RandomNumberGenerator.new()
var _mesh_cache: Dictionary = {}

func _ready() -> void:
	apply_grid_config(_meta_config())
	_build()

func _meta_config() -> Dictionary:
	var cfg := {}
	for m in get_meta_list():
		if str(m).begins_with("config_"):cfg[str(m).trim_prefix("config_")] = get_meta(m)
	return cfg

func apply_grid_config(config: Dictionary) -> void:
	if config.has("slot_size") and config.slot_size is Array and (config.slot_size as Array).size() == 2:slot_size = Vector2(float(config.slot_size[0]), float(config.slot_size[1]))
	if config.has("slot_depth"):slot_depth = float(config.slot_depth)
	if config.has("rim_width"):rim_width = float(config.rim_width)
	if config.has("count"):count = clampi(int(config.count), 1, 400)
	if config.has("diameter"):diameter = clampf(float(config.diameter), 0.08, 1.2);radius_min = diameter * .44;radius_max = diameter * .56
	if config.has("bounce"):bounce = clampf(float(config.bounce), 0.0, 1.0)
	if config.has("friction"):friction = clampf(float(config.friction), 0.0, 1.0)
	if config.has("drop_height"):drop_height = float(config.drop_height)
	if config.has("settle_seconds"):settle_seconds = float(config.settle_seconds)
	if config.has("surface"):surface_name = str(config.surface)
	if config.has("seed"):seed_value = int(config.seed)
	if button != null:_place_furniture()

## The button on a stem at the slot's front edge, the readout above it.
func _build() -> void:
	var scene: PackedScene = load("res://commons/interactables/push_button.tscn")
	button = scene.instantiate();button.name = "ReleaseButton";add_child(button)
	button.rotation = Vector3.ZERO
	if button.has_signal("pressed"):button.pressed.connect(release)
	var stem := MeshInstance3D.new();stem.name = "Stem";var cm := CylinderMesh.new();cm.top_radius = .02;cm.bottom_radius = .025;cm.height = .9;stem.mesh = cm
	var sm := StandardMaterial3D.new();sm.albedo_color = Color("8d9e9a");stem.material_override = sm;add_child(stem)
	var plate := MeshInstance3D.new();plate.name = "Plate";var bm := BoxMesh.new();bm.size = Vector3(.3, .02, .2);plate.mesh = bm
	var pm := StandardMaterial3D.new();pm.albedo_color = Color("263638");plate.material_override = pm;add_child(plate)
	readout = Label3D.new();readout.name = "Readout";readout.font_size = 28;readout.pixel_size = .004;readout.modulate = Color("e5efe9")
	readout.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y;readout.text = "POCKET TEST\npress to release %d balls" % count;add_child(readout)
	_place_furniture()

func _place_furniture() -> void:
	var front := Vector3(0, 0, slot_size.y / 2.0 + 0.45)
	get_node("Stem").position = front + Vector3(0, .45, 0)
	get_node("Plate").position = front + Vector3(0, .9, 0)
	button.position = front + Vector3(0, .92, 0)
	readout.position = front + Vector3(0, 1.35, 0)

## The surface the entropy is read from: the named sibling, else the nearest TopologySpace beside this node.
func surface() -> Node3D:
	var parent := get_parent()
	if parent == null:return null
	if surface_name != "":
		var n: Node = parent.get_node_or_null(surface_name)
		if n is Node3D:return n
	var best: Node3D = null;var best_d := INF
	for c in parent.get_children():
		if c is TopologySpace:
			var d: float = (c as Node3D).global_position.distance_to(global_position)
			if d < best_d:best_d = d;best = c
	return best

## THE RELEASE: the balls in a jittered grid over the footprint inside the rim, above the rim height, let fall.
func release() -> void:
	clear()
	rng.seed = seed_value
	var inner := Vector2(slot_size.x - 2.0 * rim_width - 2.0 * radius_max, slot_size.y - 2.0 * rim_width - 2.0 * radius_max).max(Vector2(.5, .5))
	var cols := int(ceil(sqrt(float(count) * inner.x / inner.y)));var rows := int(ceil(float(count) / float(cols)))
	var physics := PhysicsMaterial.new();physics.bounce = bounce;physics.friction = friction
	var i := 0
	for r in rows:
		for c in cols:
			if i >= count:break
			var rad: float = rng.randf_range(radius_min, radius_max)
			var x: float = -inner.x / 2.0 + (c + .5) * inner.x / cols + rng.randf_range(-.1, .1) * inner.x / cols
			var z: float = -inner.y / 2.0 + (r + .5) * inner.y / rows + rng.randf_range(-.1, .1) * inner.y / rows
			var ball := RigidBody3D.new();ball.name = "Ball%d" % i
			ball.collision_layer = LAYER;ball.collision_mask = 1 | LAYER
			ball.mass = 7800.0 * (4.0 / 3.0) * PI * rad * rad * rad * 0.1   # steel-dense, scaled down so a hundred stay cheap for Jolt
			ball.physics_material_override = physics;ball.continuous_cd = true;ball.angular_damp = 1.0;ball.linear_damp = 0.15
			var shape := CollisionShape3D.new();var sphere := SphereShape3D.new();sphere.radius = rad;shape.shape = sphere;ball.add_child(shape)
			# random bright colours (Palle): a full hue each, saturated, light
			var mi := MeshInstance3D.new();mi.mesh = _ball_mesh(rad);var mat := StandardMaterial3D.new();mat.albedo_color = Color.from_hsv(rng.randf(), .85, 1.0);mat.metallic = .1;mat.roughness = .4;mi.material_override = mat;ball.add_child(mi)
			ball.position = Vector3(x, slot_depth + drop_height + (i % 7) * (radius_max * .6), z)
			add_child(ball);balls.append(ball);i += 1
	since_release = 0.0;result = {}
	readout.text = "RELEASED %d\n..." % balls.size()

func _ball_mesh(rad: float) -> SphereMesh:
	var key := snappedf(rad, .005)
	if not _mesh_cache.has(key):
		var m := SphereMesh.new();m.radius = key;m.height = key * 2;m.radial_segments = 20;m.rings = 10;_mesh_cache[key] = m
	return _mesh_cache[key]

func clear() -> void:
	for b in balls:
		if is_instance_valid(b):b.queue_free()
	balls.clear();since_release = -1.0

## The reading: pocketed = at rest inside the rim; rim = at rest on the flat rim or against the wall; rolling =
## still moving; gone = fallen below the slot.
func reading() -> Dictionary:
	var pocketed := 0;var rim := 0;var rolling := 0;var gone := 0
	var hx := slot_size.x / 2.0 - rim_width;var hz := slot_size.y / 2.0 - rim_width
	for b in balls:
		if not is_instance_valid(b):continue
		var p := b.position
		if p.y < -2.0:gone += 1;continue
		var resting: bool = b.sleeping or b.linear_velocity.length() < .05
		if not resting:rolling += 1
		elif absf(p.x) < hx and absf(p.z) < hz:pocketed += 1
		else:rim += 1
	return {"released": balls.size(), "pocketed": pocketed, "rim": rim, "rolling": rolling, "gone": gone, "seconds": since_release}

func _physics_process(delta: float) -> void:
	if since_release < 0.0:return
	since_release += delta
	if int(since_release * 2.0) != int((since_release - delta) * 2.0) or since_release >= settle_seconds:
		var r := reading();var s: Node3D = surface();var h: float = surface_entropy_bits(s)
		r["entropy_bits"] = h;r["surface"] = str(s.name) if s else ""
		readout.text = "RELEASED %d\nPOCKETED %d   RIM %d   ROLLING %d%s\nsurface entropy %.2f bits" % [r.released, r.pocketed, r.rim, r.rolling, ("   GONE %d" % r.gone) if r.gone > 0 else "", h]
		if since_release >= settle_seconds and result.is_empty():
			result = r;readout.text += "\n(settled)"
			print("[pocket_test] surface=%s released=%d pocketed=%d rim=%d rolling=%d gone=%d entropy=%.2f" % [r.surface, r.released, r.pocketed, r.rim, r.rolling, r.gone, h])
			settled.emit(r)

## SHANNON ENTROPY OF THE SURFACE'S NORMALS (Torsson 2025): each cell's normal from the last heights, binned into
## 256 equal-area bins on the upper hemisphere (16 bands of equal cos(theta), 16 wedges of phi); H = -sum p log2 p.
static func surface_entropy_bits(s: Node3D) -> float:
	if s == null:return 0.0
	var heights: Array = s.get("_last_heights") if s.get("_last_heights") is Array else []
	var res: int = int(s.get("resolution")) if s.get("resolution") != null else 0
	var size: Vector2 = s.get("space_size") if s.get("space_size") is Vector2 else Vector2.ZERO
	if heights.size() != (res + 1) * (res + 1) or res < 2 or size.x <= 0.0:return 0.0
	var dx := size.x / float(res);var dz := size.y / float(res)
	var bins := PackedInt32Array();bins.resize(256);var total := 0
	for z in range(res):
		for x in range(res):
			var i := z * (res + 1) + x
			var hx: float = (float(heights[i + 1]) - float(heights[i])) / dx
			var hz: float = (float(heights[i + res + 1]) - float(heights[i])) / dz
			var n := Vector3(-hx, 1.0, -hz).normalized()
			var band: int = clampi(int((1.0 - n.y) * 16.0), 0, 15)             # equal area in cos(theta)
			var wedge: int = clampi(int((atan2(n.z, n.x) + PI) / TAU * 16.0), 0, 15)
			bins[band * 16 + wedge] += 1;total += 1
	var h := 0.0
	for b in bins:
		if b > 0:
			var p := float(b) / float(total);h -= p * log(p) / log(2.0)
	return h
