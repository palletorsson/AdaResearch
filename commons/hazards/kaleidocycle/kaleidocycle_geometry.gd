extends RefCounted
class_name KaleidocycleGeometry
## Kaleidocycle geometry - ring of tetrahedra that tumbles through itself.
## Infinite rotation through its center while maintaining rigid faces.

# Parameters
var segment_count: int = 6  # Number of tetrahedra
var edge_length: float = 0.2
var leg_ratio: float = 1.5  # Ratio of leg edges to base edge

# State
var rotation_phase: float = 0.0  # 0 to 2π, cycles through configurations

# Computed geometry
var tetrahedra: Array[PackedVector3Array] = []  # Each tetrahedron has 4 vertices
var face_indices: Array[PackedInt32Array] = []  # 4 faces per tetrahedron, 3 verts each
var active_face_idx: int = 0  # Which face type is currently "outward"


func build(p_segments: int, p_edge: float, p_ratio: float) -> void:
	segment_count = max(6, p_segments)  # Minimum 6 for valid kaleidocycle
	edge_length = max(0.05, p_edge)
	leg_ratio = max(1.1, p_ratio)


func solve_rotation(phase: float) -> void:
	## Compute geometry for given rotation phase.
	## phase: 0 to 2π cycles through all configurations
	
	rotation_phase = fmod(phase, TAU)
	if rotation_phase < 0:
		rotation_phase += TAU
	
	tetrahedra.clear()
	face_indices.clear()
	
	# Kaleidocycle construction:
	# Start with one tetrahedron, then chain the rest via hinge rotations
	
	var n: int = segment_count
	var base: float = edge_length
	var leg: float = edge_length * leg_ratio
	
	# Tetrahedron template (isoceles)
	# Base edge along X, apex above
	var half_base: float = base * 0.5
	var height: float = sqrt(leg * leg - half_base * half_base)
	
	# Template vertices (before any rotation)
	var template: PackedVector3Array = [
		Vector3(-half_base, 0.0, 0.0),   # Base vertex 0
		Vector3(half_base, 0.0, 0.0),    # Base vertex 1
		Vector3(0.0, height, 0.0),       # Top apex
		Vector3(0.0, height * 0.4, height * 0.6)  # Front apex (makes it 3D)
	]
	
	# Ring angle step
	var ring_angle: float = TAU / float(n)
	
	# Hinge rotation based on phase
	var hinge_angle: float = rotation_phase / float(n)
	
	# Build ring of tetrahedra
	var ring_radius: float = base * float(n) / TAU * 0.8
	
	for i in range(n):
		var angle: float = ring_angle * float(i) + rotation_phase * 0.1
		
		# Position in ring
		var center: Vector3 = Vector3(
			cos(angle) * ring_radius,
			sin(rotation_phase * 0.5 + float(i) * 0.3) * base * 0.3,
			sin(angle) * ring_radius
		)
		
		# Rotation matrices
		var ring_rot: float = angle + PI * 0.5
		var tumble: float = rotation_phase + float(i) * ring_angle * 0.5
		
		# Transform template
		var verts: PackedVector3Array = []
		for v in template:
			var rotated: Vector3 = v
			
			# Tumble rotation (around local axis)
			var tumble_axis: Vector3 = Vector3(cos(ring_rot), 0.0, sin(ring_rot))
			rotated = _rotate_around_axis(rotated, tumble_axis, tumble)
			
			# Ring position rotation
			rotated = Vector3(
				rotated.x * cos(ring_rot) - rotated.z * sin(ring_rot),
				rotated.y,
				rotated.x * sin(ring_rot) + rotated.z * cos(ring_rot)
			)
			
			# Translate to ring position
			rotated += center
			verts.append(rotated)
		
		tetrahedra.append(verts)
		
		# Face indices (4 triangular faces per tetrahedron)
		var base_idx: int = i * 4
		face_indices.append(PackedInt32Array([0, 1, 2]))  # Base-top face
		face_indices.append(PackedInt32Array([0, 1, 3]))  # Base-front face
		face_indices.append(PackedInt32Array([0, 2, 3]))  # Left face
		face_indices.append(PackedInt32Array([1, 2, 3]))  # Right face
	
	# Determine which face is "active" (outward-facing)
	active_face_idx = int(rotation_phase / (TAU / 4.0)) % 4
	
	_center_geometry()


func _rotate_around_axis(point: Vector3, axis: Vector3, angle: float) -> Vector3:
	## Rodrigues rotation formula
	axis = axis.normalized()
	var cos_a: float = cos(angle)
	var sin_a: float = sin(angle)
	
	return point * cos_a + axis.cross(point) * sin_a + axis * axis.dot(point) * (1.0 - cos_a)


func _center_geometry() -> void:
	if tetrahedra.is_empty():
		return
	
	# Find center
	var center: Vector3 = Vector3.ZERO
	var count: int = 0
	
	for tet in tetrahedra:
		for v in tet:
			center += v
			count += 1
	
	if count > 0:
		center /= float(count)
	
	# Offset all vertices
	for i in range(tetrahedra.size()):
		var tet: PackedVector3Array = tetrahedra[i]
		var new_tet: PackedVector3Array = []
		for v in tet:
			new_tet.append(v - center)
		tetrahedra[i] = new_tet


func get_bounding_radius() -> float:
	var max_dist: float = 0.0
	for tet in tetrahedra:
		for v in tet:
			max_dist = max(max_dist, v.length())
	return max_dist


func get_active_face() -> int:
	return active_face_idx
