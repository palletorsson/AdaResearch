extends Area3D
class_name EdgeZone

# @identity
# essence: a zone dying at one of the two deaths — pure ORDER (crystallize, lambda=0) or pure CHAOS (dissolve, lambda=1) — that the player RETUNES back toward the living edge (lambda~0.4) by holding it; leave it and it drifts back to its death. The thesis-mechanic: the world keeps trying to freeze or dissolve, and you keep it alive.
# desire: to be held at the edge — not frozen, not scattered, but poised where things can still change.
# critical_parameter: lambda — 0 is the crystal (frozen, dead), 1 is the dissolve (formless, dead), ~0.4 is alive; polarity (-1 crystal / +1 dissolve) sets which death it decays toward.
# triggers: proximity retunes lambda toward ALIVE while the player stands in the outer ring; a catalyst body retunes faster; unattended, lambda drifts back to its death-extreme; harm ticks while lambda is outside the living band.
# emerges: standing with the zone brings it green and quiet; walking away lets it freeze or boil again — attention as the thing that keeps a form alive.
# needs: the two deaths visibly distinct [crystal lattice vs scattering particles]; a living band that reads as alive [green pulse]; harm at the extremes [tick]; retune-by-presence [outer ring].
# relationships: the playable face of qfeplaboratory's lambda spectrum and QFEP_Edge_Of_Chaos; harmed via the same GameManager path as [[DangerZone]]; retuned by [[becoming_catalyst]]; the game-baseline's missing world-verb made real.
# truth: both extremes are death — the perfect crystal and the pure noise fail the same way. Life is the edge held against its own drift, and holding it is the whole game.

enum Polarity { CRYSTAL = -1, DISSOLVE = 1 }

@export var polarity: Polarity = Polarity.CRYSTAL
@export var cell_size: float = 3.0            # zone footprint (world metres)
@export var retune_rate: float = 0.35         # lambda/sec toward ALIVE while held
@export var catalyst_rate: float = 0.9        # faster if a catalyst is present
@export var decay_rate: float = 0.14          # lambda/sec back toward its death when unattended
@export var damage_per_tick: float = 12.0
@export var tick_interval: float = 0.6

const ALIVE := 0.4                            # the living lambda (edge of chaos)
const ALIVE_BAND := 0.12                      # +/- around ALIVE that counts as alive
const HARM_BAND := 0.18                       # within this of a death-extreme = harming
const STABILIZE_SECONDS := 3.0                # held-alive time before it locks alive

var lambda: float = 0.0                       # set from polarity in _ready
var player_present: bool = false
var catalyst_present: bool = false
var _bodies_inside: int = 0
var _damage_timer: float = 0.0
var _alive_timer: float = 0.0
var stabilized: bool = false

# visual nodes
var _crystal_root: Node3D
var _dissolve_particles: GPUParticles3D
var _core: MeshInstance3D
var _core_mat: StandardMaterial3D
var _light: OmniLight3D
var _life_mote: MeshInstance3D

signal retuned(lambda: float)
signal became_alive()
signal reached_death()
signal stabilized_alive()

func _ready() -> void:
	_read_meta_overrides()
	lambda = 0.0 if polarity == Polarity.CRYSTAL else 1.0
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 524288          # layer 20 — player body (as DangerZone)
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(cell_size, 2.4, cell_size)   # outer ring = the whole footprint
	col.shape = box
	col.position = Vector3(0, 1.2, 0)
	add_child(col)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_visuals()
	_apply_lambda(true)

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_polarity"):
		var p := str(get_meta("config_polarity")).to_lower()
		polarity = Polarity.DISSOLVE if p in ["dissolve", "chaos", "1", "+1"] else Polarity.CRYSTAL
	if has_meta("config_cell_size"):
		cell_size = float(str(get_meta("config_cell_size")))

# ── the loop ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if stabilized:
		_animate(delta)
		return
	# retune toward ALIVE while held; else drift back to the death-extreme
	if player_present:
		var rate := catalyst_rate if catalyst_present else retune_rate
		lambda = move_toward(lambda, ALIVE, rate * delta)
	else:
		var death := 0.0 if polarity == Polarity.CRYSTAL else 1.0
		lambda = move_toward(lambda, death, decay_rate * delta)
	_apply_lambda(false)
	retuned.emit(lambda)

	# alive tracking + stabilization
	if abs(lambda - ALIVE) <= ALIVE_BAND:
		if _alive_timer == 0.0:
			became_alive.emit()
		_alive_timer += delta
		if _alive_timer >= STABILIZE_SECONDS and player_present:
			_lock_alive()
	else:
		_alive_timer = 0.0

	# harm while near a death-extreme
	var near_death: bool = lambda <= HARM_BAND or lambda >= (1.0 - HARM_BAND)
	if near_death and _bodies_inside > 0:
		_damage_timer += delta
		if _damage_timer >= tick_interval:
			_damage_timer = 0.0
			# harm scales with how deep into the death the zone is
			var dist_from_alive: float = abs(lambda - ALIVE) / max(ALIVE, 1.0 - ALIVE)
			_deal_damage(damage_per_tick * clampf(dist_from_alive, 0.3, 1.0))
			if lambda <= 0.001 or lambda >= 0.999:
				reached_death.emit()
	_animate(delta)

func _lock_alive() -> void:
	stabilized = true
	lambda = ALIVE
	_apply_lambda(true)
	stabilized_alive.emit()
	if _life_mote:
		_life_mote.visible = true

# ── retune API (for the bracelet / catalyst) ─────────────────────────────────

func retune(amount: float) -> void:
	if stabilized:
		return
	lambda = clampf(lambda + amount, 0.0, 1.0)
	_apply_lambda(false)

func is_alive() -> bool:
	return abs(lambda - ALIVE) <= ALIVE_BAND

# ── bodies ───────────────────────────────────────────────────────────────────

func _on_body_entered(body: Node3D) -> void:
	if _is_catalyst(body):
		catalyst_present = true
	if _is_player(body):
		_bodies_inside += 1
		player_present = true

func _on_body_exited(body: Node3D) -> void:
	if _is_catalyst(body):
		catalyst_present = false
	if _is_player(body):
		_bodies_inside = max(0, _bodies_inside - 1)
		player_present = _bodies_inside > 0

func _is_player(b: Node3D) -> bool:
	return b.is_in_group("player") or b.is_in_group("player_body") \
		or b.name.contains("Player") or b.name.contains("XR")

func _is_catalyst(b: Node3D) -> bool:
	return b.is_in_group("catalyst") or b.name.contains("Catalyst") or b.name.contains("catalyst")

func _deal_damage(amount: float) -> void:
	var gm := get_node_or_null("/root/GameManager")
	if gm and gm.has_method("apply_health_damage"):
		gm.apply_health_damage(amount)

# ── visuals ──────────────────────────────────────────────────────────────────

func _build_visuals() -> void:
	# CRYSTAL side: a frozen cubic lattice of cold cubes
	_crystal_root = Node3D.new()
	_crystal_root.name = "CrystalLattice"
	add_child(_crystal_root)
	var n := 3
	var step := cell_size / float(n + 1)
	for x in range(1, n + 1):
		for z in range(1, n + 1):
			var c := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.28, 0.28, 0.28)
			c.mesh = bm
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.75, 0.85, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.6, 0.8, 1.0)
			m.emission_energy_multiplier = 1.4
			c.material_override = m
			c.position = Vector3(-cell_size * 0.5 + x * step, 0.3 + (x + z) % 2 * 0.35, -cell_size * 0.5 + z * step)
			_crystal_root.add_child(c)

	# DISSOLVE side: hot scattering particles, formless
	_dissolve_particles = GPUParticles3D.new()
	_dissolve_particles.name = "Dissolve"
	_dissolve_particles.amount = 60
	_dissolve_particles.lifetime = 1.4
	_dissolve_particles.position = Vector3(0, 0.8, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(cell_size * 0.5, 0.8, cell_size * 0.5)
	pm.direction = Vector3(0, 0.2, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.8
	pm.gravity = Vector3.ZERO
	pm.scale_min = 0.03
	pm.scale_max = 0.09
	pm.color = Color(1.0, 0.2, 0.7)
	_dissolve_particles.process_material = pm
	var pmesh := SphereMesh.new()
	pmesh.radius = 0.05
	pmesh.height = 0.1
	_dissolve_particles.draw_pass_1 = pmesh
	var pmat := StandardMaterial3D.new()
	pmat.emission_enabled = true
	pmat.emission = Color(1.0, 0.25, 0.7)
	pmat.emission_energy_multiplier = 3.0
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dissolve_particles.material_override = pmat
	add_child(_dissolve_particles)

	# CORE: a floor disc whose colour reads lambda (blue crystal -> green alive -> magenta chaos)
	_core = MeshInstance3D.new()
	_core.name = "Core"
	var cyl := CylinderMesh.new()
	cyl.top_radius = cell_size * 0.5
	cyl.bottom_radius = cell_size * 0.5
	cyl.height = 0.06
	_core.mesh = cyl
	_core_mat = StandardMaterial3D.new()
	_core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_core_mat.emission_enabled = true
	_core.material_override = _core_mat
	_core.position = Vector3(0, 0.03, 0)
	add_child(_core)

	_light = OmniLight3D.new()
	_light.omni_range = cell_size
	_light.position = Vector3(0, 1.0, 0)
	add_child(_light)

	# the life mote — hidden until stabilized
	_life_mote = MeshInstance3D.new()
	_life_mote.name = "LifeMote"
	var sm := SphereMesh.new()
	sm.radius = 0.22
	sm.height = 0.44
	_life_mote.mesh = sm
	var lm := StandardMaterial3D.new()
	lm.albedo_color = Color(0.3, 1.0, 0.4)
	lm.emission_enabled = true
	lm.emission = Color(0.3, 1.0, 0.45)
	lm.emission_energy_multiplier = 2.5
	_life_mote.material_override = lm
	_life_mote.position = Vector3(0, 1.1, 0)
	_life_mote.visible = false
	add_child(_life_mote)

func _lambda_color(l: float) -> Color:
	# 0 crystal blue -> 0.4 alive green -> 1 chaos magenta
	if l <= ALIVE:
		var t := l / ALIVE
		return Color(0.55, 0.75, 1.0).lerp(Color(0.3, 1.0, 0.4), t)
	var t := (l - ALIVE) / (1.0 - ALIVE)
	return Color(0.3, 1.0, 0.4).lerp(Color(1.0, 0.2, 0.7), t)

func _apply_lambda(_first: bool) -> void:
	var col := _lambda_color(lambda)
	if _core_mat:
		_core_mat.albedo_color = Color(col.r, col.g, col.b, 0.55)
		_core_mat.emission = col
		_core_mat.emission_energy_multiplier = 1.2 + (1.0 if is_alive() else 0.0)
	if _light:
		_light.light_color = col
		_light.light_energy = 1.0 + (1.5 if is_alive() else 0.0)
	# crystal fades in as lambda -> 0; dissolve fades in as lambda -> 1
	if _crystal_root:
		var vis := clampf(1.0 - lambda / max(ALIVE, 0.001), 0.0, 1.0)
		_crystal_root.visible = vis > 0.05
		_crystal_root.scale = Vector3.ONE * (0.4 + 0.6 * vis)
	if _dissolve_particles:
		var d := clampf((lambda - ALIVE) / (1.0 - ALIVE), 0.0, 1.0)
		_dissolve_particles.emitting = d > 0.05
		_dissolve_particles.amount_ratio = clampf(d, 0.05, 1.0)

func _animate(delta: float) -> void:
	if is_alive() and _core:
		var t := Time.get_ticks_msec() / 1000.0
		_core.scale = Vector3(1.0 + sin(t * 2.0) * 0.04, 1.0, 1.0 + sin(t * 2.0) * 0.04)
	if _life_mote and _life_mote.visible:
		_life_mote.rotate_y(delta * 1.5)
