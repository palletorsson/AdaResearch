@tool
extends XRToolsPickable

# @identity
# essence: trihedron — 4 vertices, 3 triangular faces and 1 quad base: the wedge as 3D primitive
# desire: learner holds a 3D solid, turns it in their hands, and counts faces, edges, vertices
# critical_parameter: button material toggle — pressing reveals the internal structure through a different material
# triggers: pick up → snaps to shelf; button press → alternates material showing surface vs wireframe quality
# emerges: the Euler relation (V-E+F=2) as something you count by holding; topology felt through handling
# needs: [has VR button (material toggle) [has], has shelf snap [has], missing edge/vertex count label]
# relationships: sibling to grab_octahedron; both teach held polyhedra with button interaction
# truth: a solid is defined by its topology — how faces connect — not by any particular material or color

## Alternate material when button pressed
@export var alternate_material : Material
@export var snap_to_shelf: bool = true
@export var snap_max_distance: float = 0.08
@export var snap_match_rotation: bool = false
@export var snap_falloff_distance: float = 1.0

## Trihedron properties
@export var base_color: Color = Color(0.2, 0.8, 1.0)
@export var trihedron_size: float = 0.6:
	set(value):
		trihedron_size = value
		if Engine.is_editor_hint():
			_rebuild_trihedron()

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# figure: WHICH trihedral solid this is. Three faces meeting at one point is a
#   definition, not a shape — and the artifact had frozen it into a single
#   vertex literal, so every placement in the project showed the same slightly
#   oblique wedge and nothing in the object said that was a choice. "wedge" is
#   that literal, kept byte for byte. "corner" is the trihedron the word means
#   in geometry: three MUTUALLY PERPENDICULAR edges from the apex, the corner
#   of a cube. "regular" is the Platonic tetrahedron, every face congruent, the
#   only one of the four with no privileged face. "inverted" turns the apex
#   downward: the same three planes, met from the concave side — a notch rather
#   than a spike. All four are normalised into the same bounding box, so the
#   axis changes silhouette and never size.
# facets: whether the polyhedron admits to its faces. Reused verbatim from
#   sphere_low/sphere_high (shown | hidden | only) because it is the same
#   question about the same shader — this artifact's own truth line says a solid
#   is its topology and not its material, and its own critical_parameter is a
#   material toggle that is dead in the shipped scene (alternate_material = null
#   in grab_trihedron.tscn, so the VR button swaps nothing). "hidden" stages the
#   smooth-surface reading the truth line argues against; "only" drops the fill
#   and leaves the edge count you are asked to make.
const FIGURES := ["wedge", "corner", "regular", "inverted"]
const FACET_MODES := ["shown", "hidden", "only"]

@export_enum("wedge", "corner", "regular", "inverted") var figure: String = "wedge"
@export_enum("shown", "hidden", "only") var facets: String = "shown"

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

# True once _ready has built the mesh at least once. apply_grid_config must not
# rebuild before that — and must not rebuild at all when nothing changed, or the
# 7 shipped placements would be re-meshed for no reason.
var _built: bool = false

# Original material
var _original_material : Material

# Current controller holding this object
var _current_controller : XRController3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Call the super
	super()

	if not Engine.is_editor_hint():
		set_process(true)

	# Build the trihedron mesh
	_rebuild_trihedron()

	# Get the original material
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		_original_material = mesh_instance.get_active_material(0)

	# Listen for when this object is picked up or dropped
	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	_built = true

func _rebuild_trihedron() -> void:
	var geometry := _trihedron_geometry()
	var material = _build_material()
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
			"name": "Trihedron",
			"material": material
		}
	)
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	# Keep the drop-handler's restore target in step with the current facets
	# value. _ready read this back off the mesh a moment after the first build,
	# which is the same object; assigning it here just keeps it true after a
	# later apply_grid_config.
	_original_material = material

	# Update collision shape
	var collision_shape = get_node_or_null("CollisionShape3D")
	if collision_shape:
		var convex_shape = ConvexPolygonShape3D.new()
		convex_shape.points = geometry["vertices"]
		collision_shape.shape = convex_shape

func _trihedron_geometry() -> Dictionary:
	var vertices := _create_trihedron_vertices()
	var faces := _create_trihedron_faces()
	return {
		"vertices": vertices,
		"faces": faces
	}

func _build_material() -> Material:
	if facets == "hidden":
		# The same three faces, shaded as though they were a surface: no edges,
		# so the count the artifact asks for cannot be made by looking.
		var plain := StandardMaterial3D.new()
		plain.albedo_color = base_color
		plain.emission_enabled = true
		plain.emission = base_color * 0.3
		return plain
	if facets == "only":
		return GridMaterialFactory.make(base_color, {"show_only_wireframe": true})
	# "shown" — the shipped SimpleGrid material, unchanged.
	return GridMaterialFactory.make(base_color, {})

func _create_trihedron_vertices() -> Array[Vector3]:
	var s := trihedron_size

	match figure:
		"corner":
			return _fit_to_box(_corner_vertices(), s)
		"regular":
			return _fit_to_box(_regular_vertices(), s)
		"inverted":
			return _fit_to_box(_inverted_vertices(), s)

	# "wedge" — the shipped literals, untouched. This branch is the whole of the
	# pre-promotion function, so every existing placement builds the same mesh
	# and the same convex hull it always did.
	var vertices: Array[Vector3] = []

	# Trihedron: 4 vertices forming a wedge/corner
	# Apex vertex (corner point)
	vertices.append(Vector3(0, s, 0))  # Apex (0)

	# Base triangle vertices
	vertices.append(Vector3(-s, -s, -s))  # Base vertex 1 (1)
	vertices.append(Vector3(s, -s, -s))   # Base vertex 2 (2)
	vertices.append(Vector3(0, -s, s))    # Base vertex 3 (3)

	return vertices

func _corner_vertices() -> Array[Vector3]:
	# The trihedron of the coordinate frame: three edges leaving the apex at
	# right angles to each other. Three unit directions arranged as a tripod
	# about -Y are mutually perpendicular exactly when their pairwise dot is
	# (2/3)cos(120 deg) + 1/3 = 0, which is the arrangement below.
	var vertices: Array[Vector3] = []
	var apex := Vector3(0, 1, 0)
	vertices.append(apex)

	var radial: float = sqrt(2.0 / 3.0)
	var drop: float = 1.0 / sqrt(3.0)
	for i in 3:
		var angle: float = TAU * float(i) / 3.0
		vertices.append(apex + Vector3(radial * cos(angle), -drop, radial * sin(angle)))
	return vertices

func _regular_vertices() -> Array[Vector3]:
	# The Platonic tetrahedron: equilateral base, apex over its centroid, all
	# four faces congruent. Circumradius 1 puts the base plane at y = -1/3.
	var vertices: Array[Vector3] = []
	vertices.append(Vector3(0, 1, 0))

	var radius: float = sqrt(8.0) / 3.0
	for i in 3:
		var angle: float = TAU * float(i) / 3.0 + PI * 0.5
		vertices.append(Vector3(radius * cos(angle), -1.0 / 3.0, radius * sin(angle)))
	return vertices

func _inverted_vertices() -> Array[Vector3]:
	# The same three planes met from the concave side: apex below, the triangle
	# above it. A notch you could set something into rather than a point you
	# hold. Winding is preserved by mirroring in Y, which also swaps two base
	# vertices so the faces still face outward.
	var vertices: Array[Vector3] = []
	vertices.append(Vector3(0, -1, 0))
	vertices.append(Vector3(-1, 1, -1))
	vertices.append(Vector3(0, 1, 1))
	vertices.append(Vector3(1, 1, -1))
	return vertices

func _fit_to_box(points: Array[Vector3], s: float) -> Array[Vector3]:
	# Centre the point set on its own bounding box and scale it so the largest
	# half-extent is exactly trihedron_size. Every non-default figure therefore
	# occupies the same box the shipped wedge does — the axis argues about the
	# solid, never about how much room it takes.
	if points.is_empty():
		return points

	var lo: Vector3 = points[0]
	var hi: Vector3 = points[0]
	for p in points:
		lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
		hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))

	var centre: Vector3 = (lo + hi) * 0.5
	var half: Vector3 = (hi - lo) * 0.5
	var widest: float = maxf(half.x, maxf(half.y, half.z))
	if widest <= 0.0:
		return points

	var factor: float = s / widest
	var out: Array[Vector3] = []
	for p in points:
		out.append((p - centre) * factor)
	return out

func _create_trihedron_faces() -> Array:
	# Trihedron has exactly 3 triangular faces, all sharing the apex vertex
	# Each face is formed by the apex and two adjacent base vertices
	return [
		# Face 1: Apex + base vertices 1 and 2
		[0, 1, 2],
		# Face 2: Apex + base vertices 2 and 3
		[0, 2, 3],
		# Face 3: Apex + base vertices 3 and 1
		[0, 3, 1]
	]

func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded on both sides: a value has to actually differ, and _ready has to
	# have built once already. A placement token that names neither figure nor
	# facets never reaches _rebuild_trihedron, so the 7 shipped placements are
	# untouched by this function existing.
	var changed: bool = false

	if config_data.has("figure"):
		var want_figure: String = str(config_data["figure"]).strip_edges().to_lower()
		if FIGURES.has(want_figure) and want_figure != figure:
			figure = want_figure
			changed = true

	if config_data.has("facets"):
		var want_facets: String = str(config_data["facets"]).strip_edges().to_lower()
		if FACET_MODES.has(want_facets) and want_facets != facets:
			facets = want_facets
			changed = true

	if changed and _built:
		_rebuild_trihedron()

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
