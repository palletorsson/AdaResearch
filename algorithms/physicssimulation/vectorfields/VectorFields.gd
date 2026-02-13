## Vector Fields — Visualizes force fields with MultiMesh arrows and Area3D sources
## Arrows rendered in ONE draw call via MultiMesh, particles advected through the field
extends Node3D

@export var grid_resolution: int = 6  # arrows per axis (6³ = 216 arrows)
@export var grid_spacing: float = 0.6
@export var arrow_scale: float = 0.1
@export var particle_count: int = 30

var arrow_multimesh: MultiMeshInstance3D
var field_sources: Array[Area3D] = []
var particles: Array[RigidBody3D] = []

func _ready():
	scale = Vector3(0.8, 0.8, 0.8)
	_create_field_sources()
	_create_arrow_grid()
	_create_test_particles()

func _create_field_sources():
	# Attractor (pulls inward)
	var attractor := Area3D.new()
	attractor.name = "Attractor"
	attractor.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	attractor.gravity_point = true
	attractor.gravity = 8.0
	attractor.gravity_point_unit_distance = 2.0
	var acol := CollisionShape3D.new()
	var ashape := SphereShape3D.new()
	ashape.radius = 3.0
	acol.shape = ashape
	attractor.add_child(acol)
	attractor.position = Vector3(-1.5, 1.5, 0)

	# Visual marker
	var amarker := MeshInstance3D.new()
	var asphere := SphereMesh.new()
	asphere.radius = 0.15
	amarker.mesh = asphere
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(1.0, 0.3, 0.3)
	amat.emission_enabled = true
	amat.emission = Color(1.0, 0.2, 0.2) * 0.8
	amarker.material_override = amat
	attractor.add_child(amarker)
	add_child(attractor)
	field_sources.append(attractor)

	# Repulsor (pushes outward)
	var repulsor := Area3D.new()
	repulsor.name = "Repulsor"
	repulsor.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	repulsor.gravity_point = true
	repulsor.gravity = -6.0  # Negative = repulsion
	repulsor.gravity_point_unit_distance = 2.0
	var rcol := CollisionShape3D.new()
	var rshape := SphereShape3D.new()
	rshape.radius = 3.0
	rcol.shape = rshape
	repulsor.add_child(rcol)
	repulsor.position = Vector3(1.5, 1.5, 0)

	var rmarker := MeshInstance3D.new()
	var rsphere := SphereMesh.new()
	rsphere.radius = 0.15
	rmarker.mesh = rsphere
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.3, 0.5, 1.0)
	rmat.emission_enabled = true
	rmat.emission = Color(0.2, 0.4, 1.0) * 0.8
	rmarker.material_override = rmat
	repulsor.add_child(rmarker)
	add_child(repulsor)
	field_sources.append(repulsor)

func _create_arrow_grid():
	arrow_multimesh = MultiMeshInstance3D.new()
	arrow_multimesh.name = "ArrowGrid"

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var total := grid_resolution * grid_resolution * grid_resolution
	mm.instance_count = total

	# Arrow mesh (thin cone)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_scale * 0.5
	cone.height = arrow_scale * 2.0
	mm.mesh = cone

	arrow_multimesh.multimesh = mm

	# Material
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	arrow_multimesh.material_override = mat

	add_child(arrow_multimesh)
	_update_arrows()

func _create_test_particles():
	for i in range(particle_count):
		var rb := RigidBody3D.new()
		rb.mass = 0.1
		rb.linear_damp = 1.0  # Some drag so they don't fly away

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.04
		col.shape = shape
		rb.add_child(col)

		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.04
		sphere.height = 0.08
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 0.3)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.9, 0.2) * 0.6
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)

		# Random position in the field
		rb.position = Vector3(
			randf_range(-1.5, 1.5),
			randf_range(0.5, 2.5),
			randf_range(-1.5, 1.5)
		)
		rb.gravity_scale = 0.0  # Only affected by Area3D fields

		add_child(rb)
		particles.append(rb)

func _physics_process(_delta: float):
	# Respawn escaped particles
	for rb in particles:
		if rb.position.length() > 5.0:
			rb.position = Vector3(
				randf_range(-1.5, 1.5),
				randf_range(0.5, 2.5),
				randf_range(-1.5, 1.5)
			)
			rb.linear_velocity = Vector3.ZERO

func _update_arrows():
	var mm := arrow_multimesh.multimesh
	var idx := 0
	var half := (grid_resolution - 1) * grid_spacing * 0.5

	for x in range(grid_resolution):
		for y in range(grid_resolution):
			for z in range(grid_resolution):
				var pos := Vector3(
					x * grid_spacing - half,
					y * grid_spacing + 0.3,
					z * grid_spacing - half
				)

				# Calculate field vector at this point
				var field := Vector3.ZERO
				for source in field_sources:
					var to_source := source.position - pos
					var dist := to_source.length()
					if dist < 0.1:
						continue
					var strength: float = source.gravity / (dist * dist)
					if source.gravity > 0:
						field += to_source.normalized() * strength
					else:
						field -= to_source.normalized() * abs(strength)

				# Orient arrow along field direction
				var t := Transform3D.IDENTITY
				t.origin = pos
				if field.length() > 0.01:
					var up := Vector3.UP
					if abs(field.normalized().dot(up)) > 0.99:
						up = Vector3.RIGHT
					t = t.looking_at(pos + field.normalized(), up)
					t.basis = t.basis * Basis(Vector3.RIGHT, -PI / 2)  # Point cone along direction

				var mag := clamp(field.length(), 0.1, 3.0)
				t.basis = t.basis.scaled(Vector3(1, mag, 1))
				mm.set_instance_transform(idx, t)

				# Color by magnitude
				var color := Color.from_hsv(0.6 - clamp(mag / 3.0, 0, 0.6), 0.8, 1.0)
				mm.set_instance_color(idx, color)

				idx += 1
