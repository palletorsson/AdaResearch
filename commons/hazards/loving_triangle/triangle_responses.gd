# TriangleResponses.gd
# Mode-specific hit responses for The Loving Triangle.
# Each catalyst mode triggers a response in the fold/tile language:
#   compression <-> expansion, folding <-> tiling.
#
# Responses are visual-only â€” the triangle transforms, never takes damage.
# The projectile's own hit effects (shrink, color, oscillation) apply as
# a "first layer".  These responses add the "second layer" unique to
# the triangle-catalyst relationship.
extends RefCounted

# â”€â”€ Mode Identification â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
const SCRIPT_TO_MODE = {
	"res://commons/hazards/becoming_catalyst/modes/primitives_projectile.gd": "primitives",
	"res://commons/hazards/becoming_catalyst/modes/transformation_projectile.gd": "transformation",
	"res://commons/hazards/becoming_catalyst/modes/chromatic_projectile.gd": "chromatic",
	"res://commons/hazards/becoming_catalyst/modes/forces_projectile.gd": "forces",
	"res://commons/hazards/becoming_catalyst/modes/waveform_projectile.gd": "waveform",
	"res://commons/hazards/becoming_catalyst/modes/chaos_projectile.gd": "chaos",
	"res://commons/hazards/becoming_catalyst/modes/fractal_projectile.gd": "fractal",
	"res://commons/hazards/becoming_catalyst/modes/cellular_projectile.gd": "cellular",
	"res://commons/hazards/becoming_catalyst/modes/branching_projectile.gd": "branching",
	"res://commons/hazards/becoming_catalyst/modes/swarm_projectile.gd": "swarm",
}

static func identify_mode(projectile: Node3D) -> String:
	if projectile == null:
		return ""
	var script: Script = projectile.get_script()
	if script == null:
		return "primitives"
	return SCRIPT_TO_MODE.get(script.resource_path, "primitives")


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# RESPONSE DISPATCHER
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

static func respond(triangle: Node3D, mode_id: String, hit_pos: Vector3) -> void:
	match mode_id:
		"primitives":     _respond_primitives(triangle, hit_pos)
		"transformation": _respond_transformation(triangle, hit_pos)
		"chromatic":      _respond_chromatic(triangle, hit_pos)
		"forces":         _respond_forces(triangle, hit_pos)
		"waveform":       _respond_waveform(triangle, hit_pos)
		"chaos":          _respond_chaos(triangle, hit_pos)
		"fractal":        _respond_fractal(triangle, hit_pos)
		"cellular":       _respond_cellular(triangle, hit_pos)
		"branching":      _respond_branching(triangle, hit_pos)
		"swarm":          _respond_swarm(triangle, hit_pos)


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# INDIVIDUAL RESPONSES
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

## Primitives â€” "12 Triangles Make a Cube"
## Briefly shows the cube the triangle truly is: wireframe cube flash.
static func _respond_primitives(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Temporary cube wireframe overlay
	var cube_overlay = MeshInstance3D.new()
	cube_overlay.name = "CubeEcho"
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.3, 0.3)
	cube_overlay.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.9, 0.6)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.85, 0.9)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cube_overlay.material_override = mat
	cube_overlay.scale = Vector3.ZERO
	visual.add_child(cube_overlay)

	# Tween: scale in, hold, scale out
	var tween = tri.create_tween()
	tween.tween_property(cube_overlay, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(cube_overlay, "scale", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(cube_overlay.queue_free)

	# Pulse the triangle emission
	_pulse_emission(tri, Color(0.85, 0.85, 0.9), 0.8)


## Transformation â€” "Fold/Unfold"
## Collapses to flat, then refolds in a different orientation.
static func _respond_transformation(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Compression â†’ expansion: scale Y to flat, rotate, restore
	var tween = tri.create_tween()
	tween.tween_property(visual, "scale:y", 0.05, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "rotation:y", visual.rotation.y + PI, 0.2)
	tween.tween_property(visual, "scale:y", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	# Breathe cycles
	for i in 3:
		tween.tween_property(visual, "scale", Vector3(0.85, 1.15, 0.85), 0.15)
		tween.tween_property(visual, "scale", Vector3(1.15, 0.85, 1.15), 0.15)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.2)

	_pulse_emission(tri, Color(0.7, 0.3, 0.85), 0.6)


## Chromatic â€” "Stained Glass"
## Each hit adds a color to the mosaic.  Particle burst in the hit's hue.
static func _respond_chromatic(tri: Node3D, hit_pos: Vector3) -> void:
	# Accumulate hue
	if tri.has_method("_add_color"):
		var hue = randf()
		tri.call("_add_color", Color.from_hsv(hue, 0.85, 1.0))

	# Rainbow particle burst at hit point
	var burst = GPUParticles3D.new()
	burst.amount = 20
	burst.lifetime = 0.8
	burst.one_shot = true
	burst.emitting = true

	var pmat = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 3.0
	pmat.gravity = Vector3(0, -2, 0)
	pmat.scale_min = 0.01
	pmat.scale_max = 0.04

	var grad = Gradient.new()
	grad.add_point(0.0, Color.from_hsv(randf(), 0.9, 1.0, 0.9))
	grad.add_point(0.5, Color.from_hsv(randf(), 0.8, 0.9, 0.6))
	grad.add_point(1.0, Color(1, 1, 1, 0))
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	burst.process_material = pmat
	burst.draw_pass_1 = QuadMesh.new()
	burst.global_position = hit_pos
	tri.get_tree().current_scene.add_child(burst)

	# Auto-cleanup
	_auto_free(burst, 2.0)


## Forces â€” "Compression"
## All triangles fold to the smallest form (point), hover up, expand back.
static func _respond_forces(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Compress to point
	var tween = tri.create_tween()
	tween.tween_property(visual, "scale", Vector3(0.05, 0.05, 0.05), 0.5).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "position:y", visual.position.y + 0.3, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.0)
	# Slowly expand back
	tween.tween_property(visual, "scale", Vector3.ONE, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(visual, "position:y", 0.0, 0.5).set_ease(Tween.EASE_IN_OUT)

	# Warm amber ring particles
	_spawn_ring_particles(tri, Color(1.0, 0.75, 0.3))


## Waveform â€” "Ripple Tessellation"
## The triangle oscillates: rotation ripple.
static func _respond_waveform(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Spin at wave frequency for 3 seconds
	var tween = tri.create_tween()
	for i in 6:
		var angle = visual.rotation.z + PI * 0.3
		tween.tween_property(visual, "rotation:z", angle, 0.25).set_trans(Tween.TRANS_SINE)
		tween.tween_property(visual, "rotation:z", angle - PI * 0.6, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual, "rotation:z", 0.0, 0.3)

	# Teal trail particles
	_spawn_trail_particles(tri, Color(0.3, 0.85, 0.85))


## Chaos â€” "Scatter Tiles"
## Briefly fragments into 4 sub-triangles that scatter, then reform.
static func _respond_chaos(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Hide main visual
	visual.visible = false

	# Spawn 4 fragment triangles
	var fragments: Array[MeshInstance3D] = []
	var scene_root = tri.get_tree().current_scene
	for i in 4:
		var frag = MeshInstance3D.new()
		frag.mesh = _make_small_triangle(0.1)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.from_hsv(randf(), 0.8, 1.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color.from_hsv(randf(), 0.7, 0.9)
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		frag.material_override = mat
		frag.global_position = tri.global_position
		scene_root.add_child(frag)
		fragments.append(frag)

		# Scatter outward with random velocity
		var scatter_dir = Vector3(randf_range(-1, 1), randf_range(0.2, 1), randf_range(-1, 1)).normalized()
		var tween = frag.create_tween()
		tween.tween_property(frag, "position", frag.position + scatter_dir * 0.5, 0.4).set_ease(Tween.EASE_OUT)
		tween.tween_property(frag, "rotation", Vector3(randf() * TAU, randf() * TAU, randf() * TAU), 0.4)

	# After scatter, reform
	var reform_tween = tri.create_tween()
	reform_tween.tween_interval(1.2)
	reform_tween.tween_callback(func():
		for frag in fragments:
			if is_instance_valid(frag):
				var t = frag.create_tween()
				t.tween_property(frag, "global_position", tri.global_position, 0.3).set_ease(Tween.EASE_IN)
				t.tween_callback(frag.queue_free)
	)
	reform_tween.tween_interval(0.5)
	reform_tween.tween_callback(func():
		visual.visible = true
		# Flash white on reform
		_pulse_emission(tri, Color.WHITE, 0.3)
	)


## Fractal â€” "Sierpinski Fold"
## Recursive subdivision appears on faces.
static func _respond_fractal(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Spawn a burst of tiny tetrahedra in the fractal pattern
	var spawn_count = 6
	for i in spawn_count:
		var mini = MeshInstance3D.new()
		mini.name = "FractalShard_%d" % i
		var mesh = SphereMesh.new()
		mesh.radius = 0.03
		mesh.height = 0.06
		mesh.radial_segments = 3
		mesh.rings = 1
		mini.mesh = mesh

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.7, 1.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(0.4, 0.7, 1.0)
		mat.emission_energy_multiplier = 2.0
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mini.material_override = mat

		var angle = TAU * float(i) / float(spawn_count)
		var r = 0.15
		mini.position = Vector3(cos(angle) * r, sin(angle * 1.5) * 0.08, sin(angle) * r)
		mini.scale = Vector3.ZERO
		visual.add_child(mini)

		# Scale in, hold, fade out
		var tween = tri.create_tween()
		tween.tween_property(mini, "scale", Vector3(0.8, 0.8, 0.8), 0.3 + i * 0.05).set_ease(Tween.EASE_OUT)
		tween.tween_interval(4.0)
		tween.tween_property(mini, "scale", Vector3.ZERO, 0.5).set_ease(Tween.EASE_IN)
		tween.tween_callback(mini.queue_free)


## Cellular â€” "Triangular CA"
## CA grid appears on each face, evolves for a few steps.
static func _respond_cellular(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Create a 3x3 grid of tiny quads as "cells"
	var grid_root = Node3D.new()
	grid_root.name = "CAGrid"
	visual.add_child(grid_root)

	var cells: Array[MeshInstance3D] = []
	var alive: Array[bool] = []
	# Generate initial Rule 30 pattern
	var center = 4  # center of 3x3 = index 4
	for i in 9:
		alive.append(i == center or randf() > 0.5)

		var cell = MeshInstance3D.new()
		var quad = QuadMesh.new()
		quad.size = Vector2(0.04, 0.04)
		cell.mesh = quad
		var row = i / 3
		var col = i % 3
		cell.position = Vector3((col - 1) * 0.05, 0.12 + (row - 1) * 0.05, 0.0)
		cell.material_override = _make_ca_cell_material(alive[i])
		grid_root.add_child(cell)
		cells.append(cell)

	# Animate: step CA every 0.5s for 4 steps, then fade
	var step_tween = tri.create_tween()
	for _step in 4:
		step_tween.tween_interval(0.5)
		step_tween.tween_callback(func():
			var new_alive: Array[bool] = []
			for idx in 9:
				var neighbors = 0
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						if dx == 0 and dy == 0:
							continue
						var nx = (idx % 3) + dx
						var ny = (idx / 3) + dy
						if nx >= 0 and nx < 3 and ny >= 0 and ny < 3:
							if alive[ny * 3 + nx]:
								neighbors += 1
				# Simple rule: alive if 2-3 neighbors when alive, 3 when dead
				if alive[idx]:
					new_alive.append(neighbors == 2 or neighbors == 3)
				else:
					new_alive.append(neighbors == 3)
			for _i in alive.size():
				alive[_i] = new_alive[_i]
			for idx in 9:
				cells[idx].material_override = _make_ca_cell_material(alive[idx])
		)
	step_tween.tween_interval(2.0)
	step_tween.tween_callback(grid_root.queue_free)


## Branching â€” "Net Unfold"
## Tetrahedron unfolds into flat net, net branches outward like a tree.
static func _respond_branching(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Create ImmediateMesh branches from 3 vertex directions
	var im = ImmediateMesh.new()
	var branch_mesh = MeshInstance3D.new()
	branch_mesh.name = "Branches"
	branch_mesh.mesh = im
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.75, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.75, 0.3)
	mat.emission_energy_multiplier = 1.5
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	branch_mesh.material_override = mat
	visual.add_child(branch_mesh)

	# Grow branches over time
	var growth_tween = tri.create_tween()
	for i in 3:
		var base_dir = Vector3(cos(TAU / 3.0 * i), 0.0, sin(TAU / 3.0 * i)).normalized()
		var start = base_dir * 0.15

		growth_tween.tween_callback(func():
			_draw_branch(im, start, base_dir, 0.12, 0)
		)
		growth_tween.tween_interval(0.3)

	# Hold then retract
	growth_tween.tween_interval(5.0)
	growth_tween.tween_property(branch_mesh, "scale", Vector3.ZERO, 0.5).set_ease(Tween.EASE_IN)
	growth_tween.tween_callback(branch_mesh.queue_free)


## Swarm â€” "Space Fill"
## Splits into many tiny triangles that tile outward, then collapse back.
static func _respond_swarm(tri: Node3D, _hit_pos: Vector3) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return

	# Spawn a MultiMeshInstance3D with 8 tiny triangles
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _make_small_triangle(0.06)
	mm.instance_count = 8

	var mmi = MultiMeshInstance3D.new()
	mmi.name = "SwarmTiles"
	mmi.multimesh = mm

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.4)
	mat.emission_energy_multiplier = 1.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mmi.material_override = mat

	# Start at center
	for i in 8:
		mm.set_instance_transform(i, Transform3D.IDENTITY)
		mm.set_instance_color(i, Color.from_hsv(float(i) / 8.0, 0.7, 1.0))

	visual.add_child(mmi)

	# Animate: expand outward then collapse
	var time_state = [0.0]  # Wrapped in array for lambda capture
	var positions: Array[Vector3] = []
	var velocities: Array[Vector3] = []
	for i in 8:
		positions.append(Vector3.ZERO)
		var angle = TAU * float(i) / 8.0
		velocities.append(Vector3(cos(angle), randf_range(-0.3, 0.3), sin(angle)) * 0.5)

	# Use a callback-based animation to get boid-like movement
	var anim_tween = tri.create_tween()
	for _step in 40:  # ~4 seconds at 10fps tween steps
		anim_tween.tween_interval(0.1)
		anim_tween.tween_callback(func():
			time_state[0] += 0.1
			var cohesion_strength = 0.0 if time_state[0] < 2.0 else (time_state[0] - 2.0) * 0.8
			var center_pos = Vector3.ZERO
			for k in 8:
				center_pos += positions[k]
			center_pos /= 8.0

			for k in 8:
				# Cohesion: pull toward center
				var to_center = center_pos - positions[k]
				velocities[k] += to_center * cohesion_strength * 0.1
				# Separation: push away from neighbors
				for j in 8:
					if j == k:
						continue
					var diff = positions[k] - positions[j]
					var dist = diff.length()
					if dist < 0.1 and dist > 0.001:
						velocities[k] += diff.normalized() * 0.02 / dist
				# Damping
				velocities[k] *= 0.95
				positions[k] += velocities[k] * 0.1
				mm.set_instance_transform(k, Transform3D(Basis(), positions[k]))
		)
	anim_tween.tween_callback(func():
		mmi.queue_free()
		_pulse_emission(tri, Color(1.0, 0.85, 0.4), 0.3)
	)


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# HELPERS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

static func _get_visual_root(tri: Node3D) -> Node3D:
	for child in tri.get_children():
		if child is Node3D and child.is_in_group("tri_visual"):
			return child as Node3D
	return null


static func _pulse_emission(tri: Node3D, color: Color, duration: float) -> void:
	var visual = _get_visual_root(tri)
	if not visual:
		return
	for child in visual.get_children():
		if child is MeshInstance3D and child.material_override:
			var mat: StandardMaterial3D = child.material_override as StandardMaterial3D
			if mat and mat.emission_enabled:
				var original_emission: Color = mat.emission
				var original_energy: float = mat.emission_energy_multiplier
				mat.emission = color
				mat.emission_energy_multiplier = 3.0
				var tween = tri.create_tween()
				tween.tween_property(mat, "emission_energy_multiplier", original_energy, duration)
				tween.tween_property(mat, "emission", original_emission, 0.1)
			break  # Only pulse the first mesh


static func _spawn_ring_particles(tri: Node3D, color: Color) -> void:
	var particles = GPUParticles3D.new()
	particles.amount = 30
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.emitting = true

	var pmat = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pmat.emission_ring_radius = 0.15
	pmat.emission_ring_inner_radius = 0.1
	pmat.emission_ring_height = 0.01
	pmat.emission_ring_axis = Vector3(0, 1, 0)
	pmat.direction = Vector3(1, 0, 0)
	pmat.spread = 0.0
	pmat.initial_velocity_min = 0.8
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3(0, -0.5, 0)
	pmat.scale_min = 0.01
	pmat.scale_max = 0.03

	var grad = Gradient.new()
	grad.add_point(0.0, Color(color.r, color.g, color.b, 0.8))
	grad.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	particles.global_position = tri.global_position
	tri.get_tree().current_scene.add_child(particles)
	_auto_free(particles, 3.0)


static func _spawn_trail_particles(tri: Node3D, color: Color) -> void:
	var particles = GPUParticles3D.new()
	particles.amount = 16
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.emitting = true

	var pmat = ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0, -1)
	pmat.spread = 30.0
	pmat.initial_velocity_min = 1.0
	pmat.initial_velocity_max = 2.0
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.005
	pmat.scale_max = 0.015

	var grad = Gradient.new()
	grad.add_point(0.0, Color(color.r, color.g, color.b, 0.7))
	grad.add_point(1.0, Color(color.r, color.g, color.b, 0.0))
	var tex = GradientTexture1D.new()
	tex.gradient = grad
	pmat.color_ramp = tex

	particles.process_material = pmat
	particles.draw_pass_1 = QuadMesh.new()
	particles.global_position = tri.global_position
	tri.get_tree().current_scene.add_child(particles)
	_auto_free(particles, 2.0)


static func _draw_branch(im: ImmediateMesh, start: Vector3, dir: Vector3, length: float, depth: int) -> void:
	var end = start + dir * length
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(Color(0.3 + depth * 0.15, 0.7 - depth * 0.1, 0.2, 0.8))
	im.surface_add_vertex(start)
	im.surface_add_vertex(end)
	im.surface_end()

	if depth < 2:
		var branch_angle = 0.44  # ~25 degrees
		var perp: Vector3
		if abs(dir.dot(Vector3.UP)) < 0.99:
			perp = dir.cross(Vector3.UP).normalized()
		else:
			perp = dir.cross(Vector3.RIGHT).normalized()
		_draw_branch(im, end, dir.rotated(perp, branch_angle).normalized(), length * 0.65, depth + 1)
		_draw_branch(im, end, dir.rotated(perp, -branch_angle).normalized(), length * 0.65, depth + 1)


static func _make_small_triangle(size: float) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var h = size * sqrt(3.0) / 2.0
	var v0 = Vector3(0, 0, -h * 2.0 / 3.0)
	var v1 = Vector3(-size / 2.0, 0, h / 3.0)
	var v2 = Vector3(size / 2.0, 0, h / 3.0)
	var n = Vector3.UP
	verts.append(v0); verts.append(v1); verts.append(v2)
	normals.append(n); normals.append(n); normals.append(n)
	verts.append(v0); verts.append(v2); verts.append(v1)
	normals.append(-n); normals.append(-n); normals.append(-n)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _make_ca_cell_material(alive: bool) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	if alive:
		mat.albedo_color = Color(0.95, 0.95, 0.95, 0.9)
		mat.emission_enabled = true
		mat.emission = Color.WHITE
		mat.emission_energy_multiplier = 2.0
	else:
		mat.albedo_color = Color(0.2, 0.2, 0.25, 0.4)
		mat.emission_enabled = true
		mat.emission = Color(0.15, 0.15, 0.2)
		mat.emission_energy_multiplier = 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


static func _auto_free(node: Node, delay: float) -> void:
	var timer = Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.timeout.connect(node.queue_free)
	node.add_child(timer)
	timer.start()

