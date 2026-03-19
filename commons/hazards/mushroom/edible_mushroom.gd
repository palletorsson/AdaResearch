# @identity
# essence: eat(mushroom) -> alter_perception() -- pickable mushroom that rewrites sensory state
# desire: a small organic form that dissolves when consumed, triggering perceptual transformation
# critical_parameter: _dissolve_timer -- how quickly it vanishes after eating; effects depend on type
# triggers: XRToolsPickable grab -> bring to face -> consume; dissolve animation; perception shift
# emerges: the boundary between pickup and hazard dissolves -- medicine and poison share the same form
# needs: XRToolsPickable [has]; dissolve animation [has]; mesh scaling [has]; VR grab interaction [has]
# relationships: paired with stick_tool and becoming_catalyst as inventory items; Q-FEP dual-nature
# truth: the mushroom is the same form whether it heals or harms -- context determines outcome.

# edible_mushroom.gd
# A mushroom the player can pick up and eat.
# Extends XRToolsPickable so XR Tools' FunctionPickup can grab it.
#
# Eating detection:
#   - VR: When held, checks distance from mushroom to XRCamera3D (head).
#         If within `eat_distance`, the mushroom is consumed.
#   - Desktop: Press 'E' while holding the mushroom (via debug/demo).
#
# On consumption:
#   - Finds or creates a MushroomEffect in the scene
#   - Calls effect.trigger()
#   - Mushroom dissolves (shrinks + fades) and is freed
extends XRToolsPickable
class_name EdibleMushroom

# ── Configuration ─────────────────────────────────────────────────────────
@export var eat_distance: float = 0.25        ## How close to head to trigger eating
@export var mushroom_type: int = 0            ## Visual variant (0-4)
@export var mushroom_scale: float = 1.0       ## Size multiplier
@export var cap_color: Color = Color(0.8, 0.2, 0.2)  ## Red cap default
@export var stem_color: Color = Color(0.9, 0.85, 0.75)
@export var glow_color: Color = Color(0.0, 0.0, 0.0)  ## Non-zero = glowing mushroom
@export var glow_energy: float = 0.8
@export var effect_shader_path: String = "res://commons/resourses/shaders/mushroom_trip.gdshader"  ## Which post-processing effect
@export var effect_duration: float = 10.0     ## How long the effect lasts (seconds)

# ── State ─────────────────────────────────────────────────────────────────
var _is_eaten: bool = false
var _dissolve_timer: float = 0.0
var _held: bool = false
var _original_scale: Vector3 = Vector3.ONE

# ── References ────────────────────────────────────────────────────────────
var _mesh_root: Node3D = null
var _cap: MeshInstance3D = null
var _stem: MeshInstance3D = null

func _ready() -> void:
	super()

	_build_mushroom()
	_setup_collision()

	add_to_group("mushroom")
	add_to_group("edible")

	picked_up.connect(_on_picked_up)
	dropped.connect(_on_dropped)

	_original_scale = Vector3.ONE * mushroom_scale
	scale = _original_scale

	print("[EdibleMushroom] Ready — pick up and bring to face to eat")

func _process(delta: float) -> void:
	if _is_eaten:
		# Dissolve animation
		_dissolve_timer += delta
		var t: float = _dissolve_timer / 0.5  # 0.5 sec dissolve
		if t >= 1.0:
			queue_free()
			return
		# Shrink and spin
		scale = _original_scale * (1.0 - t)
		rotation.y += delta * 10.0
		return

	if not _held:
		return

	# Check distance to head (VR camera)
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera:
		var head_pos: Vector3 = camera.global_position
		var mushroom_pos: Vector3 = global_position
		var dist: float = head_pos.distance_to(mushroom_pos)

		if dist < eat_distance:
			_eat()

func _on_picked_up(_pickable) -> void:
	_held = true

func _on_dropped(_pickable) -> void:
	_held = false

# ═══════════════════════════════════════════════════════════════════════════
# EATING
# ═══════════════════════════════════════════════════════════════════════════

func _eat() -> void:
	if _is_eaten:
		return
	_is_eaten = true

	# Drop from hand
	if is_picked_up():
		var holder: Node3D = get_picked_up_by()
		if holder:
			let_go(holder, Vector3.ZERO, Vector3.ZERO)
		else:
			let_go(self, Vector3.ZERO, Vector3.ZERO)

	# Disable physics
	freeze = true
	if has_node("MushroomCollision"):
		$MushroomCollision.disabled = true

	# Find or create the effect manager
	var effect: MushroomEffect = _find_or_create_effect()
	if effect:
		effect.trigger_with_shader(effect_shader_path, effect_duration)

	print("[EdibleMushroom] Eaten! Triggering effect: %s (%.0fs)" % [
		effect_shader_path.get_file(), effect_duration])

func _find_or_create_effect() -> MushroomEffect:
	# Look for existing MushroomEffect in the scene
	var existing: Node = get_tree().get_first_node_in_group("mushroom_effect")
	if existing and existing is MushroomEffect:
		return existing as MushroomEffect

	# Search by class
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		for child in scene_root.get_children():
			if child is MushroomEffect:
				return child as MushroomEffect

	# Create one
	var effect := MushroomEffect.new()
	effect.name = "MushroomEffect"
	effect.add_to_group("mushroom_effect")
	if scene_root:
		scene_root.add_child(effect)
	else:
		get_parent().add_child(effect)

	return effect

# ═══════════════════════════════════════════════════════════════════════════
# VISUAL CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════

func _build_mushroom() -> void:
	_mesh_root = Node3D.new()
	_mesh_root.name = "MeshRoot"
	add_child(_mesh_root)

	# Stem
	_stem = MeshInstance3D.new()
	_stem.name = "Stem"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.02
	cyl.height = 0.12
	cyl.radial_segments = 8
	_stem.mesh = cyl
	_stem.position.y = 0.06

	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = stem_color
	stem_mat.roughness = 0.8
	if glow_color != Color(0, 0, 0):
		stem_mat.emission_enabled = true
		stem_mat.emission = glow_color
		stem_mat.emission_energy_multiplier = glow_energy * 0.3
	_stem.material_override = stem_mat
	_mesh_root.add_child(_stem)

	# Cap
	_cap = MeshInstance3D.new()
	_cap.name = "Cap"
	var dome := SphereMesh.new()
	dome.radius = 0.06
	dome.height = 0.08
	dome.radial_segments = 16
	dome.rings = 8
	_cap.mesh = dome
	_cap.scale.y = 0.5
	_cap.position.y = 0.12

	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = cap_color
	cap_mat.roughness = 0.6
	if glow_color != Color(0, 0, 0):
		cap_mat.emission_enabled = true
		cap_mat.emission = glow_color
		cap_mat.emission_energy_multiplier = glow_energy
	_cap.material_override = cap_mat
	_mesh_root.add_child(_cap)

	# Spots on cap (classic toadstool look)
	_add_spots()

	# Glow light if glowing
	if glow_color != Color(0, 0, 0):
		var light := OmniLight3D.new()
		light.name = "GlowLight"
		light.light_color = glow_color
		light.light_energy = glow_energy
		light.omni_range = 0.8
		light.position.y = 0.14
		_mesh_root.add_child(light)

func _add_spots() -> void:
	var spot_count: int = 5
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cap_color) + mushroom_type

	for i in range(spot_count):
		var spot := MeshInstance3D.new()
		spot.name = "Spot_%d" % i
		var sphere := SphereMesh.new()
		sphere.radius = 0.008 + rng.randf() * 0.008
		sphere.height = sphere.radius * 2.0
		spot.mesh = sphere

		# Position on cap surface
		var angle: float = rng.randf() * TAU
		var r: float = rng.randf_range(0.01, 0.04)
		spot.position = Vector3(
			cos(angle) * r,
			0.13 + rng.randf() * 0.015,
			sin(angle) * r
		)

		var spot_mat := StandardMaterial3D.new()
		spot_mat.albedo_color = Color(0.95, 0.95, 0.9)
		spot.material_override = spot_mat
		_mesh_root.add_child(spot)

func _setup_collision() -> void:
	# Capsule collision for grabbing
	var col := CollisionShape3D.new()
	col.name = "MushroomCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.06
	capsule.height = 0.16
	col.shape = capsule
	col.position.y = 0.08
	add_child(col)

	# Collision layer 3 (pickable) for XR Tools
	collision_layer = 0b0000_0000_0000_0000_0000_0000_0000_0100
	collision_mask = 1  # Collide with world
