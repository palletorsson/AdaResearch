# DangerZone.gd
# Hazard volume that damages players on contact
# Supports multiple danger types with unique visuals/audio

extends Area3D
class_name DangerZone

enum Type { 
	FIRE,       # Burning - damage ramps with heat
	VACUUM,     # Suffocation - oxygen depletion
	ELECTRIC,   # Shock pulses - periodic bursts
	TOXIC,      # Poison - lingers after exit
	RADIATION,  # Invisible - Geiger warning
	GENERIC     # Basic damage
}

@export var danger_type: Type = Type.GENERIC
@export var damage_per_tick: float = 10.0
@export var tick_interval: float = 0.5

# Fire: light damage (1%) with cooldown
const FIRE_DAMAGE_PER_TICK := 10.0
const FIRE_TICK_INTERVAL := 2.0
@export var instant_kill: bool = false  ## Dumb ways to die
## Flash the screen red on every damage tick. See _flash_screen.
@export var flash_on_damage: bool = true

# Type-specific configuration
const TYPE_CONFIG = {
	Type.FIRE: {
		"color": Color(1.0, 0.4, 0.0, 0.4),
		"emission_color": Color(1.0, 0.3, 0.0),
		"description": "Fire hazard"
	},
	Type.VACUUM: {
		"color": Color(0.1, 0.1, 0.3, 0.3),
		"emission_color": Color(0.2, 0.2, 0.5),
		"description": "Vacuum hazard"
	},
	Type.ELECTRIC: {
		"color": Color(0.0, 0.8, 1.0, 0.4),
		"emission_color": Color(0.3, 0.9, 1.0),
		"description": "Electric hazard"
	},
	Type.TOXIC: {
		"color": Color(0.2, 0.8, 0.2, 0.4),
		"emission_color": Color(0.3, 1.0, 0.3),
		"description": "Toxic hazard"
	},
	Type.RADIATION: {
		"color": Color(1.0, 1.0, 0.0, 0.2),
		"emission_color": Color(1.0, 1.0, 0.3),
		"description": "Radiation hazard"
	},
	Type.GENERIC: {
		"color": Color(0.8, 0.0, 0.0, 0.4),
		"emission_color": Color(1.0, 0.2, 0.2),
		"description": "Danger zone"
	}
}

var player_inside: bool = false
var damage_timer: float = 0.0
var config: Dictionary

# Type-specific state
var heat_level: float = 0.0  # Fire
var oxygen_level: float = 100.0  # Vacuum
var pulse_timer: float = 0.0  # Electric

# Chromatic NEUTRALIZER (catalyst friend power): while a live FRIEND foe of
# the "chromatic" lineage stands inside this zone, per-tick damage is muted
# and the zone's light/particles dim. instant_kill zones (h:death) are NEVER
# muted — death is not negotiable. Zero-cost when no such friend exists.
const NEUTRALIZE_SCAN_INTERVAL := 0.25
var _neutralized: bool = false
var _neutralize_scan_timer: float = 0.0

# Visual nodes (created dynamically)
var zone_mesh: MeshInstance3D
var warning_label: Label3D
var ambient_audio: AudioStreamPlayer3D

signal player_entered_danger(danger_type: Type)
signal player_exited_danger(danger_type: Type)
signal damage_dealt(amount: float, danger_type: Type)

func _ready() -> void:
	print("[DangerZone] _ready() called - type: %s, position: %s" % [Type.keys()[danger_type], global_position])
	config = TYPE_CONFIG.get(danger_type, TYPE_CONFIG[Type.GENERIC])
	add_to_group("danger_zone")  # world-power systems (neutralizer, bridger tendril) find zones via this group

	# Fire burns fast — ~1 second to kill from full health
	if danger_type == Type.FIRE:
		damage_per_tick = FIRE_DAMAGE_PER_TICK
		tick_interval = FIRE_TICK_INTERVAL

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_setup_collision()
	_setup_visuals()
	_setup_audio()
	print("[DangerZone] Setup complete")

func _setup_collision() -> void:
	# Ensure we have monitoring enabled - match subtitle_trigger settings
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 524288  # Layer 20 - player body (same as subtitle_trigger)

var _zone_light: OmniLight3D = null
var _zone_particles: GPUParticles3D = null
var _zone_mat: StandardMaterial3D = null
var _arc_timer: float = 0.0
var _arc_meshes: Array[MeshInstance3D] = []

func _setup_visuals() -> void:
	var collision_shape = get_node_or_null("CollisionShape3D")
	if not collision_shape:
		return

	match danger_type:
		Type.FIRE:
			_build_fire_visuals(collision_shape)
		Type.ELECTRIC:
			_build_electric_visuals(collision_shape)
		Type.TOXIC:
			_build_toxic_visuals(collision_shape)
		Type.VACUUM:
			_build_vacuum_visuals(collision_shape)
		_:
			_build_death_visuals(collision_shape)


func _build_fire_visuals(col: CollisionShape3D) -> void:
	# Orange glowing box + rising flame particles + pulsing light
	zone_mesh = MeshInstance3D.new()
	zone_mesh.name = "FireMesh"
	var box := BoxMesh.new()
	box.size = Vector3(1, 0.3, 1)
	zone_mesh.mesh = box
	_zone_mat = _make_zone_mat(Color(1.0, 0.4, 0.0, 0.3), Color(1.0, 0.3, 0.0), 1.5)
	zone_mesh.material_override = _zone_mat
	zone_mesh.position = col.position
	add_child(zone_mesh)

	# Fire particles rising
	_zone_particles = GPUParticles3D.new()
	_zone_particles.name = "FireParticles"
	_zone_particles.amount = 30
	_zone_particles.lifetime = 1.2
	_zone_particles.position = col.position
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 30.0
	pmat.initial_velocity_min = 0.5
	pmat.initial_velocity_max = 1.5
	pmat.gravity = Vector3(0, 0.2, 0)
	pmat.scale_min = 0.03
	pmat.scale_max = 0.08
	pmat.color = Color(1.0, 0.5, 0.1)
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.6, 0.1, 1.0))
	grad.add_point(0.5, Color(1.0, 0.2, 0.0, 0.8))
	grad.add_point(1.0, Color(0.3, 0.05, 0.0, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pmat.color_ramp = gt
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(0.4, 0.05, 0.4)
	_zone_particles.process_material = pmat
	_zone_particles.draw_pass_1 = SphereMesh.new()
	(_zone_particles.draw_pass_1 as SphereMesh).radius = 0.04
	(_zone_particles.draw_pass_1 as SphereMesh).height = 0.08
	add_child(_zone_particles)

	_zone_light = _make_light(Color(1.0, 0.4, 0.0), 1.5, 2.0, col.position + Vector3(0, 0.5, 0))


func _build_electric_visuals(col: CollisionShape3D) -> void:
	# Cyan tesla sphere + spark particles + flickering light
	zone_mesh = MeshInstance3D.new()
	zone_mesh.name = "TeslaSphere"
	var sphere := SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	sphere.radial_segments = 16
	sphere.rings = 8
	zone_mesh.mesh = sphere
	_zone_mat = _make_zone_mat(Color(0.0, 0.8, 1.0, 0.15), Color(0.3, 0.9, 1.0), 3.0)
	zone_mesh.material_override = _zone_mat
	zone_mesh.position = col.position + Vector3(0, 0.4, 0)
	add_child(zone_mesh)

	# Spark particles — short bursts outward
	_zone_particles = GPUParticles3D.new()
	_zone_particles.name = "SparkParticles"
	_zone_particles.amount = 20
	_zone_particles.lifetime = 0.25
	_zone_particles.explosiveness = 0.8
	_zone_particles.position = col.position + Vector3(0, 0.4, 0)
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 2.0
	pmat.initial_velocity_max = 5.0
	pmat.gravity = Vector3.ZERO
	pmat.damping_min = 5.0
	pmat.damping_max = 10.0
	pmat.scale_min = 0.01
	pmat.scale_max = 0.03
	pmat.color = Color(0.5, 0.9, 1.0)
	_zone_particles.process_material = pmat
	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(0.02, 0.002, 0.002)
	_zone_particles.draw_pass_1 = spark_mesh
	var spark_mat := StandardMaterial3D.new()
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(0.3, 0.9, 1.0)
	spark_mat.emission_energy_multiplier = 5.0
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_zone_particles.material_override = spark_mat
	add_child(_zone_particles)

	_zone_light = _make_light(Color(0.2, 0.7, 1.0), 2.0, 2.5, col.position + Vector3(0, 0.5, 0))


func _build_toxic_visuals(col: CollisionShape3D) -> void:
	# Green slime floor + rising vapor particles
	zone_mesh = MeshInstance3D.new()
	zone_mesh.name = "ToxicFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.0, 1.0)
	plane.subdivide_depth = 4
	plane.subdivide_width = 4
	zone_mesh.mesh = plane
	# Try slime shader, fallback to standard material
	var slime_shader = load("res://commons/resourses/shaders/slime.gdshader")
	if slime_shader:
		var smat := ShaderMaterial.new()
		smat.shader = slime_shader
		smat.set_shader_parameter("albedo", Color(0.15, 0.6, 0.1))
		smat.set_shader_parameter("emission_color", Color(0.2, 0.8, 0.2))
		zone_mesh.material_override = smat
	else:
		_zone_mat = _make_zone_mat(Color(0.2, 0.7, 0.2, 0.5), Color(0.3, 1.0, 0.3), 1.0)
		zone_mesh.material_override = _zone_mat
	zone_mesh.position = col.position + Vector3(0, 0.01, 0)
	add_child(zone_mesh)

	# Rising toxic vapor
	_zone_particles = GPUParticles3D.new()
	_zone_particles.name = "ToxicVapor"
	_zone_particles.amount = 40
	_zone_particles.lifetime = 3.0
	_zone_particles.position = col.position
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 20.0
	pmat.initial_velocity_min = 0.1
	pmat.initial_velocity_max = 0.3
	pmat.gravity = Vector3(0, 0.05, 0)
	pmat.scale_min = 0.05
	pmat.scale_max = 0.15
	pmat.color = Color(0.2, 0.8, 0.1, 0.3)
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(0.4, 0.01, 0.4)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.2, 0.8, 0.1, 0.4))
	grad.add_point(0.5, Color(0.15, 0.6, 0.1, 0.2))
	grad.add_point(1.0, Color(0.1, 0.4, 0.05, 0.0))
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pmat.color_ramp = gt
	_zone_particles.process_material = pmat
	_zone_particles.draw_pass_1 = SphereMesh.new()
	(_zone_particles.draw_pass_1 as SphereMesh).radius = 0.06
	(_zone_particles.draw_pass_1 as SphereMesh).height = 0.12
	var vap_mat := StandardMaterial3D.new()
	vap_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vap_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vap_mat.vertex_color_use_as_albedo = true
	_zone_particles.material_override = vap_mat
	add_child(_zone_particles)

	_zone_light = _make_light(Color(0.2, 0.6, 0.1), 0.8, 1.5, col.position + Vector3(0, 0.3, 0))


func _build_vacuum_visuals(col: CollisionShape3D) -> void:
	# Blue pressure sphere + inward-pulling particles + pulsing
	zone_mesh = MeshInstance3D.new()
	zone_mesh.name = "VacuumSphere"
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	sphere.radial_segments = 16
	sphere.rings = 8
	zone_mesh.mesh = sphere
	# Fresnel-like: bright at edges, transparent at center
	_zone_mat = StandardMaterial3D.new()
	_zone_mat.albedo_color = Color(0.1, 0.1, 0.3, 0.1)
	_zone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_zone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_zone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_zone_mat.emission_enabled = true
	_zone_mat.emission = Color(0.15, 0.2, 0.5)
	_zone_mat.emission_energy_multiplier = 1.5
	_zone_mat.rim_enabled = true
	_zone_mat.rim = 1.0
	_zone_mat.rim_tint = 0.8
	zone_mesh.material_override = _zone_mat
	zone_mesh.position = col.position + Vector3(0, 0.4, 0)
	add_child(zone_mesh)

	# Inward-pulling particles (negative initial velocity = suction)
	_zone_particles = GPUParticles3D.new()
	_zone_particles.name = "VacuumPull"
	_zone_particles.amount = 25
	_zone_particles.lifetime = 1.5
	_zone_particles.position = col.position + Vector3(0, 0.4, 0)
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 0, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = -1.5
	pmat.initial_velocity_max = -0.5
	pmat.gravity = Vector3.ZERO
	pmat.scale_min = 0.01
	pmat.scale_max = 0.04
	pmat.color = Color(0.3, 0.4, 0.9, 0.5)
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmat.emission_sphere_radius = 0.6
	_zone_particles.process_material = pmat
	_zone_particles.draw_pass_1 = SphereMesh.new()
	(_zone_particles.draw_pass_1 as SphereMesh).radius = 0.02
	(_zone_particles.draw_pass_1 as SphereMesh).height = 0.04
	var vac_mat := StandardMaterial3D.new()
	vac_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vac_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vac_mat.vertex_color_use_as_albedo = true
	_zone_particles.material_override = vac_mat
	add_child(_zone_particles)

	_zone_light = _make_light(Color(0.15, 0.2, 0.6), 1.0, 2.0, col.position + Vector3(0, 0.4, 0))


func _build_death_visuals(col: CollisionShape3D) -> void:
	# Red cross/X shape — instant death marker
	var cross_mat := _make_zone_mat(Color(0.8, 0.0, 0.0, 0.6), Color(1.0, 0.1, 0.1), 2.0)
	# Vertical bar
	var v_bar := MeshInstance3D.new()
	v_bar.name = "DeathCrossV"
	var vb := BoxMesh.new()
	vb.size = Vector3(0.1, 0.8, 0.1)
	v_bar.mesh = vb
	v_bar.material_override = cross_mat
	v_bar.position = col.position + Vector3(0, 0.4, 0)
	add_child(v_bar)
	# Horizontal bar
	var h_bar := MeshInstance3D.new()
	h_bar.name = "DeathCrossH"
	var hb := BoxMesh.new()
	hb.size = Vector3(0.6, 0.1, 0.1)
	h_bar.mesh = hb
	h_bar.material_override = cross_mat
	h_bar.position = col.position + Vector3(0, 0.5, 0)
	add_child(h_bar)
	zone_mesh = v_bar
	_zone_light = _make_light(Color(0.8, 0.1, 0.1), 1.5, 1.5, col.position + Vector3(0, 0.5, 0))


func _make_zone_mat(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = energy
	return mat


func _make_light(color: Color, energy: float, range_m: float, pos: Vector3) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "ZoneLight"
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_m
	light.omni_attenuation = 1.5
	light.position = pos
	add_child(light)
	return light

func _setup_audio() -> void:
	ambient_audio = AudioStreamPlayer3D.new()
	ambient_audio.name = "AmbientAudio"
	ambient_audio.max_distance = 15.0
	ambient_audio.unit_size = 3.0
	add_child(ambient_audio)
	# TODO: Load type-specific ambient sounds

func _process(delta: float) -> void:
	# Neutralizer power: rescan for a chromatic friend on a slow cadence.
	# One group scan per interval — cached in _neutralized, never per body.
	_neutralize_scan_timer += delta
	if _neutralize_scan_timer >= NEUTRALIZE_SCAN_INTERVAL:
		_neutralize_scan_timer = 0.0
		_set_neutralized(_scan_for_chroma_friend())

	# Animate visuals (always, even when player not inside)
	_animate_visuals(delta)

	if not player_inside:
		heat_level = max(0.0, heat_level - delta)
		oxygen_level = min(100.0, oxygen_level + delta * 20.0)
		return

	# Type-specific damage processing
	match danger_type:
		Type.FIRE:
			_process_fire(delta)
		Type.VACUUM:
			_process_vacuum(delta)
		Type.ELECTRIC:
			_process_electric(delta)
		Type.TOXIC:
			_process_toxic(delta)
		Type.RADIATION:
			_process_radiation(delta)
		Type.GENERIC:
			_process_generic(delta)

func _animate_visuals(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	# Neutralized zones glow faint — the mute is visible, restored on exit
	var mute: float = 0.15 if _neutralized else 1.0

	match danger_type:
		Type.FIRE:
			# Pulsing fire glow
			if _zone_light:
				_zone_light.light_energy = (1.5 + sin(t * 6.0) * 0.5) * mute
			if _zone_mat:
				_zone_mat.emission_energy_multiplier = (1.5 + sin(t * 4.0) * 0.5) * mute

		Type.ELECTRIC:
			# Rapid flickering tesla sphere
			if _zone_light:
				_zone_light.light_energy = (1.0 + randf() * 3.0) * mute
			if _zone_mat:
				_zone_mat.emission_energy_multiplier = (2.0 + randf() * 2.0) * mute
				_zone_mat.albedo_color.a = 0.1 + randf() * 0.15

		Type.VACUUM:
			# Slow breathing pulse
			if zone_mesh:
				var pulse := 1.0 + sin(t * 1.5) * 0.1
				zone_mesh.scale = Vector3(pulse, pulse, pulse)
			if _zone_light:
				_zone_light.light_energy = (0.8 + sin(t * 1.5) * 0.3) * mute

		Type.TOXIC:
			# Gentle light pulse
			if _zone_light:
				_zone_light.light_energy = (0.6 + sin(t * 2.0) * 0.2) * mute


func _process_generic(delta: float) -> void:
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_deal_damage(damage_per_tick)

func _process_fire(delta: float) -> void:
	# Heat accumulates, damage increases
	heat_level = min(heat_level + delta * 0.5, 3.0)
	
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		var heat_multiplier = 1.0 + heat_level
		_deal_damage(damage_per_tick * heat_multiplier)

func _process_vacuum(delta: float) -> void:
	# Oxygen depletes, damage starts when low
	oxygen_level = max(0.0, oxygen_level - delta * 15.0)
	
	if oxygen_level < 50.0:
		damage_timer += delta
		if damage_timer >= tick_interval:
			damage_timer = 0.0
			var severity = 1.0 - (oxygen_level / 50.0)
			_deal_damage(damage_per_tick * severity)

func _process_electric(delta: float) -> void:
	# Periodic shock pulses
	pulse_timer += delta
	if pulse_timer >= 1.5:  # Shock every 1.5 seconds
		pulse_timer = 0.0
		_deal_damage(damage_per_tick * 2.0)
		_flash_screen(Color.CYAN)

func _process_toxic(delta: float) -> void:
	# Standard tick damage, poison effect handled separately
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_deal_damage(damage_per_tick * 0.7)
		# TODO: Apply poison status effect

func _process_radiation(delta: float) -> void:
	# Slow constant damage, Geiger clicks
	damage_timer += delta
	if damage_timer >= tick_interval:
		damage_timer = 0.0
		_deal_damage(damage_per_tick * 0.5)
		# TODO: Geiger click sound

func _on_body_entered(body: Node3D) -> void:
	if not _is_player(body):
		return
	
	print("[DangerZone] Player entered! Type: %s" % Type.keys()[danger_type])
	player_inside = true
	damage_timer = 0.0
	player_entered_danger.emit(danger_type)
	
	if instant_kill:
		_instant_kill()
	else:
		# Immediate first tick
		_deal_damage(damage_per_tick * 0.5)

func _on_body_exited(body: Node3D) -> void:
	if not _is_player(body):
		return
	
	print("[DangerZone] Player exited")
	player_inside = false
	player_exited_danger.emit(danger_type)

func _is_player(body: Node3D) -> bool:
	if body.is_in_group("player"):
		return true
	if body.is_in_group("player_body"):
		return true
	if body.name.contains("Player") or body.name.contains("XR"):
		return true
	return false

func _deal_damage(amount: float) -> void:
	# NEUTRALIZER: a chromatic friend inside the zone mutes per-tick damage.
	# instant_kill never routes through here (see _instant_kill) — death is
	# not negotiable.
	if _neutralized:
		return

	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("apply_health_damage"):
		game_manager.apply_health_damage(amount)

	# SAY SO. A hazard that drains health invisibly is a bug in every hazard, not
	# just this one, so the flash is on by default rather than opt-in — but it is
	# an export, because a designer may want one zone to take from you quietly.
	if flash_on_damage:
		_flash_screen(Color.RED)

	_play_pain_sound()
	damage_dealt.emit(amount, danger_type)

func _instant_kill() -> void:
	# Deliberately NOT gated on _neutralized — h:death cannot be muted.
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_health"):
		game_manager.set_health(0.0)

# ============================================================================
# CHROMATIC NEUTRALIZER (catalyst friend power)
# ============================================================================

func _scan_for_chroma_friend() -> bool:
	# True when a live FRIEND catalyst_foe of the chromatic lineage stands
	# inside this zone. Cheap no-op when the group is empty.
	var foes = get_tree().get_nodes_in_group("catalyst_foe")
	if foes.is_empty():
		return false

	var center: Vector3 = global_position
	var col: CollisionShape3D = _find_zone_shape()
	if col:
		center = col.global_position
	var radius: float = _effective_radius()

	for foe in foes:
		if not is_instance_valid(foe) or not (foe is Node3D):
			continue
		if not ("_personality" in foe) or String(foe.get("_personality")) != "friend":
			continue
		if not ("_locked_mode_id" in foe) or String(foe.get("_locked_mode_id")) != "chromatic":
			continue
		if (foe as Node3D).global_position.distance_to(center) <= radius:
			return true
	return false

func _set_neutralized(muted: bool) -> void:
	if muted == _neutralized:
		return
	_neutralized = muted
	# Cheap visual: particles off while muted; animated lights dim via the
	# mute factor in _animate_visuals. Non-animated types dim directly here.
	if _zone_particles and is_instance_valid(_zone_particles):
		_zone_particles.emitting = not muted
	if _zone_light and is_instance_valid(_zone_light):
		match danger_type:
			Type.GENERIC, Type.RADIATION:
				_zone_light.light_energy = 0.2 if muted else 1.5
			_:
				pass  # handled per-frame in _animate_visuals

func _find_zone_shape() -> CollisionShape3D:
	var col = get_node_or_null("CollisionShape3D")
	if col and col is CollisionShape3D:
		return col
	for child in get_children():
		if child is CollisionShape3D:
			return child
	return null

func _effective_radius() -> float:
	# Derive the zone's reach from its collision shape; safe fallback of 1m.
	var col: CollisionShape3D = _find_zone_shape()
	if col and col.shape:
		var shape: Shape3D = col.shape
		if shape is BoxShape3D:
			var s: Vector3 = (shape as BoxShape3D).size
			return max(s.x, max(s.y, s.z)) * 0.5
		if shape is SphereShape3D:
			return (shape as SphereShape3D).radius
		if shape is CylinderShape3D:
			var cyl: CylinderShape3D = shape as CylinderShape3D
			return max(cyl.radius, cyl.height * 0.5)
	return 1.0

## THE STUB THAT MADE EVERY HAZARD SILENT.
##
## This was `# TODO: Add screen flash effect / pass` and had been since the file
## was written, so nothing in the game ever indicated damage: health fell and the
## screen did not move. DeathEffect owns the VR-proven overlay (MushroomEffect +
## damage_flash_spatial.gdshader) and now exposes it flash-only, without hurt()'s
## teleport-to-spawn, which is why this can finally be honoured.
func _flash_screen(_color: Color) -> void:
	var fx := get_node_or_null("/root/DeathEffect")
	if fx != null and fx.has_method("damage_flash"):
		fx.call("damage_flash")

func _play_pain_sound() -> void:
	# TODO: Play pain sound from pool based on danger_type
	pass

# ============================================================================
# UTILITY SPAWNER INTEGRATION
# ============================================================================

static func create_from_notation(notation: String) -> DangerZone:
	"""Create DangerZone from utility notation like h:fire:20"""
	var parts = notation.split(":")
	if parts.size() < 2:
		return null
	
	var zone = DangerZone.new()
	var type_str = parts[1].to_lower()
	
	match type_str:
		"fire": zone.danger_type = Type.FIRE
		"vacuum": zone.danger_type = Type.VACUUM
		"electric": zone.danger_type = Type.ELECTRIC
		"toxic": zone.danger_type = Type.TOXIC
		"radiation": zone.danger_type = Type.RADIATION
		"death": zone.instant_kill = true
		_: zone.danger_type = Type.GENERIC
	
	if parts.size() >= 3:
		zone.damage_per_tick = float(parts[2])
	
	# Add default collision shape (1x1x1 cube)
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(1, 2, 1)
	zone.add_child(collision)
	
	return zone
