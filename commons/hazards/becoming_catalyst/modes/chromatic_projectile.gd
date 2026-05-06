# ChromaticProjectile.gd
# Rainbow sphere that permanently colors whatever grid cubes it hits.
# Colors + transforms + fractal-spawns cubes on impact.
extends CatalystProjectile

var _hue_offset: float = 0.0
const COLOR_RADIUS := 1.5  # Meters — how far the paint splashes
const FRACTAL_SCALE := 0.45  # Spawned cubes are smaller
const FRACTAL_OFFSET := 0.6  # How far spawned cubes fly out

func _build_visual() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06 * projectile_scale
	sphere.height = 0.12 * projectile_scale
	_mesh_instance.mesh = sphere
	_mesh_instance.material_override = _make_material(color_primary, emission_energy)
	add_child(_mesh_instance)

	# Rainbow trail particles
	_particles = GPUParticles3D.new()
	_particles.amount = 20
	_particles.lifetime = 0.4
	_particles.emitting = true

	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0, 1)
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.01
	pmat.scale_max = 0.03

	var grad := Gradient.new()
	grad.add_point(0.0, Color(color_primary, 0.9))
	grad.add_point(0.5, Color(color_secondary, 0.5))
	grad.add_point(1.0, Color(color_secondary, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	_particles.process_material = pmat
	_particles.draw_pass_1 = QuadMesh.new()
	add_child(_particles)

func _update_trajectory(_delta: float) -> void:
	# Hue cycling on the mesh
	if _mesh_instance and _mesh_instance.material_override and not has_hit:
		_hue_offset += _delta * 0.5
		var mat: StandardMaterial3D = _mesh_instance.material_override
		var new_color := Color.from_hsv(fmod(color_primary.h + _hue_offset, 1.0), 0.85, 1.0)
		mat.emission = new_color

func _on_hit(body: Node3D) -> void:
	projectile_hit.emit(body, global_position)
	if body.has_method("hit_by_projectile"):
		body.hit_by_projectile(color_primary)
	# Paint grid cubes via MultiMesh
	_paint_grid_cubes(global_position)

func _paint_grid_cubes(hit_pos: Vector3) -> void:
	if not is_inside_tree():
		return
	# Find the GridSystem via its group
	var grids := get_tree().get_nodes_in_group("grid_system")
	for grid in grids:
		if not is_instance_valid(grid):
			continue
		var struct = grid.get("structure_component")
		if not struct:
			continue
		var mm: MultiMesh = struct.get("multimesh")
		if not mm:
			continue
		var positions: Array = struct.get("cube_positions")
		if positions.is_empty():
			continue
		var cs: float = struct.get("cube_size")
		var gt: float = struct.get("gutter")
		var total_size: float = cs + gt
		# Grid node's global transform offsets cube world positions
		var grid_origin: Vector3 = grid.global_position if grid is Node3D else Vector3.ZERO

		var scene_root := get_tree().current_scene
		for i in positions.size():
			var gp: Vector3i = positions[i]
			var world_pos := grid_origin + Vector3(gp.x, gp.y, gp.z) * total_size
			var dist := world_pos.distance_to(hit_pos)
			if dist < COLOR_RADIUS:
				var hue_shift := dist * 0.15
				var paint_color := Color.from_hsv(
					fmod(color_primary.h + hue_shift, 1.0),
					0.8,
					0.95
				)
				# Color the cube
				mm.set_instance_color(i, paint_color)

				# Transform the cube — scale down, shift, rotate
				var t := mm.get_instance_transform(i)
				var shrink: float = randf_range(0.75, 0.92)
				t.basis = t.basis.scaled(Vector3.ONE * shrink)
				t.basis = t.basis.rotated(
					Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized(),
					randf_range(-0.3, 0.3)
				)
				t.origin += Vector3(
					randf_range(-0.15, 0.15),
					randf_range(-0.1, 0.1),
					randf_range(-0.15, 0.15)
				)
				mm.set_instance_transform(i, t)

				# Fractal spawn — two small cubes fly out
				_spawn_fractal_cubes(world_pos, paint_color, cs, scene_root)

func _spawn_fractal_cubes(origin: Vector3, base_color: Color, cube_size: float, scene_root: Node) -> void:
	var child_size: float = cube_size * FRACTAL_SCALE
	for c in 2:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * child_size
		mi.mesh = box

		var mat := StandardMaterial3D.new()
		var hue_shift: float = c * 0.12
		var col := Color.from_hsv(fmod(base_color.h + hue_shift, 1.0), 0.85, 1.0)
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 1.2
		mat.metallic = 0.3
		mat.roughness = 0.4
		mi.material_override = mat

		# Random direction away from impact
		var dir := Vector3(
			randf_range(-1, 1), randf_range(0.2, 1), randf_range(-1, 1)
		).normalized()
		mi.global_position = origin
		scene_root.add_child(mi)

		# Tween: fly out, shrink, then vanish
		var end_pos := origin + dir * FRACTAL_OFFSET
		var tw := mi.create_tween()
		tw.set_parallel(true)
		tw.tween_property(mi, "global_position", end_pos, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(mi, "scale", Vector3.ONE * 0.1, 0.8).set_ease(Tween.EASE_IN).set_delay(0.4)
		tw.set_parallel(false)
		tw.tween_callback(mi.queue_free)
