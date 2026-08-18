# VRCubeDeformer.gd - Deformable cube with grab spheres at corners
extends Node3D

@export var base_color: Color = Color(1.0, 0.4, 0.7)  # Pink cube color
@export var hover_color: Color = Color(0.4, 0.8, 1.0)

## DNA (stage 2 - variation, promoted 2026-07-29)
##   handles       - which vertices get a vote. The blurb calls this cube "a
##                   treaty among vertices"; a treaty is defined by who signs it,
##                   and that was hard-coded to all eight.
##   triangulation - which diagonal splits each quad face. The blurb claims "the
##                   faces re-triangulate around your decision" - they did not:
##                   every face carried a fixed seam baked in at author time.
## Both defaults reproduce the pre-promotion artifact exactly.

const HANDLE_MODES: Array[String] = ["corners", "top", "diagonal"]
const TRIANGULATIONS: Array[String] = ["fixed", "shortest"]

## Which corners are draggable.
##   corners  - all eight; every vertex signs (shipped)
##   top      - the four upper corners; the solid can only be warped from above
##   diagonal - two opposite corners; the minimal treaty, two vertices decide
@export_enum("corners", "top", "diagonal") var handles: String = "corners"

## How each square face is cut into two triangles.
##   fixed    - the author's diagonal, always a-c; the seam is remembered, and a
##              dragged corner creases along a line chosen before you arrived
##              (shipped)
##   shortest - the shorter diagonal wins, re-picked every rebuild; the seam
##              follows your deformation instead of preceding it
## At rest the cube is square and both diagonals are equal, so the two modes are
## identical until a corner is dragged.
@export_enum("fixed", "shortest") var triangulation: String = "fixed"

# Each face as a quad in winding order. Splitting [a,b,c,d] on the a-c diagonal
# reproduces the historical hard-coded triangle list exactly.
const FACE_QUADS: Array = [
	[0, 1, 2, 3],   # front
	[5, 4, 7, 6],   # back
	[4, 0, 3, 7],   # left
	[1, 5, 6, 2],   # right
	[3, 2, 6, 7],   # top
	[4, 5, 1, 0]    # bottom
]

var is_hovered: bool = false
var mesh_instance: MeshInstance3D
var grab_spheres: Array[Node3D] = []
var original_vertices: Array[Vector3] = []
var current_vertices: Array[Vector3] = []
var is_ready_complete: bool = false

# Cube corner indices for grab spheres
var corner_indices = [0, 1, 2, 3, 4, 5, 6, 7]

func _ready():
	call_deferred("setup_complete_cube")

func setup_complete_cube():
	create_vr_cube()
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	create_grab_spheres()
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	is_ready_complete = true
	print("Cube setup complete - should see cube and spheres now")

func create_vr_cube():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Regular cube dimensions
	var size = 0.5  # Half size for each dimension
	
	# Store original vertices
	original_vertices = [
		Vector3(-size, -size, size),    # 0 - bottom left front
		Vector3(size, -size, size),     # 1 - bottom right front
		Vector3(size, size, size),      # 2 - top right front
		Vector3(-size, size, size),     # 3 - top left front
		Vector3(-size, -size, -size),   # 4 - bottom left back
		Vector3(size, -size, -size),    # 5 - bottom right back
		Vector3(size, size, -size),     # 6 - top right back
		Vector3(-size, size, -size)     # 7 - top left back
	]
	
	# Copy to current vertices for deformation
	current_vertices = original_vertices.duplicate()
	
	# Cube faces (each face made of 2 triangles)
	var faces: Array = _current_faces(current_vertices)

	# Add faces with normals and UVs
	for face in faces:
		add_triangle_with_normal_and_uv(st, current_vertices, face)
	
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.name = "VRCube"
	apply_cube_material(mesh_instance, base_color)
	add_child(mesh_instance)
	
	# Add hover detection area
	var hover_area = Area3D.new()
	var hover_collision = CollisionShape3D.new()
	var hover_box = BoxShape3D.new()
	hover_box.size = Vector3(size * 2.2, size * 2.2, size * 2.2)  # Slightly larger for easier hovering
	hover_collision.shape = hover_box
	hover_area.add_child(hover_collision)
	hover_area.name = "HoverArea"
	add_child(hover_area)
	
	# Connect hover signals
	hover_area.mouse_entered.connect(_on_hover_start)
	hover_area.mouse_exited.connect(_on_hover_end)
	
	print("Created cube mesh")

func create_grab_spheres():
	print("Creating grab spheres...")
	
	# Load the grab sphere point scene
	var grab_sphere_scene = preload("res://commons/primitives/point/grab_sphere_point.tscn")
	
	for i in range(8):
		var sphere_node = grab_sphere_scene.instantiate()
		sphere_node.name = "GrabSphere_" + str(i)
		
		# Position at corner
		sphere_node.position = current_vertices[i]
		sphere_node.freeze = true		
		# Add to this node (cube) as child
		add_child(sphere_node)
		grab_spheres.append(sphere_node)

		# Connect signals for dragging if they exist
		if sphere_node.has_signal("picked_up"):
			sphere_node.picked_up.connect(_on_sphere_picked_up.bind(i))
		if sphere_node.has_signal("dropped"):
			sphere_node.dropped.connect(_on_sphere_dropped.bind(i))
		
		print("Created sphere ", i, " at position ", current_vertices[i])

	# All eight spheres always exist so grab_spheres stays index-aligned with
	# current_vertices; the handles axis only decides which ones are live.
	_apply_handle_visibility()

func _on_sphere_picked_up(vertex_index: int, _pickable = null):
	print("Sphere ", vertex_index, " picked up")

func _on_sphere_dropped(vertex_index: int, _pickable = null):
	if vertex_index < grab_spheres.size():
		var sphere = grab_spheres[vertex_index]
		var drop_position = sphere.position
		
		# Update the vertex position based on the sphere's new position
		current_vertices[vertex_index] = drop_position
		update_cube_mesh()
		print("Sphere ", vertex_index, " dropped at: ", drop_position)

func _process(_delta):
	if not is_ready_complete:
		return
	
	# Continuously track sphere positions for real-time deformation
	var needs_update = false
	for i in range(grab_spheres.size()):
		if i < current_vertices.size():
			var sphere = grab_spheres[i]
			var sphere_pos = sphere.position
			
			# Check if sphere moved significantly
			if current_vertices[i].distance_to(sphere_pos) > 0.001:
				current_vertices[i] = sphere_pos
				needs_update = true
	
	if needs_update:
		update_cube_mesh()

func update_cube_mesh():
	if not mesh_instance:
		return
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Cube faces using updated vertices
	var faces: Array = _current_faces(current_vertices)

	# Add faces with updated vertices
	for face in faces:
		add_triangle_with_normal_and_uv(st, current_vertices, face)
	
	mesh_instance.mesh = st.commit()

func add_triangle_with_normal_and_uv(st: SurfaceTool, vertices: Array, face: Array):
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]  
	var v2 = vertices[face[2]]
	
	# Calculate face normal
	var edge1 = v1 - v0
	var edge2 = v2 - v0
	var normal = edge1.cross(edge2).normalized()
	
	# Simple UV mapping
	var uv0 = Vector2(0, 0)
	var uv1 = Vector2(1, 0)
	var uv2 = Vector2(1, 1)
	
	# Add vertices with normals and UVs
	st.set_normal(normal)
	st.set_uv(uv0)
	st.add_vertex(v0)
	
	st.set_normal(normal)
	st.set_uv(uv1)
	st.add_vertex(v1)
	
	st.set_normal(normal)
	st.set_uv(uv2)
	st.add_vertex(v2)

func apply_cube_material(mesh_instance: MeshInstance3D, color: Color):
	# Use standard material for visibility
	var standard_material = StandardMaterial3D.new()
	standard_material.albedo_color = color
	standard_material.emission_enabled = true
	standard_material.emission = color * 0.3
	mesh_instance.material_override = standard_material

func _on_hover_start():
	is_hovered = true
	animate_hover(true)

func _on_hover_end():
	is_hovered = false
	animate_hover(false)

func animate_hover(hover: bool):
	if not mesh_instance:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if hover:
		# Hover effects
		tween.tween_property(self, "scale", Vector3(1.1, 1.1, 1.1), 0.2)
		apply_cube_material(mesh_instance, hover_color)
	else:
		# Return to normal
		tween.tween_property(self, "scale", Vector3.ONE, 0.2)
		apply_cube_material(mesh_instance, base_color)

func reset_cube():
	# Reset cube to original shape
	current_vertices = original_vertices.duplicate()
	
	# Reset grab sphere positions
	for i in range(grab_spheres.size()):
		if i < corner_indices.size():
			grab_spheres[i].position = current_vertices[corner_indices[i]]
	
	update_cube_mesh()

func set_base_color(color: Color):
	base_color = color
	if mesh_instance and not is_hovered:
		apply_cube_material(mesh_instance, base_color)

# VR interaction methods
func activate():
	# Called when VR controller selects this cube
	print("Cube activated")
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector3(0.9, 0.9, 0.9), 0.1)
	tween.tween_property(self, "scale", Vector3.ONE, 0.1)
	
	# Emit custom signal
	cube_activated.emit()

signal cube_activated()

# Helper function to position cube in VR space
func set_vr_position(pos: Vector3):
	position = pos

# -- DNA plumbing ------------------------------------------------------------

## The corner indices that carry a live grab sphere under the current handles
## mode. "corners" returns all eight, which is what shipped.
func _handle_indices() -> Array:
	if handles == "top":
		return [2, 3, 6, 7]
	if handles == "diagonal":
		return [0, 6]
	return [0, 1, 2, 3, 4, 5, 6, 7]

## Hide and un-collide the corners that do not sign this treaty. With
## handles == "corners" every sphere is shown and enabled, i.e. untouched.
func _apply_handle_visibility() -> void:
	var active: Array = _handle_indices()
	for i in range(grab_spheres.size()):
		var sphere: Node3D = grab_spheres[i]
		if not is_instance_valid(sphere):
			continue
		var live: bool = active.has(i)
		sphere.visible = live
		var collider: CollisionShape3D = sphere.get_node_or_null("CollisionShape3D")
		if collider:
			collider.disabled = not live
		if not live and i < current_vertices.size():
			# A dormant corner stops voting: park it back on its own vertex so
			# _process() never reads a stale offset from it.
			sphere.position = current_vertices[i]

## Split every quad face into two triangles. Under "fixed" the diagonal is
## always a-c, which reproduces the historical triangle list exactly.
func _current_faces(verts: Array) -> Array:
	var out: Array = []
	for quad in FACE_QUADS:
		var a: int = quad[0]
		var b: int = quad[1]
		var c: int = quad[2]
		var d: int = quad[3]
		var split_bd: bool = false
		if triangulation == "shortest" and verts.size() > d:
			var len_ac: float = verts[a].distance_to(verts[c])
			var len_bd: float = verts[b].distance_to(verts[d])
			split_bd = len_bd < len_ac
		if split_bd:
			out.append([b, c, d])
			out.append([b, d, a])
		else:
			out.append([a, b, c])
			out.append([a, c, d])
	return out

## Grid config arrives deferred and may land either side of the deferred
## setup_complete_cube(). Nothing is torn down here: a value is only written
## when it differs, and the scene is only touched once the build has run - so a
## placement passing no config (or a config naming neither axis) is untouched.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	var handles_changed: bool = false
	var mesh_changed: bool = false
	if config_data.has("handles"):
		var new_handles: String = str(config_data["handles"]).strip_edges().to_lower()
		if HANDLE_MODES.has(new_handles) and new_handles != handles:
			handles = new_handles
			handles_changed = true
	if config_data.has("triangulation"):
		var new_tri: String = str(config_data["triangulation"]).strip_edges().to_lower()
		if TRIANGULATIONS.has(new_tri) and new_tri != triangulation:
			triangulation = new_tri
			mesh_changed = true
	if not is_ready_complete:
		# The deferred build has not happened yet; it will read the new values.
		return
	if handles_changed:
		_apply_handle_visibility()
	if mesh_changed:
		update_cube_mesh()

# Test function to manually move a corner and see deformation
func test_deform_corner(corner_index: int, new_pos: Vector3):
	if corner_index < current_vertices.size():
		current_vertices[corner_index] = new_pos
		if corner_index < grab_spheres.size():
			grab_spheres[corner_index].position = new_pos
		update_cube_mesh()
		print("Deformed corner ", corner_index, " to ", new_pos)
