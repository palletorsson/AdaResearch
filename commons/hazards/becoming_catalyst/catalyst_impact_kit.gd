# CatalystImpactKit.gd
# The shared impact language for catalyst projectiles — every mode's hit
# gets the same four VR-safe layers, tinted by the mode's own colors:
#
#   1. flash core   — white-hot sphere, scales up while fading (0.18 s)
#   2. shockwave    — expanding torus ring facing the impact normal (0.35 s)
#   3. ring spray   — flat disc of particles flying outward (0.5 s)
#   4. light pulse  — OmniLight in the mode color, 3.5 -> 0 (0.3 s)
#   + a light haptic tick on the player's controllers (house value)
#
# Composed from the best precedents in the repo: sentry_turret's
# flash/ring/light decomposition, catalyst_foe's near-field light pulse,
# triangle_responses' EMISSION_SHAPE_RING spray and static+auto-free
# convention, primitives_projectile's scene-parenting so the effect stays
# pinned at the contact point after the body is freed.
#
# Deliberately NOT here (VR-hostile): camera shake, Engine.time_scale
# hit-stop, full-screen ripple/flash. World-space + haptics only.
#
# Usage (preload, not class_name — headless boots resolve preloads only):
#   const ImpactKit := preload("res://commons/hazards/becoming_catalyst/catalyst_impact_kit.gd")
#   ImpactKit.burst(parent, global_position, normal, color_primary, color_secondary, scale)
extends RefCounted

const FLASH_TIME := 0.18
const RING_TIME := 0.35
const SPRAY_TIME := 0.5
const LIGHT_TIME := 0.3
const HAPTIC := [0.08, 0.3]   # duration, amplitude — the house light-impact value


static func burst(parent: Node, pos: Vector3, normal: Vector3,
		primary: Color, secondary: Color, scale_mult: float = 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	_flash_core(parent, pos, scale_mult)
	_shock_ring(parent, pos, normal, primary, scale_mult)
	_ring_spray(parent, pos, normal, primary, secondary, scale_mult)
	_light_pulse(parent, pos, primary)
	_haptic_tick(parent)


static func _flash_core(parent: Node, pos: Vector3, s: float) -> void:
	var core := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.09 * s
	mesh.height = 0.18 * s
	core.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.emission_energy_multiplier = 12.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core.material_override = mat
	parent.add_child(core)
	core.global_position = pos
	var tw := core.create_tween().set_parallel(true)
	tw.tween_property(core, "scale", Vector3.ONE * 2.5, FLASH_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, FLASH_TIME)
	tw.chain().tween_callback(core.queue_free)


static func _shock_ring(parent: Node, pos: Vector3, normal: Vector3, tint: Color, s: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.10 * s
	torus.outer_radius = 0.13 * s
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(tint.r, tint.g, tint.b, 0.85)
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring.material_override = mat
	parent.add_child(ring)
	ring.global_position = pos
	# torus lies in the XZ plane (axis = Y); aim its axis along the normal
	var n := normal.normalized()
	if n.length_squared() > 0.5 and absf(n.dot(Vector3.UP)) < 0.99:
		ring.global_transform.basis = Basis(Quaternion(Vector3.UP, n))
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * 3.5, RING_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, RING_TIME)
	tw.chain().tween_callback(ring.queue_free)


static func _ring_spray(parent: Node, pos: Vector3, normal: Vector3,
		primary: Color, secondary: Color, s: float) -> void:
	var spray := GPUParticles3D.new()
	spray.emitting = true
	spray.amount = 16
	spray.lifetime = SPRAY_TIME
	spray.one_shot = true
	spray.explosiveness = 0.95
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 0.12 * s
	mat.emission_ring_inner_radius = 0.08 * s
	mat.emission_ring_height = 0.01
	mat.emission_ring_axis = Vector3(0, 1, 0)
	mat.spread = 8.0
	mat.initial_velocity_min = 2.2
	mat.initial_velocity_max = 3.6
	mat.gravity = Vector3.ZERO
	mat.damping_min = 3.0
	mat.damping_max = 5.0
	mat.scale_min = 0.03 * s
	mat.scale_max = 0.07 * s
	var gradient := Gradient.new()
	gradient.add_point(0.0, primary)
	gradient.add_point(0.6, secondary)
	gradient.add_point(1.0, Color(secondary, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	mat.color_ramp = tex
	spray.process_material = mat
	spray.draw_pass_1 = QuadMesh.new()
	parent.add_child(spray)
	spray.global_position = pos
	var n := normal.normalized()
	if n.length_squared() > 0.5 and absf(n.dot(Vector3.UP)) < 0.99:
		spray.global_transform.basis = Basis(Quaternion(Vector3.UP, n))
	parent.get_tree().create_timer(SPRAY_TIME + 0.3).timeout.connect(spray.queue_free)


static func _light_pulse(parent: Node, pos: Vector3, tint: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = tint
	light.light_energy = 3.5
	light.omni_range = 2.2
	light.omni_attenuation = 1.6
	parent.add_child(light)
	light.global_position = pos
	var tw := light.create_tween()
	tw.tween_property(light, "light_energy", 0.0, LIGHT_TIME).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_callback(light.queue_free)


# Light tick on every player controller — "that connected", felt not seen.
static func _haptic_tick(parent: Node) -> void:
	var tree := parent.get_tree()
	if tree == null:
		return
	for origin in tree.get_nodes_in_group("xr_origin"):
		for child in origin.get_children():
			if child is XRController3D:
				(child as XRController3D).trigger_haptic_pulse("haptic", 0.0, HAPTIC[0], HAPTIC[1], 0.0)
