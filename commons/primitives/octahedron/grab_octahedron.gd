@tool
extends XRToolsPickable

# @identity
# essence: octahedron — 6 vertices, 12 edges, 8 triangular faces: dual of the cube, Platonic solid
# desire: learner holds the octahedron and discovers its symmetry through physical rotation
# critical_parameter: button material toggle — reveals the 8-face structure through a contrasting material
# triggers: pick up → snaps to shelf; button press → alternates material to show surface texture change
# emerges: the dual relationship to the cube — 6 face-centers of a cube are the 6 vertices of an octahedron
# needs: the cube this solid is the dual OF, visible rather than asserted [has, 2026-08-03 — the `dual` axis, the word taken from snap_octahedron_puzzle]. Has VR button (material toggle), has shelf snap. Missing: Euler formula label
# relationships: sibling to grab_trihedron; shares the `dual` axis with snap_octahedron_puzzle; also used as the origin spinning decoration
# truth: the octahedron has more symmetry than it first appears — it looks the same from 48 orientations

## Alternate material when button pressed
@export var alternate_material : Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

## Octahedron properties
@export var base_color: Color = Color(1.0, 1.0, 0.0)
@export var octahedron_scale: float = 0.5:
	set(value):
		octahedron_scale = value
		if Engine.is_editor_hint():
			_rebuild_octahedron()

# --- DNA (stage 2, promoted 2026-08-03) — axis `dual` ---
#
# THE FAMILY OWNS THIS WORD ALREADY. snap_octahedron_puzzle promoted `dual` on
# 2026-07-29 with exactly these four values, on exactly this question: which side of the
# octahedron-cube duality is actually drawn. Same sequence, same solid, same claim at a
# different level of assembly — a puzzle you complete there, a solid you hold here. So
# the word, the four values, the cyan and the strut proportions are taken over
# character for character rather than reinvented, and the two should measure alike.
#
# It is the same complaint in both files, and it is this file's own truth statement:
# "the octahedron has more symmetry than it first appears" and "the dual relationship to
# the cube — 6 face-centers of a cube are the 6 vertices of an octahedron". Shipped,
# that cube is asserted by @identity and by technical.md and drawn nowhere. What the
# hand holds is a yellow solid; the reciprocal it is supposedly about is a caption.
#
# WHAT THE HARD-CODED CONSTANTS WERE HIDING. _octahedron_geometry() puts the six
# vertices at +-octahedron_scale on each axis and the eight faces are the eight sign
# octants. Both cubes fall straight out of those numbers with nothing new invented:
# the circumscribing cube has half-side R (its six face centres ARE the vertices), and
# the inscribed cube has half-side R/3 (an octahedron face centre is (R,0,0), (0,R,0),
# (0,0,R) averaged). The duality was already fully written down in the vertex table.
#
# WHERE THIS ARTIFACT MUST DIVERGE FROM ITS SIBLING, and why the axis note says so:
# snap_octahedron_puzzle's octahedron is a cage of struts, so `inside` is simply visible
# through it. This one is an OPAQUE solid, and an inscribed cube of half-side R/3 has
# its eight corners exactly ON the eight faces — it would be sealed inside and every
# frame would come out identical, the documented occlusion trap. So on `inside` and
# `both` the solid faces are withdrawn and the octahedron is drawn as its twelve edges.
# That is not a second axis smuggled in: it is the same claim, that duality is a figure
# and ground you can swap, and which of the pair is solid is exactly what is being said.

## Which side of the octahedron-cube duality is actually drawn.
## off = the shipped solid, nothing added. around = the circumscribing cube whose six
## face centres are the six vertices. inside = the inscribed cube whose eight corners
## are the eight face centres, with the solid opened to its edges so it can be seen.
## both = both cubes, showing duality nests.
@export_enum("off", "around", "inside", "both") var dual: String = "off"

const DUALS: PackedStringArray = ["off", "around", "inside", "both"]

## Strut gauges as a FRACTION of the circumradius, not in metres. snap_octahedron_puzzle
## draws 0.008 m and 0.005 m struts around a 0.20 m circumradius; this octahedron is
## 2.5x larger, so copying those numbers in metres would draw a visibly thinner cage and
## the two siblings would stop measuring alike despite sharing a vocabulary.
const DUAL_GAUGE: float = 0.04
const INNER_GAUGE: float = 0.025

## The octahedron's own edges, drawn heavier than either cube so the figure still reads
## as the subject when it opens rather than as more scaffolding.
const CAGE_GAUGE: float = 0.05

## The dual cube's cyan — the colour snap_octahedron_puzzle gives its cubes, so the
## reciprocal reads as the same thing in both artifacts.
const DUAL_CYAN: Color = Color(0.3, 0.8, 1.0, 1.0)

## Corner signs as a table rather than nested sign loops — an untyped loop variable
## multiplied into a Vector3 is the compile trap this codebase keeps hitting.
const CUBE_SIGNS: Array = [
	Vector3(-1.0, -1.0, -1.0), Vector3(-1.0, -1.0, 1.0),
	Vector3(-1.0, 1.0, -1.0), Vector3(-1.0, 1.0, 1.0),
	Vector3(1.0, -1.0, -1.0), Vector3(1.0, -1.0, 1.0),
	Vector3(1.0, 1.0, -1.0), Vector3(1.0, 1.0, 1.0),
]

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

# Original material
var _original_material : Material

# Current controller holding this object
var _current_controller : XRController3D

# Everything _build_dual() made, so it can unmake exactly that and nothing else.
var _dna_nodes: Array[Node3D] = []

# The render layer the mesh SHIPPED on, captured once. Restoring a hard-coded 1 would
# quietly re-layer any placement that had been put on another layer.
var _shipped_layers: int = -1

# apply_grid_config arrives call_deferred, i.e. after _ready. Nothing may rebuild before
# _ready has built once.
var _built: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	if not Engine.is_editor_hint():
		set_process(true)

	# The grid sets config_<key> metadata as well as calling apply_grid_config, and the
	# call is deferred. Reading the meta here means a `#dual:around` placement builds
	# right the first time instead of building the shipped solid and rebuilding a frame
	# later. An unrecognised string falls back to "off", never to nothing.
	if has_meta("config_dual"):
		dual = _pick_axis(str(get_meta("config_dual")), "off")
	dual = _pick_axis(dual, "off")

	# Build the octahedron mesh
	_rebuild_octahedron()

	# Get the original material
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	_built = true

func _rebuild_octahedron() -> void:
	var geometry := _octahedron_geometry()
	var material = GridMaterialFactory.make(base_color)
	var mesh_instance = get_node_or_null("MeshInstance3D")
	
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "MeshInstance3D"
		add_child(mesh_instance)
		move_child(mesh_instance, 1)  # Move after CollisionShape3D
	
	var mesh = PrimitiveMeshBuilder.build_mesh(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Octahedron",
			"material": material
		}
	)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	
	# Update collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape:
		var convex_shape = ConvexPolygonShape3D.new()
		convex_shape.points = geometry["vertices"]
		collision_shape.shape = convex_shape

	_build_dual()


# ═══════════════════════════════════════════════════════════════════
# DUAL — the cube this solid has always been about
# ═══════════════════════════════════════════════════════════════════

## Builds nothing and touches nothing on "off", so a default placement takes exactly the
## code path it took before this axis existed. The collision shape is never changed by
## this: the octahedron stays grabbable at its shipped size in every value.
func _build_dual() -> void:
	for i in range(_dna_nodes.size()):
		var node: Node3D = _dna_nodes[i]
		if is_instance_valid(node):
			if node.get_parent() == self:
				remove_child(node)
			node.queue_free()
	_dna_nodes.clear()

	var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh_instance != null and _shipped_layers < 0:
		_shipped_layers = mesh_instance.layers

	# The solid faces are withdrawn only when something has to be seen through them, and
	# with layers = 0 rather than visible = false: the mesh stays in the capture AABB so
	# the framing does not jump between values, and its material is left untouched so the
	# controller button's material swap still has a surface to swap.
	var opened: bool = dual == "inside" or dual == "both"
	if mesh_instance != null:
		if opened:
			mesh_instance.layers = 0
		else:
			mesh_instance.layers = _shipped_layers

	if dual == "off":
		return

	var r: float = octahedron_scale
	if dual == "around" or dual == "both":
		_add_cube(r, r * DUAL_GAUGE * 0.5, _make_dna_material(DUAL_CYAN))
	if opened:
		_add_octahedron_cage(r, r * CAGE_GAUGE * 0.5, _make_dna_material(base_color))
		_add_cube(r / 3.0, r * INNER_GAUGE * 0.5, _make_dna_material(DUAL_CYAN))


func _add_cube(half: float, radius: float, mat: StandardMaterial3D) -> void:
	var edges: Array = _cube_edges(half)
	for i in range(edges.size()):
		var edge: Array = edges[i]
		var a: Vector3 = edge[0]
		var b: Vector3 = edge[1]
		_add_strut(a, b, radius, mat)


## The twelve edges as corner pairs: two corners are joined exactly when they differ on
## one axis, which is when their distance is the full side length. Derived from the same
## sign table the corners come from, so edges cannot drift from vertices.
func _cube_edges(half: float) -> Array:
	var corners: Array = []
	for i in range(CUBE_SIGNS.size()):
		var sign_vec: Vector3 = CUBE_SIGNS[i]
		corners.append(sign_vec * half)
	var side: float = half * 2.0
	var edges: Array = []
	for i in range(corners.size()):
		for j in range(i + 1, corners.size()):
			var a: Vector3 = corners[i]
			var b: Vector3 = corners[j]
			if absf(a.distance_to(b) - side) < 0.0001:
				edges.append([a, b])
	return edges


## The octahedron's own twelve edges. Two of its six vertices share an edge exactly when
## they are NOT antipodal — fifteen pairs minus three opposite pairs — so this is read
## off the same +-R table _octahedron_geometry() uses and cannot drift from the solid.
func _add_octahedron_cage(r: float, radius: float, mat: StandardMaterial3D) -> void:
	var verts: Array = [
		Vector3(0.0, r, 0.0), Vector3(0.0, -r, 0.0),
		Vector3(r, 0.0, 0.0), Vector3(-r, 0.0, 0.0),
		Vector3(0.0, 0.0, r), Vector3(0.0, 0.0, -r),
	]
	for i in range(verts.size()):
		for j in range(i + 1, verts.size()):
			var a: Vector3 = verts[i]
			var b: Vector3 = verts[j]
			if not a.is_equal_approx(-b):
				_add_strut(a, b, radius, mat)


func _add_strut(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var length: float = a.distance_to(b)
	if length < 0.0005:
		return
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 8
	cyl.rings = 1

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "DnaStrut"
	mi.mesh = cyl
	mi.material_override = mat
	mi.transform = _strut_xform(a, b)
	add_child(mi)
	_dna_nodes.append(mi)


func _strut_xform(a: Vector3, b: Vector3) -> Transform3D:
	var mid: Vector3 = (a + b) * 0.5
	var y_axis: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(y_axis.dot(ref)) > 0.9:
		ref = Vector3.FORWARD
	var x_axis: Vector3 = ref.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	return Transform3D(Basis(x_axis, y_axis, z_axis), mid)


func _make_dna_material(color: Color) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color.r, color.g, color.b, 0.75)
	m.metallic = 0.2
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.2
	return m


func _pick_axis(raw: String, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if DUALS.has(v) else fallback


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Reached from a map token as `grab_octahedron:0:0:0.4#dual:around`. The grid calls this
## deferred, so it may arrive before or long after _ready — hence both guards.
func apply_grid_config(config_data: Dictionary) -> void:
	var before: String = dual
	if config_data.has("dual"):
		dual = _pick_axis(str(config_data["dual"]), dual)
	if not _built:
		return
	# Rebuild ONLY on a real change. Every placement in every map gets this call; an
	# unguarded rebuild would make all eleven of them pay for the axis existing.
	if dual == before:
		return
	_build_dual()


func _octahedron_geometry() -> Dictionary:
	var scale := octahedron_scale
	var vertices: Array[Vector3] = [
		Vector3(0, 0.5, 0) * scale * 2.0,
		Vector3(0, -0.5, 0) * scale * 2.0,
		Vector3(0.5, 0, 0) * scale * 2.0,
		Vector3(-0.5, 0, 0) * scale * 2.0,
		Vector3(0, 0, 0.5) * scale * 2.0,
		Vector3(0, 0, -0.5) * scale * 2.0
	]
	var faces: Array = [
		[0, 4, 2],
		[0, 2, 5],
		[0, 5, 3],
		[0, 3, 4],
		[1, 2, 4],
		[1, 5, 2],
		[1, 3, 5],
		[1, 4, 3]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not snap_to_shelf:
		return
	if _current_controller:
		return
	_snap_to_nearest_shelf_point(true)

# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	# Listen for button events on the associated controller
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.button_pressed.connect(_on_controller_button_pressed)
		_current_controller.button_released.connect(_on_controller_button_released)

# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# Unsubscribe to controller button events when dropped
	if _current_controller:
		_current_controller.button_pressed.disconnect(_on_controller_button_pressed)
		_current_controller.button_released.disconnect(_on_controller_button_released)
		_current_controller = null

	# Restore original material when dropped
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		mesh_instance.set_surface_override_material(0, _original_material)
	_snap_to_nearest_shelf_point()

# Called when a controller button is pressed
func _on_controller_button_pressed(button : String):
	# Handle controller button presses
	if button == "ax_button":
		# Set alternate material when button pressed
		if alternate_material:
			var mesh_instance = get_node_or_null("MeshInstance3D")
			if mesh_instance:
				mesh_instance.set_surface_override_material(0, alternate_material)

# Called when a controller button is released
func _on_controller_button_released(button : String):
	# Handle controller button releases
	if button == "ax_button":
		# Restore original material when button released
		var mesh_instance = get_node_or_null("MeshInstance3D")
		if mesh_instance:
			mesh_instance.set_surface_override_material(0, _original_material)

func _snap_to_nearest_shelf_point(force: bool = false) -> void:
	if not snap_to_shelf:
		return

	var effective_max = snap_max_distance
	if force:
		effective_max = snap_falloff_distance if snap_falloff_distance > 0.0 else snap_max_distance
	elif snap_max_distance <= 0.0:
		return

	var snap_points = get_tree().get_nodes_in_group("shelf_snap_point")
	if snap_points.is_empty():
		return

	var best_point: Node3D = null
	var best_distance = effective_max if effective_max > 0.0 else INF

	for point in snap_points:
		if point is Node3D:
			var snap_node := point as Node3D
			if not is_instance_valid(snap_node):
				continue
			var distance = snap_node.global_position.distance_to(global_position)
			if distance <= best_distance:
				best_distance = distance
				best_point = snap_node

	if best_point == null:
		return

	if snap_falloff_distance > 0.0 and best_distance > snap_falloff_distance:
		return

	var target = best_point.global_position
	var current_scale = global_transform.basis.get_scale()
	var basis := Basis.IDENTITY
	if snap_match_rotation:
		basis = best_point.global_transform.basis
	basis = basis.scaled(current_scale)
	global_transform = Transform3D(basis, target)
