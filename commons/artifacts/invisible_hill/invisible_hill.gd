extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name InvisibleHill

## @identity
## lineage: the Force-field category's hero, elevating force_field_zone — a flat dark
##   green, dead level, nothing on it. Pucks glide across from the rim and SWERVE around
##   a middle where nothing stands, climbing and descending a hill that exists only as
##   force. Their light-trails pile up into the hill's portrait: contour lines drawn by
##   refusal.
## essence: falling isn't a property of the void, it's a property of the field over it.
##   The floor is flat; the FIELD is a hill (radial 1/r² repulsion). Every puck
##   integrates the same field live, so the swerve is computed, not choreographed —
##   watch long enough and the invisible summit is the best-mapped place in the room.
## truth: a zone is a force with a border. You learn the hill's shape the way the pucks
##   do: by never being allowed across it.
##
## The 2026-08-27 brief: surreal, fun, beautiful, applied — the uncanny made functional.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const POOL := 10                       # gliding pucks, recycled at the rim — never freed
const TRAIL_LEN := 150                 # ~2.5 s of ribbon at 60 fps

@export var seed: int = 17
@export var green_r: float = 2.3       # the flat "lawn" the hill secretly owns
## Field strength: mu / r² away from the centre, clamped inside 0.3 m. 1.4 turns a
## centre-aimed puck around ~0.5 m out; the miss distance IS the contour it draws.
@export var mu: float = 1.4
@export var launch_speed: float = 1.35

var _pucks: Array = []                 # {node, vel, trail: Array, mesh: ImmediateMesh}
var _spawn_clock := 0.0
var _next := 0

func _ready() -> void:
	_rng.seed = seed
	_build_green()
	_build_pucks()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "green_r", "mu", "launch_speed"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(delta: float) -> void:
	var dt: float = minf(delta, 1.0 / 30.0)
	_spawn_clock += dt
	if _spawn_clock > 0.9:
		_spawn_clock = 0.0
		_relaunch(_pucks[_next])
		_next = (_next + 1) % _pucks.size()
	for p in _pucks:
		var node: Node3D = p["node"]
		if not node.visible:
			continue
		var pos: Vector3 = node.position
		var flat := Vector3(pos.x, 0.0, pos.z)
		# THE HILL: radial repulsion, mu / r², the same law gravity runs in reverse.
		var acc := flat.normalized() * (mu / maxf(flat.length_squared(), 0.09))
		p["vel"] += acc * dt
		node.position += p["vel"] * dt
		node.position.y = 0.12
		node.rotation.y += dt * 2.0
		_update_trail(p)
		if Vector3(node.position.x, 0.0, node.position.z).length() > green_r + 0.3:
			node.visible = false          # off the green: parked until relaunch

func _relaunch(p: Dictionary) -> void:
	# Enter from a random rim point, aimed NEAR the centre with a small offset — the
	# offsets fan the family of paths, and the family draws the hill.
	var ang := _rng.randf_range(0.0, TAU)
	var start := Vector3(cos(ang), 0.0, sin(ang)) * green_r
	var aim := Vector3(_rng.randf_range(-0.35, 0.35), 0.0, _rng.randf_range(-0.35, 0.35))
	var node: Node3D = p["node"]
	node.position = start + Vector3(0.0, 0.12, 0.0)
	node.visible = true
	p["vel"] = (aim - start).normalized() * launch_speed
	p["trail"].clear()

# --- build --------------------------------------------------------------------------

func _build_green() -> void:
	var green := MeshInstance3D.new()
	var green_mesh := CylinderMesh.new()
	green_mesh.top_radius = green_r
	green_mesh.bottom_radius = green_r + 0.08
	green_mesh.height = 0.09
	green.mesh = green_mesh
	green.position = Vector3(0.0, 0.045, 0.0)
	green.material_override = _matte_mat(Color(0.10, 0.16, 0.11), 0.95)
	add_child(green)
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = green_r - 0.03
	rim_mesh.outer_radius = green_r + 0.09
	rim.mesh = rim_mesh
	rim.position = Vector3(0.0, 0.09, 0.0)
	rim.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(rim)
	# the summit marker that ISN'T: a faint ring of disturbed air where the hill's
	# foot would be — barely-there, the only concession to the eye
	var ghost := MeshInstance3D.new()
	var ghost_mesh := TorusMesh.new()
	ghost_mesh.inner_radius = 0.42
	ghost_mesh.outer_radius = 0.46
	ghost.mesh = ghost_mesh
	ghost.position = Vector3(0.0, 0.1, 0.0)
	var gm := _glow_mat(Color(0.75, 0.85, 0.95), 0.5)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color.a = 0.10
	ghost.material_override = gm
	add_child(ghost)

func _build_pucks() -> void:
	for i in range(POOL):
		var puck := MeshInstance3D.new()
		var puck_mesh := CylinderMesh.new()
		puck_mesh.top_radius = 0.09
		puck_mesh.bottom_radius = 0.11
		puck_mesh.height = 0.07
		puck.mesh = puck_mesh
		puck.material_override = _glow_mat(Color(0.95, 0.85, 0.40), 1.3)
		puck.visible = false
		add_child(puck)
		var trail := MeshInstance3D.new()
		var im := ImmediateMesh.new()
		trail.mesh = im
		var tm := _glow_mat(Color(0.95, 0.85, 0.40), 0.8)
		tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tm.albedo_color.a = 0.35
		trail.material_override = tm
		add_child(trail)
		_pucks.append({"node": puck, "vel": Vector3.ZERO, "trail": [], "mesh": im})
	# seed the green so a capture is never empty: three pucks mid-glide at t0
	for k in range(3):
		_relaunch(_pucks[k])
		_next = (k + 1) % POOL

func _update_trail(p: Dictionary) -> void:
	var trail: Array = p["trail"]
	trail.append(p["node"].position)
	if trail.size() > TRAIL_LEN:
		trail.pop_front()
	var im: ImmediateMesh = p["mesh"]
	im.clear_surfaces()
	if trail.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for v in trail:
		im.surface_add_vertex(v)
	im.surface_end()

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "HillPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-green_r - 0.35, 0.24, 0.85)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("INVISIBLE HILL",
			"The floor is flat. The FIELD is a hill: mu/r2, integrated live by every puck.\nFalling isn't a property of the void - it's a property of the field over it.\nThe trails are the hill's portrait, drawn by refusal.")
