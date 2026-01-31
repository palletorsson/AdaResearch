@tool
extends Node3D
class_name AlessiTree

## Procedural Alessi-style stacked cone tree with radial stripes
## Based on Alessi holiday decorations

@export var height: float = 1.0:
	set(v):
		height = v
		_rebuild()

@export var base_radius: float = 0.4:
	set(v):
		base_radius = v
		_rebuild()

@export_range(3, 12) var tiers: int = 5:
	set(v):
		tiers = v
		_rebuild()

@export_range(8, 64) var radial_segments: int = 24:
	set(v):
		radial_segments = v
		_rebuild()

@export var stripe_count: int = 12:
	set(v):
		stripe_count = v
		_rebuild()

@export var color_a: Color = Color.WHITE:
	set(v):
		color_a = v
		_rebuild()

@export var color_b: Color = Color(0.9, 0.15, 0.1):
	set(v):
		color_b = v
		_rebuild()

@export var gold_trim: bool = true:
	set(v):
		gold_trim = v
		_rebuild()

var _mesh_instance: MeshInstance3D

func _ready():
	_rebuild()

func _rebuild():
	if _mesh_instance:
		_mesh_instance.queue_free()
	
	_mesh_instance = MeshInstance3D.new()
	add_child(_mesh_instance)
	
	var mesh = _generate_mesh()
	_mesh_instance.mesh = mesh

func _generate_mesh() -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Generate profile - zigzag pattern
	var profile = []
	var tier_height = height / tiers
	
	for t in range(tiers + 1):
		var y = t * tier_height
		var progress = float(t) / tiers
		
		# Alternate between wide and narrow
		var envelope = 1.0 - progress * 0.7  # Taper toward top
		if t % 2 == 0:
			# Wide point
			profile.append([base_radius * envelope, y])
		else:
			# Narrow point
			profile.append([base_radius * envelope * 0.5, y])
	
	# Top cap
	profile.append([base_radius * 0.1, height])
	
	# Generate mesh by revolving profile
	for p in range(profile.size() - 1):
		var r0 = profile[p][0]
		var y0 = profile[p][1]
		var r1 = profile[p + 1][0]
		var y1 = profile[p + 1][1]
		
		for s in range(radial_segments):
			var theta0 = TAU * s / radial_segments
			var theta1 = TAU * (s + 1) / radial_segments
			
			var stripe_idx = int(s * stripe_count / radial_segments)
			var color = color_a if stripe_idx % 2 == 0 else color_b
			
			# Four vertices of this quad
			var v00 = Vector3(cos(theta0) * r0, y0, sin(theta0) * r0)
			var v10 = Vector3(cos(theta1) * r0, y0, sin(theta1) * r0)
			var v01 = Vector3(cos(theta0) * r1, y1, sin(theta0) * r1)
			var v11 = Vector3(cos(theta1) * r1, y1, sin(theta1) * r1)
			
			# Calculate normal (approximate)
			var n = ((v10 - v00).cross(v01 - v00)).normalized()
			
			st.set_color(color)
			st.set_normal(n)
			
			# Triangle 1
			st.add_vertex(v00)
			st.add_vertex(v01)
			st.add_vertex(v10)
			
			# Triangle 2
			st.add_vertex(v10)
			st.add_vertex(v01)
			st.add_vertex(v11)
	
	# Bottom cap
	var gold = Color(0.85, 0.65, 0.13) if gold_trim else color_a
	for s in range(radial_segments):
		var theta0 = TAU * s / radial_segments
		var theta1 = TAU * (s + 1) / radial_segments
		var r = profile[0][0]
		
		var v0 = Vector3(cos(theta0) * r, 0, sin(theta0) * r)
		var v1 = Vector3(cos(theta1) * r, 0, sin(theta1) * r)
		
		st.set_color(gold)
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(v1)
		st.add_vertex(v0)
	
	var mesh = st.commit()
	
	# Create material that uses vertex colors
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.1
	mat.roughness = 0.3
	
	mesh.surface_set_material(0, mat)
	
	return mesh
