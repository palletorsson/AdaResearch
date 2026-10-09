extends Node3D

# @identity
# essence: pyramid(5 vertices) rebuilt from 5 draggable handles — apex and 4 base corners all movable
# desire: learner discovers that the pyramid shape is not fixed — every vertex is a degree of freedom
# critical_parameter: apex handle — moving it changes the character from flat to tall, from pyramid to spike
# triggers: dragging any of the 5 grab sphere handles — mesh rebuilds instantly from new vertex positions
# emerges: the intuition that named shapes are just default parameterisations of a more general vertex space
# needs: [has 5 grabbable vertex handles [has], symmetry-lock toggle via the constraint axis [has]]
# relationships: interactive version of pyramid.gd; sibling to animatedcubebuilder and triangle
# truth: a pyramid is just a parameterisation — move the apex and it stops being a pyramid

##
## STAGE-2 DNA PROMOTION (2026-07-29). The script had no exports: five handles,
## all of them free, always. That is one position in a parameter space the artifact
## itself names — its @identity listed "missing symmetry-lock toggle" as a need, and
## its truth line ("a pyramid is just a parameterisation") is only half the sentence.
## The other half is that a parameterisation is defined by what it FORBIDS. One axis —
##
##   constraint   which degrees of freedom the handles actually offer
##                free · symmetric · apex_only · base_only
##
## free is the pre-promotion behaviour exactly (no positions are ever written back)
## and is the default, so all 11 existing placements are untouched. Under symmetric
## the base can only ever be a rectangle centred under the apex, so no amount of
## dragging escapes the family of right pyramids; under apex_only the base is frozen
## and the artifact argues its own truth line literally; under base_only the apex is
## nailed and the learner deforms the footprint under a fixed peak.
##
## Usage in map_data.json:
##   "pyramid_edit#constraint:symmetric"
##   "pyramid_edit#constraint:apex_only"

const HANDLE_SCENE := preload("res://commons/primitives/point/grab_sphere_point.tscn")
const HANDLE_ORDER := [
	"base_back_left",
	"base_back_right",
	"base_front_right",
	"base_front_left",
	"apex"
]

## Which degrees of freedom the five handles offer. free = every vertex independent
## (the original). symmetric = the four base corners mirror each other and the apex
## stays on the centre axis. apex_only = base frozen. base_only = apex frozen.
@export_enum("free", "symmetric", "apex_only", "base_only") var constraint: String = "free"

var base_color: Color = Color(1.0, 0.8, 0.2)
var pyramid_height: float = 0.8
var base_size: float = 0.6

var mesh_instance: MeshInstance3D
var handle_nodes: Dictionary = {}
var last_handle_positions: Dictionary = {}
var _home_positions: Dictionary = {}

func _ready():
	_create_handles()
	_rebuild_pyramid()
	set_process(true)

func _process(_delta: float) -> void:
	var moved: Array = _changed_handles()
	if moved.is_empty():
		return
	if constraint != "free":
		_apply_constraint(moved)
	_rebuild_pyramid()

func _create_handles() -> void:
	if not handle_nodes.is_empty():
		return

	var half_base := base_size * 0.5
	var defaults := {
		"base_back_left": Vector3(-half_base, 0.0, -half_base),
		"base_back_right": Vector3(half_base, 0.0, -half_base),
		"base_front_right": Vector3(half_base, 0.0, half_base),
		"base_front_left": Vector3(-half_base, 0.0, half_base),
		"apex": Vector3(0.0, pyramid_height, 0.0)
	}

	for name in HANDLE_ORDER:
		var handle := HANDLE_SCENE.instantiate()
		handle.name = name
		handle.position = defaults.get(name, Vector3.ZERO)
		handle.alter_freeze = false
		handle.freeze = true
		handle.set_meta("pyramid_handle", name)
		add_child(handle)
		handle_nodes[name] = handle
		_home_positions[name] = handle.position
		if owner:
			handle.owner = owner

	_sync_handle_positions()

func _rebuild_pyramid() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertices := _get_current_vertices()
	if handle_nodes.size() == HANDLE_ORDER.size():
		var base_points := [
			handle_nodes["base_back_left"].position,
			handle_nodes["base_back_right"].position,
			handle_nodes["base_front_right"].position,
			handle_nodes["base_front_left"].position
		]
		var perimeter := 0.0
		for j in base_points.size():
			var next_index := (j + 1) % base_points.size()
			perimeter += (base_points[next_index] - base_points[j]).length()
		base_size = perimeter / float(base_points.size())
		pyramid_height = handle_nodes["apex"].position.y
	var faces := _create_pyramid_faces()
	for face in faces:
		_add_triangle_with_normal(st, vertices, face)

	var mesh := st.commit()
	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "Pyramid"
		add_child(mesh_instance)
		if owner:
			mesh_instance.owner = owner
		apply_queer_material(mesh_instance, base_color)

	mesh_instance.mesh = mesh
	_sync_handle_positions()

func _get_current_vertices() -> Array:
	if handle_nodes.size() == HANDLE_ORDER.size():
		return [
			handle_nodes["base_back_left"].position,
			handle_nodes["base_back_right"].position,
			handle_nodes["base_front_right"].position,
			handle_nodes["base_front_left"].position,
			handle_nodes["apex"].position
		]

	var half_base := base_size * 0.5
	return [
		Vector3(-half_base, 0, -half_base),
		Vector3(half_base, 0, -half_base),
		Vector3(half_base, 0, half_base),
		Vector3(-half_base, 0, half_base),
		Vector3(0, pyramid_height, 0)
	]

func _create_pyramid_faces() -> Array:
	return [
		[0, 2, 1],
		[0, 3, 2],
		[0, 1, 4],
		[1, 2, 4],
		[2, 3, 4],
		[3, 0, 4]
	]

func _add_triangle_with_normal(st: SurfaceTool, vertices: Array, face: Array) -> void:
	var v0: Vector3 = vertices[face[0]]
	var v1: Vector3 = vertices[face[1]]
	var v2: Vector3 = vertices[face[2]]

	var normal := (v1 - v0).cross(v2 - v0).normalized()

	st.set_normal(normal)
	st.add_vertex(v0)
	st.set_normal(normal)
	st.add_vertex(v1)
	st.set_normal(normal)
	st.add_vertex(v2)

func apply_queer_material(mesh: MeshInstance3D, color: Color) -> void:
	var material := ShaderMaterial.new()
	var shader := load("res://commons/resourses/shaders/SimpleGrid.gdshader")
	if shader:
		material.shader = shader
		material.set_shader_parameter("base_color", color)
		material.set_shader_parameter("edge_color", Color.WHITE)
		material.set_shader_parameter("edge_width", 1.5)
		material.set_shader_parameter("edge_sharpness", 2.0)
		material.set_shader_parameter("emission_strength", 1.0)
		mesh.material_override = material
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = color
		fallback.emission_enabled = true
		fallback.emission = color * 0.3
		mesh.material_override = fallback

func set_base_color(color: Color) -> void:
	base_color = color
	if mesh_instance:
		apply_queer_material(mesh_instance, base_color)

func set_pyramid_size(height: float, base: float) -> void:
	pyramid_height = height
	base_size = base
	if handle_nodes.is_empty():
		_create_handles()

	var half := base * 0.5
	if handle_nodes.has("base_back_left"):
		handle_nodes["base_back_left"].position = Vector3(-half, 0.0, -half)
	if handle_nodes.has("base_back_right"):
		handle_nodes["base_back_right"].position = Vector3(half, 0.0, -half)
	if handle_nodes.has("base_front_right"):
		handle_nodes["base_front_right"].position = Vector3(half, 0.0, half)
	if handle_nodes.has("base_front_left"):
		handle_nodes["base_front_left"].position = Vector3(-half, 0.0, half)
	if handle_nodes.has("apex"):
		handle_nodes["apex"].position = Vector3(0.0, height, 0.0)

	for hname in HANDLE_ORDER:
		var key: String = str(hname)
		if handle_nodes.has(key):
			_home_positions[key] = handle_nodes[key].position

	_sync_handle_positions()
	_rebuild_pyramid()

## Names of the handles the player has moved since the last rebuild.
func _changed_handles() -> Array:
	var changed: Array = []
	if handle_nodes.is_empty():
		return changed

	for name in HANDLE_ORDER:
		if not handle_nodes.has(name):
			continue
		var handle: Node3D = handle_nodes[name]
		var pos := handle.position
		var last_position = last_handle_positions.get(name)
		if last_position == null or not pos.is_equal_approx(last_position):
			changed.append(str(name))
			last_handle_positions[name] = pos

	return changed

## Write handle positions back so the moved handle only bought the freedom this
## constraint allows. Never called when constraint == "free", which is the default,
## so the original behaviour touches no positions at all.
func _apply_constraint(moved: Array) -> void:
	match constraint:
		"apex_only":
			for hname in HANDLE_ORDER:
				if str(hname) != "apex":
					_restore_home(str(hname))
		"base_only":
			_restore_home("apex")
		"symmetric":
			var driver: String = ""
			for hname in moved:
				if str(hname) != "apex":
					driver = str(hname)
					break
			if driver != "":
				_mirror_base(driver)
			if handle_nodes.has("apex"):
				var apex: Node3D = handle_nodes["apex"]
				apex.position = Vector3(0.0, apex.position.y, 0.0)

## The moved corner sets the half-extents; the other three take the same
## magnitudes with their own signs, so the base stays a centred rectangle.
func _mirror_base(driver: String) -> void:
	if not handle_nodes.has(driver):
		return
	var lead: Vector3 = handle_nodes[driver].position
	var half_x: float = abs(lead.x)
	var half_z: float = abs(lead.z)
	for hname in HANDLE_ORDER:
		var key: String = str(hname)
		if key == "apex" or not handle_nodes.has(key):
			continue
		var home: Vector3 = _home_positions.get(key, Vector3.ZERO)
		var sign_x: float = -1.0 if home.x < 0.0 else 1.0
		var sign_z: float = -1.0 if home.z < 0.0 else 1.0
		handle_nodes[key].position = Vector3(sign_x * half_x, lead.y, sign_z * half_z)

func _restore_home(hname: String) -> void:
	if handle_nodes.has(hname) and _home_positions.has(hname):
		handle_nodes[hname].position = _home_positions[hname]

## Grid config hook. Only re-applies when the value actually changed AND the
## handles already exist (i.e. _ready has built once) — an unguarded rebuild here
## breaks shipped placements.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("constraint"):
		return
	var wanted: String = str(config_data["constraint"])
	if wanted == constraint:
		return
	constraint = wanted
	if handle_nodes.is_empty() or not is_inside_tree():
		return
	if constraint != "free":
		_apply_constraint(HANDLE_ORDER.duplicate())
	_rebuild_pyramid()

func _sync_handle_positions() -> void:
	for name in handle_nodes.keys():
		last_handle_positions[name] = handle_nodes[name].position
