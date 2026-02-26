# CatalystVisual.gd
# Builds and evolves the procedural mesh of The Becoming Catalyst.
# Each unlocked mode adds to the visual identity — the weapon grows.
#
# Tier 0: Simple octahedron crystal, translucent, faint glow
# Tier 1: Crystal elongates, asymmetric
# Tier 2: Rainbow emission pulses
# Tier 3: Warm orbiting particle ring
# Tier 4: Surface undulation
# Tier 5: Irregular/organic vertices
# Tier 6: Sub-crystal fractals
# Tier 7: Grid etch pattern
# Tier 8: Organic tendrils
# Tier 9: Orbiting satellite spheres
class_name CatalystVisual
extends RefCounted

# Mode colors for visual identity
const MODE_COLORS := {
	"primitives":     Color(0.85, 0.85, 0.9),
	"transformation": Color(0.7, 0.3, 0.85),
	"chromatic":      Color(1.0, 0.4, 0.4),  # Will cycle
	"forces":         Color(1.0, 0.75, 0.3),
	"waveform":       Color(0.3, 0.85, 0.85),
	"chaos":          Color(0.9, 0.2, 0.5),
	"fractal":        Color(0.4, 0.7, 1.0),
	"cellular":       Color(0.95, 0.95, 0.95),
	"branching":      Color(0.4, 0.75, 0.3),
	"swarm":          Color(1.0, 0.85, 0.4),
}

static func build_crystal(parent: Node3D, unlocked_modes: Array[String]) -> void:
	# Clear previous visual
	for child in parent.get_children():
		if child.is_in_group("catalyst_visual"):
			child.queue_free()

	var tier := unlocked_modes.size() - 1  # 0-based

	# Base crystal — octahedron (two pyramids)
	var crystal := _build_octahedron(tier)
	crystal.add_to_group("catalyst_visual")
	parent.add_child(crystal)

	# Tier 2+: Rainbow emission particles
	if tier >= 2:
		var rainbow := _build_rainbow_aura()
		rainbow.add_to_group("catalyst_visual")
		parent.add_child(rainbow)

	# Tier 3+: Orbiting ring
	if tier >= 3:
		var ring := _build_orbit_ring()
		ring.add_to_group("catalyst_visual")
		parent.add_child(ring)

	# Tier 6+: Sub-crystals on faces
	if tier >= 6:
		var subs := _build_sub_crystals()
		subs.add_to_group("catalyst_visual")
		parent.add_child(subs)

	# Tier 9+: Satellite spheres
	if tier >= 9:
		var sats := _build_satellites()
		sats.add_to_group("catalyst_visual")
		parent.add_child(sats)


static func get_mode_color(mode_id: String) -> Color:
	return MODE_COLORS.get(mode_id, Color.WHITE)


# ═════════════════════════════════════════════════════════════════════════
# BUILDERS
# ═════════════════════════════════════════════════════════════════════════

static func _build_octahedron(tier: int) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "CrystalCore"

	# Use a sphere with very few segments → faceted crystal look
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.22 if tier >= 1 else 0.16  # Elongate at tier 1+
	sphere.radial_segments = 6
	sphere.rings = 4
	mesh_instance.mesh = sphere

	# Tier 1+: Asymmetric tilt
	if tier >= 1:
		mesh_instance.rotation.z = 0.15

	# Tier 5+: Random offset for organic feel
	if tier >= 5:
		mesh_instance.rotation.x = randf_range(-0.1, 0.1)
		mesh_instance.rotation.y = randf_range(-0.2, 0.2)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.8, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.8, 0.8, 0.95)
	mat.emission_energy_multiplier = 1.2 + tier * 0.15
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.25
	mat.rim_enabled = tier >= 2  # Rainbow rim at tier 2+
	if tier >= 2:
		mat.rim = 0.6
		mat.rim_tint = 0.3
	mesh_instance.material_override = mat

	return mesh_instance


static func _build_rainbow_aura() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "RainbowAura"
	particles.amount = 16
	particles.lifetime = 1.5
	particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.1
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 0.02
	mat.initial_velocity_max = 0.08
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.01
	mat.scale_max = 0.03

	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1, 0.3, 0.3, 0.8))
	gradient.add_point(0.25, Color(1, 0.8, 0.2, 0.7))
	gradient.add_point(0.5, Color(0.3, 1, 0.3, 0.6))
	gradient.add_point(0.75, Color(0.3, 0.5, 1, 0.5))
	gradient.add_point(1.0, Color(0.7, 0.3, 1, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	mat.color_ramp = tex

	particles.process_material = mat
	particles.draw_pass_1 = QuadMesh.new()
	return particles


static func _build_orbit_ring() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "OrbitRing"
	particles.amount = 24
	particles.lifetime = 2.0
	particles.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 0.12
	mat.emission_ring_inner_radius = 0.11
	mat.emission_ring_height = 0.005
	mat.emission_ring_axis = Vector3(0, 1, 0)
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 0.0
	mat.initial_velocity_min = 0.15
	mat.initial_velocity_max = 0.2
	mat.gravity = Vector3.ZERO
	mat.orbit_velocity_min = 0.8
	mat.orbit_velocity_max = 1.0
	mat.scale_min = 0.008
	mat.scale_max = 0.015

	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(1, 0.75, 0.3, 0.9))
	gradient.add_point(1.0, Color(1, 0.6, 0.2, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	mat.color_ramp = tex

	particles.process_material = mat
	particles.draw_pass_1 = QuadMesh.new()
	return particles


static func _build_sub_crystals() -> Node3D:
	var container := Node3D.new()
	container.name = "SubCrystals"

	var offsets := [
		Vector3(0.1, 0.05, 0),
		Vector3(-0.08, -0.04, 0.06),
		Vector3(0.03, 0.08, -0.07),
	]

	for offset in offsets:
		var sub := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.025
		sphere.height = 0.06
		sphere.radial_segments = 4
		sphere.rings = 2
		sub.mesh = sphere
		sub.position = offset

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.5, 0.6, 0.9, 0.7)
		mat.emission_enabled = true
		mat.emission = Color(0.6, 0.7, 1.0)
		mat.emission_energy_multiplier = 1.5
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sub.material_override = mat
		container.add_child(sub)

	return container


static func _build_satellites() -> Node3D:
	var container := Node3D.new()
	container.name = "Satellites"

	for i in 5:
		var sat := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.012
		sphere.height = 0.024
		sat.mesh = sphere
		# Distribute around the crystal
		var angle := (TAU / 5.0) * i
		sat.position = Vector3(cos(angle) * 0.15, sin(angle * 0.7) * 0.06, sin(angle) * 0.15)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0.85, 0.4, 0.9)
		mat.emission_enabled = true
		mat.emission = Color(1, 0.9, 0.5)
		mat.emission_energy_multiplier = 2.0
		sat.material_override = mat
		container.add_child(sat)

	return container
