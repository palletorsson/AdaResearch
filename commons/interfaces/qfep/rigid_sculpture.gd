# rigid_sculpture.gd
# QFEP φ < 0 Visualization - Rigid Sculpture
# Conservative: resists change, preserves pattern
# Static, frozen, crystalline structure

extends Node3D

class_name QFEPRigidSculpture

# @identity
# essence: octahedron_center + radial_prisms(angle = i/n * TAU) + caps -> crystalline sculpture, no _process
# desire: confront a form that refuses to move — perfect geometry locked in metallic purple
# critical_parameter: the absence of animation — no _process means no becoming, only being
# triggers: nothing — the sculpture is immune to time
# emerges: nothing emerges — and that absence is the lesson
# needs: no VR controls — rigidity is the interaction [has]
# relationships: contrasts fluid_form (phi>0 vs phi<0); paired with preserved_pattern; represents conservative resistance to change
# truth: negative phi crystallizes form into monument — the rigid sculpture is beautiful and dead

## Sculpture size
@export var size: float = 0.4

## Number of elements
@export var element_count: int = 8

## Conservative color (purple)
@export var rigid_color: Color = Color(0.6, 0.3, 0.7, 1.0)

# Internal
var _elements: Array[MeshInstance3D] = []

func _ready() -> void:
	_build_sculpture()

func _build_sculpture() -> void:
	# Create a crystalline structure - rigid, angular, frozen
	var mat = StandardMaterial3D.new()
	mat.albedo_color = rigid_color
	mat.emission_enabled = true
	mat.emission = rigid_color
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.8
	mat.roughness = 0.2
	
	# Central octahedron
	var center = MeshInstance3D.new()
	var center_mesh = _create_octahedron(size * 0.5)
	center.mesh = center_mesh
	center.material_override = mat
	add_child(center)
	_elements.append(center)
	
	# Surrounding prisms - fixed positions, no variation
	for i in range(element_count):
		var element = MeshInstance3D.new()
		var prism = PrismMesh.new()
		prism.size = Vector3(size * 0.15, size * 0.4, size * 0.15)
		element.mesh = prism
		element.material_override = mat
		
		# Perfect geometric arrangement
		var angle = (float(i) / element_count) * TAU
		var radius = size * 0.6
		element.position = Vector3(
			cos(angle) * radius,
			0,
			sin(angle) * radius
		)
		# Point outward
		element.rotation.y = -angle
		
		add_child(element)
		_elements.append(element)
	
	# Top and bottom caps
	for y_mult in [-1, 1]:
		var cap = MeshInstance3D.new()
		var cap_mesh = _create_octahedron(size * 0.2)
		cap.mesh = cap_mesh
		cap.material_override = mat
		cap.position.y = size * 0.5 * y_mult
		add_child(cap)
		_elements.append(cap)

func _create_octahedron(s: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Vertices of octahedron
	var top = Vector3(0, s, 0)
	var bottom = Vector3(0, -s, 0)
	var front = Vector3(0, 0, s)
	var back = Vector3(0, 0, -s)
	var left = Vector3(-s, 0, 0)
	var right = Vector3(s, 0, 0)
	
	# Top 4 faces
	_add_triangle(st, top, front, right)
	_add_triangle(st, top, right, back)
	_add_triangle(st, top, back, left)
	_add_triangle(st, top, left, front)
	
	# Bottom 4 faces
	_add_triangle(st, bottom, right, front)
	_add_triangle(st, bottom, back, right)
	_add_triangle(st, bottom, left, back)
	_add_triangle(st, bottom, front, left)
	
	st.generate_normals()
	return st.commit()

func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

# Rigid sculpture doesn't animate - that's the point!
# It resists change.
