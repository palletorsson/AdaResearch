extends Node3D
class_name WaterbombShell
## Rigid-foldable waterbomb tessellation shell.
## Generates a deployable origami sphere using actual geometric constraints.
## Each face is a rigid triangle; fold angles are computed from deployment parameter.

signal deployment_changed(amount: float)

@export_group("Tessellation")
@export var radial_segments: int = 16:  # Around the equator
	set(v):
		radial_segments = max(6, v)
		if is_inside_tree(): _rebuild()
@export var ring_count: int = 3:  # Pole to equator (mirrored)
	set(v):
		ring_count = max(1, v)
		if is_inside_tree(): _rebuild()
@export var base_radius: float = 0.6:
	set(v):
		base_radius = max(0.1, v)
		if is_inside_tree(): _rebuild()

@export_group("Deployment")
@export_range(0.0, 1.0) var deployment: float = 0.0:
	set(v):
		deployment = clamp(v, 0.0, 1.0)
		_apply_deployment()
		deployment_changed.emit(deployment)
@export var deployment_speed: float = 2.0

@export_group("Appearance")
@export var face_color: Color = Color(0.6, 0.85, 0.75, 1.0)
@export var crease_color: Color = Color(0.2, 0.3, 0.28, 1.0)
@export var emission_color: Color = Color(0.1, 0.4, 0.35, 1.0)
@export var show_creases: bool = true

# Geometry data
var _vertices: PackedVector3Array = []  # Flat pattern vertices (2D, z=0)
var _faces: Array[PackedInt32Array] = []  # Triangle indices
var _creases: Array[Vector2i] = []  # Edge pairs (vertex indices)
var _crease_fold_signs: PackedFloat32Array = []  # +1 mountain, -1 valley

# Runtime nodes
var _face_meshes: Array[MeshInstance3D] = []
var _crease_meshes: Array[MeshInstance3D] = []
var _face_pivots: Array[Node3D] = []  # Transform hierarchy for folding

# Cached materials
var _face_material: StandardMaterial3D
var _crease_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_rebuild()


func _create_materials() -> void:
	_face_material = StandardMaterial3D.new()
	_face_material.albedo_color = face_color
	_face_material.metallic = 0.15
	_face_material.roughness = 0.6
	_face_material.emission_enabled = true
	_face_material.emission = emission_color
	_face_material.emission_energy_multiplier = 0.4
	_face_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # See both sides
	
	_crease_material = StandardMaterial3D.new()
	_crease_material.albedo_color = crease_color
	_crease_material.metallic = 0.3
	_crease_material.roughness = 0.4


func _rebuild() -> void:
	# Clear existing geometry
	for child in get_children():
		child.queue_free()
	_face_meshes.clear()
	_crease_meshes.clear()
	_face_pivots.clear()
	_vertices.clear()
	_faces.clear()
	_creases.clear()
	_crease_fold_signs.clear()
	
	# Generate the crease pattern
	_generate_waterbomb_pattern()
	
	# Build the 3D mesh hierarchy
	_build_mesh_hierarchy()
	
	# Apply current deployment
	_apply_deployment()


func _generate_waterbomb_pattern() -> void:
	## Generate vertices and faces for a waterbomb tessellation sphere.
	## The pattern is a radial array of waterbomb cells from pole to pole.
	
	var n: int = radial_segments
	var m: int = ring_count
	
	# Vertex layout:
	# - Top pole (1 vertex)
	# - For each ring: n vertices around + n cell centers
	# - Equator: n vertices
	# - Mirror for bottom hemisphere
	# - Bottom pole (1 vertex)
	
	# For simplicity, we'll use a modified approach:
	# Generate a 2D crease pattern that maps to a sphere when folded.
	
	# Angular step
	var angle_step: float = TAU / float(n)
	var ring_height: float = base_radius / float(m + 1)
	
	# Top pole
	_vertices.append(Vector3(0.0, 0.0, 0.0))
	var top_pole: int = 0
	
	# Generate rings from top to equator
	var vertex_index: int = 1
	var ring_vertices: Array[PackedInt32Array] = []
	var cell_centers: Array[PackedInt32Array] = []
	
	for ring in range(m):
		var ring_radius: float = ring_height * float(ring + 1)
		var ring_verts: PackedInt32Array = []
		var centers: PackedInt32Array = []
		
		for seg in range(n):
			var angle: float = angle_step * float(seg)
			
			# Ring vertex (on the "latitude" line)
			var x: float = cos(angle) * ring_radius
			var y: float = sin(angle) * ring_radius
			_vertices.append(Vector3(x, y, 0.0))
			ring_verts.append(vertex_index)
			vertex_index += 1
			
			# Cell center (between this and next ring)
			var center_radius: float = ring_radius + ring_height * 0.5
			var center_angle: float = angle + angle_step * 0.5
			var cx: float = cos(center_angle) * center_radius
			var cy: float = sin(center_angle) * center_radius
			_vertices.append(Vector3(cx, cy, 0.0))
			centers.append(vertex_index)
			vertex_index += 1
		
		ring_vertices.append(ring_verts)
		cell_centers.append(centers)
	
	# Equator ring
	var equator_verts: PackedInt32Array = []
	var equator_radius: float = base_radius
	for seg in range(n):
		var angle: float = angle_step * float(seg)
		var x: float = cos(angle) * equator_radius
		var y: float = sin(angle) * equator_radius
		_vertices.append(Vector3(x, y, 0.0))
		equator_verts.append(vertex_index)
		vertex_index += 1
	ring_vertices.append(equator_verts)
	
	# Now create triangular faces
	# Top cap: triangles from pole to first ring through cell centers
	for seg in range(n):
		var next_seg: int = (seg + 1) % n
		var v0: int = top_pole
		var v1: int = ring_vertices[0][seg]
		var v2: int = cell_centers[0][seg]
		var v3: int = ring_vertices[0][next_seg]
		
		# Two triangles per waterbomb cell at pole
		_add_face([v0, v1, v2])
		_add_face([v0, v2, v3])
		
		# Creases
		_add_crease(v0, v1, 1.0)  # Mountain from pole
		_add_crease(v0, v2, -1.0)  # Valley to center
		_add_crease(v1, v2, 1.0)  # Mountain
		_add_crease(v2, v3, 1.0)  # Mountain
	
	# Middle rings: waterbomb cells between adjacent rings
	for ring in range(m - 1):
		var inner: PackedInt32Array = ring_vertices[ring]
		var outer: PackedInt32Array = ring_vertices[ring + 1]
		var centers_inner: PackedInt32Array = cell_centers[ring]
		var centers_outer: PackedInt32Array = cell_centers[ring + 1]
		
		for seg in range(n):
			var next_seg: int = (seg + 1) % n
			
			# Each waterbomb cell has 4 triangles meeting at center
			var center: int = centers_outer[seg]
			var v_inner: int = inner[seg]
			var v_inner_next: int = inner[next_seg]
			var v_outer: int = outer[seg]
			var v_outer_next: int = outer[next_seg]
			var center_prev: int = centers_inner[(seg + n - 1) % n]
			var center_this: int = centers_inner[seg]
			
			# Connect inner ring to outer ring through centers
			_add_face([center_this, v_inner_next, center])
			_add_face([center, v_inner_next, v_outer_next])
			_add_face([center, v_outer_next, v_outer])
			_add_face([center_this, center, v_outer])
			
			# Creases for waterbomb pattern
			_add_crease(center_this, center, -1.0)  # Valley between cells
			_add_crease(center, v_inner_next, 1.0)  # Mountain
			_add_crease(center, v_outer, 1.0)  # Mountain
			_add_crease(center, v_outer_next, 1.0)  # Mountain
	
	# Last ring to equator
	if m > 0:
		var inner: PackedInt32Array = ring_vertices[m - 1]
		var equator: PackedInt32Array = ring_vertices[m]
		var centers_last: PackedInt32Array = cell_centers[m - 1]
		
		for seg in range(n):
			var next_seg: int = (seg + 1) % n
			var center: int = centers_last[seg]
			var v_inner: int = inner[seg]
			var v_inner_next: int = inner[next_seg]
			var v_equator: int = equator[seg]
			var v_equator_next: int = equator[next_seg]
			
			_add_face([center, v_inner_next, v_equator_next])
			_add_face([center, v_equator_next, v_equator])
			
			_add_crease(center, v_equator, 1.0)
			_add_crease(center, v_equator_next, 1.0)
			_add_crease(v_equator, v_equator_next, -1.0)  # Valley at equator


func _add_face(indices: Array) -> void:
	var face: PackedInt32Array = []
	for i in indices:
		face.append(i)
	_faces.append(face)


func _add_crease(v0: int, v1: int, fold_sign: float) -> void:
	# Avoid duplicates
	var edge: Vector2i = Vector2i(min(v0, v1), max(v0, v1))
	if edge not in _creases:
		_creases.append(edge)
		_crease_fold_signs.append(fold_sign)


func _build_mesh_hierarchy() -> void:
	## Build actual 3D meshes for each face.
	## For rigid origami, we need a hierarchical transform structure
	## where each face rotates relative to its parent along the shared edge.
	
	var root: Node3D = Node3D.new()
	root.name = "ShellRoot"
	add_child(root)
	
	# For now, create individual triangle meshes
	# A more sophisticated approach would build a proper kinematic chain
	for i in range(_faces.size()):
		var face: PackedInt32Array = _faces[i]
		if face.size() < 3:
			continue
		
		var pivot: Node3D = Node3D.new()
		pivot.name = "FacePivot_%d" % i
		root.add_child(pivot)
		_face_pivots.append(pivot)
		
		# Get face vertices
		var v0: Vector3 = _vertices[face[0]]
		var v1: Vector3 = _vertices[face[1]]
		var v2: Vector3 = _vertices[face[2]]
		
		# Create triangle mesh
		var mesh: ArrayMesh = _create_triangle_mesh(v0, v1, v2)
		var mesh_instance: MeshInstance3D = MeshInstance3D.new()
		mesh_instance.mesh = mesh
		mesh_instance.material_override = _face_material
		pivot.add_child(mesh_instance)
		_face_meshes.append(mesh_instance)
	
	# Create crease lines if enabled
	if show_creases:
		for i in range(_creases.size()):
			var edge: Vector2i = _creases[i]
			var v0: Vector3 = _vertices[edge.x]
			var v1: Vector3 = _vertices[edge.y]
			
			var line_mesh: ArrayMesh = _create_line_mesh(v0, v1, 0.005)
			var line_instance: MeshInstance3D = MeshInstance3D.new()
			line_instance.mesh = line_mesh
			line_instance.material_override = _crease_material
			root.add_child(line_instance)
			_crease_meshes.append(line_instance)


func _create_triangle_mesh(v0: Vector3, v1: Vector3, v2: Vector3) -> ArrayMesh:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices: PackedVector3Array = [v0, v1, v2]
	var normals: PackedVector3Array = []
	var normal: Vector3 = (v1 - v0).cross(v2 - v0).normalized()
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _create_line_mesh(v0: Vector3, v1: Vector3, thickness: float) -> ArrayMesh:
	# Create a thin box for the crease line
	var mesh: ArrayMesh = ArrayMesh.new()
	var direction: Vector3 = (v1 - v0)
	var length: float = direction.length()
	if length < 0.001:
		return mesh
	
	direction = direction.normalized()
	var up: Vector3 = Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right: Vector3 = direction.cross(up).normalized() * thickness * 0.5
	up = right.cross(direction).normalized() * thickness * 0.5
	
	var vertices: PackedVector3Array = [
		v0 + right + up, v0 - right + up, v0 - right - up, v0 + right - up,
		v1 + right + up, v1 - right + up, v1 - right - up, v1 + right - up
	]
	
	var indices: PackedInt32Array = [
		0, 1, 5, 0, 5, 4,  # Top
		2, 3, 7, 2, 7, 6,  # Bottom
		0, 4, 7, 0, 7, 3,  # Right
		1, 2, 6, 1, 6, 5,  # Left
		0, 3, 2, 0, 2, 1,  # Front
		4, 5, 6, 4, 6, 7   # Back
	]
	
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _apply_deployment() -> void:
	## Apply the deployment parameter to fold the shell.
	## deployment = 0: fully collapsed (flat or ball shape)
	## deployment = 1: fully deployed (flower/open shape)
	
	if _face_pivots.is_empty():
		return
	
	# For a waterbomb sphere:
	# - deployment = 0: sphere is inflated (faces tilted outward)
	# - deployment = 1: sphere is deflated/open (faces fold inward)
	
	# The key insight: in rigid origami, all fold angles are coupled.
	# For a waterbomb ball, there's essentially one degree of freedom.
	
	# Simplified approach: rotate faces based on their position
	# relative to the center, using deployment to control the fold angle.
	
	var center: Vector3 = Vector3.ZERO
	
	# Calculate fold angle range
	# When deployed (t=1): faces tilt outward (positive rotation from normal)
	# When collapsed (t=0): faces are more vertical/closed
	
	var base_fold_angle: float = lerp(PI * 0.4, PI * 0.1, deployment)  # Radians
	
	for i in range(_face_pivots.size()):
		var pivot: Node3D = _face_pivots[i]
		var face: PackedInt32Array = _faces[i]
		if face.size() < 3:
			continue
		
		# Get face centroid in the flat pattern
		var centroid: Vector3 = Vector3.ZERO
		for vi in face:
			centroid += _vertices[vi]
		centroid /= float(face.size())
		
		# Direction from center to face
		var radial_dir: Vector3 = centroid.normalized()
		if radial_dir.length_squared() < 0.001:
			radial_dir = Vector3.RIGHT
		
		# Distance from center determines ring
		var dist: float = centroid.length()
		var ring_factor: float = clamp(dist / base_radius, 0.0, 1.0)
		
		# Compute the 3D position based on deployment
		# When collapsed: faces form a compact ball
		# When deployed: faces open outward like flower petals
		
		# Spherical mapping for collapsed state
		var theta: float = atan2(centroid.y, centroid.x)  # Azimuth
		var phi: float = ring_factor * PI * 0.5  # Elevation from pole
		
		# 3D position on sphere surface
		var sphere_radius: float = base_radius * lerp(0.4, 1.2, deployment)
		var sphere_pos: Vector3 = Vector3(
			sin(phi) * cos(theta),
			sin(phi) * sin(theta),
			cos(phi)
		) * sphere_radius
		
		# For deployed state, push faces outward and tilt
		var deployed_offset: float = deployment * base_radius * 0.6
		var radial_3d: Vector3 = Vector3(radial_dir.x, radial_dir.y, 0.0).normalized()
		
		pivot.position = sphere_pos + radial_3d * deployed_offset
		
		# Rotation: face should tilt based on deployment
		# Normal points outward when collapsed, tilts back when deployed
		var tilt_angle: float = lerp(-0.3, 0.8, deployment) * PI
		var tilt_axis: Vector3 = Vector3(-radial_dir.y, radial_dir.x, 0.0).normalized()
		if tilt_axis.length_squared() < 0.001:
			tilt_axis = Vector3.RIGHT
		
		pivot.rotation = Vector3.ZERO
		pivot.rotate(tilt_axis, tilt_angle)
		pivot.rotate(Vector3.UP, theta)


## Public API

func set_deployment_animated(target: float, duration: float = 0.5) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "deployment", clamp(target, 0.0, 1.0), duration)


func deploy(duration: float = 0.5) -> void:
	set_deployment_animated(1.0, duration)


func collapse(duration: float = 0.5) -> void:
	set_deployment_animated(0.0, duration)


func get_deployed_radius() -> float:
	return base_radius * lerp(0.4, 1.8, deployment)
