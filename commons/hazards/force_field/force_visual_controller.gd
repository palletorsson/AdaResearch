# ForceVisualController.gd
# Manages visual state transitions for ForceField.
# Builds and updates: zone mesh, particles, light, label, progress ring.
# Follows PlasmaCritter's _build_visuals / _apply_form_visuals pattern.
extends RefCounted
class_name ForceVisualController

# ── Built nodes ──────────────────────────────────────────────────────────
var zone_mesh: MeshInstance3D
var zone_material: StandardMaterial3D
var particles: GPUParticles3D
var particle_material: ParticleProcessMaterial
var light: OmniLight3D
var label: Label3D
var progress_ring: MeshInstance3D
var progress_material: StandardMaterial3D

var _parent: Node3D


func build(parent: Node3D, radius: float, height: float) -> void:
	_parent = parent

	# ── Zone mesh (translucent cylinder) ─────────────────────────────
	zone_mesh = MeshInstance3D.new()
	zone_mesh.name = "ForceZoneMesh"
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 24
	cyl.rings = 1
	zone_mesh.mesh = cyl

	zone_material = StandardMaterial3D.new()
	zone_material.albedo_color = Color(1, 0, 0, 0.3)
	zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	zone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	zone_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	zone_material.emission_enabled = true
	zone_material.emission = Color(1, 0, 0)
	zone_material.emission_energy_multiplier = 0.5
	zone_mesh.material_override = zone_material
	zone_mesh.position.y = height * 0.5
	_parent.add_child(zone_mesh)

	# ── Particles ────────────────────────────────────────────────────
	particles = GPUParticles3D.new()
	particles.name = "ForceParticles"
	particles.emitting = true
	particles.amount = 40
	particles.lifetime = 2.5
	particles.position.y = height * 0.5

	particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 1, 0)
	particle_material.spread = 45.0
	particle_material.initial_velocity_min = 0.3
	particle_material.initial_velocity_max = 1.2
	particle_material.gravity = Vector3(0, 0.2, 0)
	particle_material.scale_min = 0.04
	particle_material.scale_max = 0.12
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	particle_material.emission_sphere_radius = radius * 0.8

	var grad: Gradient = Gradient.new()
	grad.add_point(0.0, Color(1, 0.5, 0, 0.9))
	grad.add_point(1.0, Color(1, 0, 0, 0.0))
	var grad_tex: GradientTexture1D = GradientTexture1D.new()
	grad_tex.gradient = grad
	particle_material.color_ramp = grad_tex

	particles.process_material = particle_material
	particles.draw_pass_1 = QuadMesh.new()
	_parent.add_child(particles)

	# ── Light ────────────────────────────────────────────────────────
	light = OmniLight3D.new()
	light.name = "ForceLight"
	light.light_energy = 1.5
	light.omni_range = radius * 3.0
	light.omni_attenuation = 1.5
	light.shadow_enabled = false
	light.position.y = height * 0.5
	_parent.add_child(light)

	# ── Label ────────────────────────────────────────────────────────
	label = Label3D.new()
	label.name = "ForceLabel"
	label.font_size = 36
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position.y = height + 0.3
	_parent.add_child(label)

	# ── Progress ring (hidden until transmuting) ─────────────────────
	progress_ring = MeshInstance3D.new()
	progress_ring.name = "ProgressRing"
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = radius * 0.85
	torus.outer_radius = radius * 0.95
	torus.rings = 32
	torus.ring_segments = 16
	progress_ring.mesh = torus
	progress_ring.rotation.x = -PI / 2.0  # Lay flat
	progress_ring.position.y = 0.05

	progress_material = StandardMaterial3D.new()
	progress_material.albedo_color = Color(1, 1, 1, 0.6)
	progress_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	progress_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	progress_material.emission_enabled = true
	progress_material.emission = Color(1, 1, 1)
	progress_material.emission_energy_multiplier = 1.5
	progress_ring.material_override = progress_material
	progress_ring.visible = false
	_parent.add_child(progress_ring)


func apply_hazard_visuals(config: Dictionary) -> void:
	_apply_config(config)
	if label:
		label.text = config.get("description", "FORCE")
		label.modulate = config.get("emission", Color.RED)
	if progress_ring:
		progress_ring.visible = false


func apply_transmuted_visuals(config: Dictionary) -> void:
	_apply_config(config)
	if label:
		label.text = config.get("description", "TRANSMUTED")
		label.modulate = config.get("emission", Color.GREEN)
	if progress_ring:
		progress_ring.visible = false


func apply_transmuting_blend(hazard_cfg: Dictionary, transmuted_cfg: Dictionary, progress: float) -> void:
	# Blend between hazard and transmuted visuals
	var t: float = clampf(progress, 0.0, 1.0)

	if zone_material:
		var c_from: Color = hazard_cfg.get("color", Color(1, 0, 0, 0.3))
		var c_to: Color = transmuted_cfg.get("color", Color(0, 1, 0, 0.3))
		zone_material.albedo_color = c_from.lerp(c_to, t)

		var e_from: Color = hazard_cfg.get("emission", Color.RED)
		var e_to: Color = transmuted_cfg.get("emission", Color.GREEN)
		zone_material.emission = e_from.lerp(e_to, t)

	if light:
		var lc_from: Color = hazard_cfg.get("light_color", Color.RED)
		var lc_to: Color = transmuted_cfg.get("light_color", Color.GREEN)
		light.light_color = lc_from.lerp(lc_to, t)

		var le_from: float = hazard_cfg.get("light_energy", 1.5)
		var le_to: float = transmuted_cfg.get("light_energy", 0.8)
		light.light_energy = lerpf(le_from, le_to, t)

	# Progress ring: visible during transmutation, scales with progress
	if progress_ring:
		progress_ring.visible = true
		var ring_alpha: float = 0.3 + 0.5 * t
		progress_material.albedo_color = Color(1, 1, 1, ring_alpha)
		var e_blend: Color = hazard_cfg.get("emission", Color.WHITE).lerp(
			transmuted_cfg.get("emission", Color.WHITE), t
		)
		progress_material.emission = e_blend
		progress_ring.scale = Vector3(t, t, t)

	if label:
		label.text = "TRANSMUTING... %d%%" % int(t * 100.0)
		var lbl_color: Color = hazard_cfg.get("emission", Color.WHITE).lerp(
			transmuted_cfg.get("emission", Color.WHITE), t
		)
		label.modulate = lbl_color


func _apply_config(config: Dictionary) -> void:
	if zone_material:
		zone_material.albedo_color = config.get("color", Color(0.5, 0.5, 0.5, 0.3))
		zone_material.emission = config.get("emission", Color(0.5, 0.5, 0.5))
		zone_material.emission_energy_multiplier = config.get("emission_energy", 0.5)

	if light:
		light.light_color = config.get("light_color", Color.WHITE)
		light.light_energy = config.get("light_energy", 1.0)

	if particle_material:
		particle_material.direction = config.get("particle_direction", Vector3(0, 1, 0))
		particle_material.spread = config.get("particle_spread", 45.0)

		var grad: Gradient = Gradient.new()
		grad.add_point(0.0, config.get("particle_color_start", Color(1, 1, 1, 0.8)))
		grad.add_point(1.0, config.get("particle_color_end", Color(1, 1, 1, 0.0)))
		var grad_tex: GradientTexture1D = GradientTexture1D.new()
		grad_tex.gradient = grad
		particle_material.color_ramp = grad_tex
