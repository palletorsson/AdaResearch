# tunable_field.gd
# Seq 17: QFEP laboratory. Two floating knob-like indicators — λ and φ —
# visualize that the biome is now tunable. Positioned above the map.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var lam: float = float(params.get("lambda_init", 0.5))
	var phi: float = float(params.get("phi_init", 0.5))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var height: float = 6.0
	var span: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.4

	# Lambda (green) to the left, Phi (magenta) to the right
	_add_knob(grid_center + Vector3(-span, height, 0), lam, Color(0.3, 1.0, 0.5), "λ")
	_add_knob(grid_center + Vector3(span, height, 0), phi, Color(1.0, 0.5, 1.0), "φ")


func _add_knob(pos: Vector3, value: float, col: Color, _label: String) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	# Outer ring
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.45
	ring.mesh = torus
	ring.rotation.x = PI * 0.5
	_apply_mat(ring, col, 0.8)
	root.add_child(ring)

	# Pointer (indicates current value)
	var pointer := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.08, 0.08, 0.4)
	pointer.mesh = pm
	pointer.rotation.y = value * TAU
	pointer.position = Vector3(0, 0, 0)
	_apply_mat(pointer, col.lightened(0.3), 1.2)
	root.add_child(pointer)


func _apply_mat(mi: MeshInstance3D, col: Color, em: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = em
	mi.material_override = mat
