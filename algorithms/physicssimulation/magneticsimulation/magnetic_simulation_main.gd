## Magnetic Simulation — RigidBody3D magnets with force-based attraction/repulsion
## Uses apply_central_force() for magnetic interaction, GPUParticles3D for field lines
extends Node3D

@export var magnet_count: int = 4
@export var magnetic_constant: float = 5.0

var magnets: Array[RigidBody3D] = []
var polarities: Array[float] = []  # +1 or -1

func _ready():
	scale = Vector3(0.8, 0.8, 0.8)
	_create_floor()
	_create_magnets()
	_create_field_particles()

func _create_floor():
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(6, 0.2, 6)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

func _create_magnets():
	var positions := [
		Vector3(-1, 1, -1), Vector3(1, 1, -1),
		Vector3(-1, 1, 1), Vector3(1, 1, 1)
	]

	for i in range(magnet_count):
		var rb := RigidBody3D.new()
		rb.name = "Magnet_%d" % i
		rb.mass = 1.0
		rb.linear_damp = 0.5
		rb.angular_damp = 0.5

		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.2
		shape.height = 0.4
		col.shape = shape
		rb.add_child(col)

		var mesh_inst := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.2
		cyl.height = 0.4
		mesh_inst.mesh = cyl

		# Alternate polarity
		var polarity := 1.0 if i % 2 == 0 else -1.0
		polarities.append(polarity)

		var mat := StandardMaterial3D.new()
		if polarity > 0:
			mat.albedo_color = Color(1.0, 0.2, 0.2)  # North = red
			mat.emission = Color(1.0, 0.1, 0.1) * 0.4
		else:
			mat.albedo_color = Color(0.2, 0.3, 1.0)  # South = blue
			mat.emission = Color(0.1, 0.2, 1.0) * 0.4
		mat.emission_enabled = true
		mat.metallic = 0.7
		mat.roughness = 0.3
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)

		rb.position = positions[i]
		add_child(rb)
		magnets.append(rb)

func _create_field_particles():
	# Iron filings effect using GPUParticles3D
	var particles := GPUParticles3D.new()
	particles.name = "FieldParticles"
	particles.amount = 60
	particles.lifetime = 3.0
	particles.position = Vector3(0, 1, 0)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(2, 0.5, 2)
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.1
	mat.initial_velocity_max = 0.3
	mat.gravity = Vector3(0, -2, 0)
	mat.damping_min = 2.0
	mat.damping_max = 4.0
	mat.scale_min = 0.02
	mat.scale_max = 0.04
	mat.color = Color(0.6, 0.6, 0.7)

	particles.process_material = mat
	particles.draw_pass_1 = SphereMesh.new()
	particles.draw_pass_1.radius = 0.02
	particles.draw_pass_1.height = 0.04

	add_child(particles)

func _physics_process(_delta: float):
	# Apply magnetic forces between all pairs
	for i in range(magnets.size()):
		for j in range(i + 1, magnets.size()):
			var a := magnets[i]
			var b := magnets[j]
			var direction := b.position - a.position
			var dist := direction.length()
			if dist < 0.3:
				continue

			# Magnetic force: F = k * p1 * p2 / r²
			# Same polarity = repulsion, opposite = attraction
			var force_mag := magnetic_constant * polarities[i] * polarities[j] / (dist * dist)
			var force := direction.normalized() * force_mag

			# Opposite poles attract (force_mag negative when polarities differ)
			a.apply_central_force(force)
			b.apply_central_force(-force)
