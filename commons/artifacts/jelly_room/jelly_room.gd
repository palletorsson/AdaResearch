extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name JellyRoom

## @identity
## name: "Jelly & deformation"
## tier: large
## lineage: Verlet jelly cubes — eight corners held by every pair-spring. Deform one
##   and the whole lattice negotiates a new shape, then the springs pull it home.
## essence: A room you walk among, planted with wobbling jelly pillars. Each pillar is a
##   pre-settled soft-body cube stacked into a column; the whole room breathes with a slow,
##   gentle wobble. You can move between them — nothing here is rigid, and nothing holds a dent.
## truth: "PUSH IT, IT PUSHES BACK, THEN FORGETS"
## applications: gels, soft robotics, crash foam, biological tissue — shapes that yield and return.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var pillar_count: int = 7
@export var ring_radius: float = 2.4
@export var pillar_size: float = 0.62
@export var stiffness: float = 0.85
@export var floor_col: Color = Color(0.12, 0.12, 0.15)
@export var jelly_a: Color = Color(0.85, 0.32, 0.45)
@export var jelly_b: Color = Color(0.38, 0.55, 0.92)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _pillars: Array = []   # each: { node:Node3D, sim, mm:MultiMesh, base:Vector3, phase:float }


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("pillar_count"):
		pillar_count = int(clampf(float(config["pillar_count"]), 3, 12))
	if config.has("ring_radius"):
		ring_radius = clampf(float(config["ring_radius"]), 1.2, 3.2)
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.5, 0.97)
	if config.has("jelly_a"):
		jelly_a = _parse_color(config["jelly_a"], jelly_a)
	if config.has("jelly_b"):
		jelly_b = _parse_color(config["jelly_b"], jelly_b)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_pillars.clear()
	_build()


func _build() -> void:
	# Room floor — large slab the player stands on.
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_col, 0.9)))

	# Ring of jelly pillars.
	for p in range(pillar_count):
		var ang: float = TAU * float(p) / float(pillar_count)
		var base := Vector3(cos(ang) * ring_radius, 0.0, sin(ang) * ring_radius)
		var col: Color = jelly_a if p % 2 == 0 else jelly_b
		_add_pillar(base, col, float(p) * 0.9)

	# A lone centre pillar so the room reads as inhabited, not just a wall-ring.
	_add_pillar(Vector3.ZERO, jelly_a.lerp(jelly_b, 0.5), 1.7)

	add_child(_billboard_label("PUSH IT, IT PUSHES BACK, THEN FORGETS", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _add_pillar(base: Vector3, col: Color, phase: float) -> void:
	# Stack three jelly cubes into a ~1.9m column of one merged particle cloud.
	var sim = SBShapes.make_jelly_box(pillar_size, stiffness)
	sim.floor_y = 0.0
	sim.gravity = Vector3(0.0, -2.4, 0.0)
	sim.damping = 0.92
	# Add two more cube-layers above the first so a pillar has height.
	var layer_h: float = pillar_size * 1.05
	for layer in [1, 2]:
		var off: float = float(layer) * layer_h
		var start: int = sim.positions.size()
		var hs: float = pillar_size * 0.5
		for z in [-1, 1]:
			for y in [-1, 1]:
				for x in [-1, 1]:
					sim.add_particle(base + Vector3(x * hs, y * hs + pillar_size + off, z * hs), false)
		for i in range(8):
			for j in range(i + 1, 8):
				sim.add_spring(start + i, start + j)
		# Tie this layer to the one below for a continuous column.
		var below: int = start - 8
		for k in range(8):
			sim.add_spring(below + k, start + k)

	for _i in 40:
		sim.step()

	var node := Node3D.new()
	node.position = base
	add_child(node)

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = pillar_size * 0.30
	sm.height = pillar_size * 0.60
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = sim.positions.size()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.35 if emissive else 0.0
	mmi.material_override = mat
	node.add_child(mmi)

	_pillars.append({ "node": node, "sim": sim, "mm": mm, "base": base, "phase": phase })
	_refresh_pillar(_pillars.size() - 1)


func _refresh_pillar(idx: int) -> void:
	var pil: Dictionary = _pillars[idx]
	var sim = pil["sim"]
	var mm: MultiMesh = pil["mm"]
	var base: Vector3 = pil["base"]
	for i in sim.positions.size():
		var t := Transform3D.IDENTITY
		# positions are world-space relative to ring; node sits at base, so subtract it.
		t.origin = sim.positions[i] - base
		mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for idx in range(_pillars.size()):
		var pil: Dictionary = _pillars[idx]
		var sim = pil["sim"]
		var node: Node3D = pil["node"]
		var phase: float = pil["phase"]
		# Gentle wobble: nudge the top particles sideways, let springs carry it down.
		var w: float = sin(_t * 1.3 + phase) * 0.012
		var base: Vector3 = pil["base"]
		for i in sim.positions.size():
			if sim.positions[i].y > pillar_size * 1.8:
				sim.positions[i].x += w
				sim.positions[i].z += w * 0.6
		sim.step()
		_refresh_pillar(idx)
		# Whole-node breathing sway on top of the spring motion.
		node.rotation.z = sin(_t * 0.9 + phase) * 0.03
