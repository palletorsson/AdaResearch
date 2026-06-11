extends Node3D
class_name DeathPylon

## @identity
## lineage: a hazard that breathes — it draws power from the ground, then spends it all in a
##   gout of fire at the player, then starts over. The cycle (charge → discharge → cool) is
##   the lesson: energy is conserved, gathered before it is thrown.
## essence: during the charge a wide ground field of grid-cells and energy motes is sucked
##   up into the pylon's core (a GPUParticlesAttractorSphere3D pulling everything inward),
##   the core swelling and brightening as it fills; at full charge it fires a jet of fire
##   straight at you — close enough and it kills — then it dims and gathers again.
## truth: the most dangerous machines are patient; they take from the world a long time
##   before they give it back all at once.
##
## Particle technique adapted from the godot-xr-tools particle galleries: GPUParticles3D +
## ParticleProcessMaterial, attractor for the suck, additive fire gradient for the jet.
## Kills via the DeathEffect autoload when the jet reaches the player.

@export var charge_time: float = 4.2
@export var fire_time: float = 1.6
@export var cooldown_time: float = 1.5
@export var kill_range: float = 9.0          # the jet kills the player within this radius
@export var grid_n: int = 5                  # NxN ground grid that gets sucked in
@export var energy_color: Color = Color(0.32, 0.86, 1.0)   # the drawn-in energy (electric cyan)
@export var fire_color: Color = Color(1.0, 0.42, 0.10)     # the discharge fire
@export var pylon_color: Color = Color(0.11, 0.12, 0.15)   # the dark stand
@export var emissive: bool = true

enum State { CHARGE, FIRE, COOLDOWN }

const CORE_Y := 2.45
const TOP_Y := 3.0
const GRID_STEP := 1.05

var _state: int = State.CHARGE
var _t: float = 0.0
var _fired: bool = false
var _player: Node3D
var _core: MeshInstance3D
var _core_mat: StandardMaterial3D
var _halo_mat: StandardMaterial3D
var _suction: GPUParticles3D
var _motes_mat: ParticleProcessMaterial
var _fire: GPUParticles3D
var _attractor: GPUParticlesAttractorSphere3D
var _ring_mat: StandardMaterial3D
var _cells: Array = []                        # [{node, home}]


func _ready() -> void:
	_find_player()
	_build()
	_enter_charge()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("charge_time"): charge_time = float(config_data["charge_time"])
	if config_data.has("kill_range"): kill_range = float(config_data["kill_range"])
	if config_data.has("grid_n"): grid_n = int(config_data["grid_n"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	energy_color = _parse_color(config_data.get("energy_color", energy_color), energy_color)
	fire_color = _parse_color(config_data.get("fire_color", fire_color), fire_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_cells.clear()
	_build()
	_enter_charge()
	# preview: jump partway into the charge so a still capture shows the suck mid-pull
	if config_data.has("preview"):
		_t = charge_time * clampf(float(config_data["preview"]), 0.0, 1.0)
		_process(0.0)
	if config_data.has("preview_fire"):          # force the discharge for a still capture
		_enter_fire()


# ─── structure + particles ───────────────────────────────────────────────────
func _build() -> void:
	var dark := _dark(pylon_color)
	var steel := _dark(pylon_color.lerp(Color(0.4, 0.42, 0.48), 0.5))

	# base + angled legs anchoring it to the ground
	add_child(_cyl(Vector3(0, 0.12, 0), 0.95, 0.24, dark))
	add_child(_cyl(Vector3(0, 0.30, 0), 0.62, 0.30, steel))
	for i in range(4):
		var a := TAU * float(i) / 4.0 + PI / 4.0
		var foot := Vector3(cos(a), 0.0, sin(a)) * 0.95
		add_child(_cyl_between(Vector3(0, 0.5, 0), foot + Vector3(0, 0.06, 0), 0.07, steel))
		add_child(_box(foot + Vector3(0, 0.06, 0), Vector3(0.26, 0.12, 0.26), dark))

	# tapering tower up to the core
	add_child(_cyl(Vector3(0, 1.2, 0), 0.34, 1.5, dark))
	add_child(_cyl(Vector3(0, CORE_Y - 0.25, 0), 0.20, 0.5, steel))
	# glowing energy conduits up the tower
	for i in range(3):
		var a := TAU * float(i) / 3.0
		var off := Vector3(cos(a), 0.0, sin(a)) * 0.30
		add_child(_cyl_between(Vector3(off.x, 0.5, off.z), Vector3(off.x * 0.6, CORE_Y - 0.3, off.z * 0.6), 0.025, _glow(energy_color, 1.4)))

	# the core (swells + brightens as it charges)
	_core_mat = _glow(energy_color, 0.6)
	_core = _sphere(Vector3(0, CORE_Y, 0), 0.34, _core_mat)
	add_child(_core)
	_halo_mat = _halo(energy_color)
	add_child(_sphere(Vector3(0, CORE_Y, 0), 0.52, _halo_mat))
	# cage around the core
	for i in range(6):
		var a := TAU * float(i) / 6.0
		add_child(_cyl_between(Vector3(cos(a) * 0.42, CORE_Y - 0.4, sin(a) * 0.42), Vector3(cos(a) * 0.42, CORE_Y + 0.4, sin(a) * 0.42), 0.018, steel))
	# the emitter tip (where the jet leaves)
	add_child(_cyl(Vector3(0, TOP_Y, 0), 0.10, 0.3, steel))
	add_child(_sphere(Vector3(0, TOP_Y + 0.18, 0), 0.10, _glow(fire_color, 1.0)))

	# the ground intake ring — the mouth it drinks the ground through
	_ring_mat = _glow(energy_color, 1.2)
	var ring := _torus(Vector3(0, 0.04, 0), kill_range * 0.42, 0.05, _ring_mat)
	add_child(ring)

	_build_grid()
	_build_particles()


func _build_grid() -> void:
	# a field of grid-cells on the ground that get sucked up into the core
	var half := (grid_n - 1) * 0.5
	for ix in range(grid_n):
		for iz in range(grid_n):
			var home := Vector3((ix - half) * GRID_STEP, 0.06, (iz - half) * GRID_STEP)
			if home.length() < 0.8:
				continue                       # leave the base clear
			var cell := _box(home, Vector3(0.34, 0.06, 0.34), _glow(energy_color.lerp(Color(0.5, 0.55, 0.7), 0.5), 0.5))
			add_child(cell)
			_cells.append({"node": cell, "home": home})


func _build_particles() -> void:
	# the attractor that pulls the suck up into the core
	_attractor = GPUParticlesAttractorSphere3D.new()
	_attractor.position = Vector3(0, CORE_Y, 0)
	_attractor.radius = kill_range
	_attractor.strength = 2.5
	_attractor.attenuation = 0.5
	add_child(_attractor)

	# energy motes lifting off the whole ground field, funnelled up into the core
	_suction = _new_particles("EnergyIntake", 240, 2.2)
	_suction.position = Vector3(0, 0.1, 0)
	_suction.local_coords = false              # world space — attractor pulls reliably
	_motes_mat = _proc_mat(ParticleProcessMaterial.EMISSION_SHAPE_BOX, Vector3(0, 1, 0), 22.0,
		Vector3(0, 0.0, 0), 0.0, 0.12, 0.05, 0.16,
		_gradient([energy_color.lerp(Color.WHITE, 0.4), energy_color, Color(energy_color.r, energy_color.g, energy_color.b, 0.0)]))
	_motes_mat.emission_box_extents = Vector3(kill_range * 0.42, 0.05, kill_range * 0.42)
	_motes_mat.attractor_interaction_enabled = true
	_motes_mat.damping_min = 3.5               # heavy damping → pulled in and absorbed, not flung
	_motes_mat.damping_max = 7.0
	_suction.process_material = _motes_mat
	_suction.material_override = _part_mat(energy_color, 2.6)
	_suction.draw_pass_1 = _quad(0.11)
	add_child(_suction)

	# the fire jet — off until discharge, then aimed at the player
	_fire = _new_particles("FireJet", 260, 0.9)
	_fire.position = Vector3(0, TOP_Y + 0.18, 0)
	_fire.local_coords = false
	_fire.emitting = false
	var fmat := _proc_mat(ParticleProcessMaterial.EMISSION_SHAPE_SPHERE, Vector3(0, 1, 0), 16.0,
		Vector3(0, -1.2, 0), 7.0, 12.0, 0.22, 0.6,
		_gradient([Color(1.0, 0.96, 0.6), fire_color, Color(0.5, 0.04, 0.0, 0.0)]))
	fmat.emission_sphere_radius = 0.12
	_fire.process_material = fmat
	_fire.material_override = _part_mat(fire_color, 3.4)
	_fire.draw_pass_1 = _quad(0.3)
	add_child(_fire)


# ─── the charge → fire → cool cycle ──────────────────────────────────────────
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	match _state:
		State.CHARGE:
			var f: float = clampf(_t / charge_time, 0.0, 1.0)
			var e: float = f * f                          # ease-in: accelerating intake
			if emissive:
				_core_mat.emission_energy_multiplier = lerpf(0.6, 4.2, f)
				_ring_mat.emission_energy_multiplier = lerpf(0.6, 2.6, f)
			_core.scale = Vector3.ONE * lerpf(0.75, 1.45, f)
			_halo_mat.albedo_color.a = 0.10 + 0.28 * f
			_attractor.strength = lerpf(2.5, 7.0, f)
			for cell in _cells:
				(cell["node"] as Node3D).position = (cell["home"] as Vector3).lerp(Vector3(0, CORE_Y, 0), e * 0.9)
			if _t >= charge_time:
				_enter_fire()
		State.FIRE:
			if not _fired:
				_fired = true
				_discharge()
			if _t >= fire_time:
				_enter_cooldown()
		State.COOLDOWN:
			var f2: float = clampf(_t / cooldown_time, 0.0, 1.0)
			if emissive:
				_core_mat.emission_energy_multiplier = lerpf(3.0, 0.5, f2)
			_core.scale = Vector3.ONE * lerpf(1.2, 0.75, f2)
			for cell in _cells:
				(cell["node"] as Node3D).position = (cell["home"] as Vector3).lerp(Vector3(0, CORE_Y, 0), (1.0 - f2) * 0.9)
			if _t >= cooldown_time:
				_enter_charge()


func _enter_charge() -> void:
	_state = State.CHARGE
	_t = 0.0
	_fired = false
	if _suction: _suction.emitting = true
	if _fire: _fire.emitting = false


func _enter_fire() -> void:
	_state = State.FIRE
	_t = 0.0
	_fired = false
	if _suction: _suction.emitting = false
	if emissive and _core_mat:
		_core_mat.emission_energy_multiplier = 6.0       # flash
	# aim the jet at the player and let it rip
	if _fire:
		var aim: Vector3 = _aim_point()
		var origin: Vector3 = _fire.global_position
		var dir: Vector3 = (aim - origin)
		if dir.length() > 0.01:
			(_fire.process_material as ParticleProcessMaterial).direction = dir.normalized()
		_fire.emitting = true
		_fire.restart()


func _enter_cooldown() -> void:
	_state = State.COOLDOWN
	_t = 0.0
	if _fire: _fire.emitting = false


# discharge: if the player is real and within the jet's reach, kill them
func _discharge() -> void:
	if not is_instance_valid(_player):
		_find_player()
	if not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position) > kill_range:
		return
	var de := get_node_or_null("/root/DeathEffect")
	if de == null:
		return
	if de.has_method("is_immune") and de.is_immune():
		return
	if de.has_method("play"):
		de.play(_aim_point())


# ─── player targeting (project pattern) ──────────────────────────────────────
func _find_player() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		_player = null
		return
	for candidate in [get_tree().get_first_node_in_group("player"),
			scene_root.find_child("XROrigin3D", true, false),
			scene_root.find_child("Player", true, false),
			scene_root.find_child("PlayerBody", true, false)]:
		if candidate is Node3D:
			_player = candidate as Node3D
			return
	_player = null


func _aim_point() -> Vector3:
	if not is_instance_valid(_player):
		return global_position + Vector3(0.0, 1.2, -3.0)
	return _player.global_position + Vector3(0.0, 1.2, 0.0)


# ─── primitives + materials ──────────────────────────────────────────────────
func _dark(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.roughness = 0.7; m.metallic = 0.3
	return m

func _glow(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c; m.emission_enabled = true; m.emission = c
	m.emission_energy_multiplier = e if emissive else e * 0.3
	return m

func _halo(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = c
	m.emission_energy_multiplier = 1.4 if emissive else 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size = size
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat; mi.position = center
	return mi

func _cyl(center: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new(); mesh.top_radius = radius * 0.85; mesh.bottom_radius = radius; mesh.height = height
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat; mi.position = center
	return mi

func _sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius * 2.0
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat; mi.position = center
	return mi

func _torus(center: Vector3, radius: float, tube: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new(); mesh.inner_radius = radius - tube; mesh.outer_radius = radius + tube
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat; mi.position = center
	return mi

func _cyl_between(a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius
	mesh.height = maxf(a.distance_to(b), 0.001)
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = mat
	var y: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.UP if absf(y.dot(Vector3.UP)) < 0.985 else Vector3.RIGHT
	var x: Vector3 = ref.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y).normalized()), (a + b) * 0.5)
	return mi

func _new_particles(n: String, amount: int, lifetime: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = n; p.amount = amount; p.lifetime = lifetime; p.emitting = true; p.local_coords = true
	p.preprocess = lifetime                       # populated on frame 0 (so captures aren't empty)
	p.visibility_aabb = AABB(Vector3(-kill_range, -1, -kill_range), Vector3(kill_range * 2, TOP_Y + 4, kill_range * 2))
	return p

func _proc_mat(shape: int, dir: Vector3, spread: float, gravity: Vector3, vmin: float, vmax: float, smin: float, smax: float, ramp: GradientTexture1D) -> ParticleProcessMaterial:
	var m := ParticleProcessMaterial.new()
	m.emission_shape = shape
	m.direction = dir; m.spread = spread; m.gravity = gravity
	m.initial_velocity_min = vmin; m.initial_velocity_max = vmax
	m.scale_min = smin; m.scale_max = smax
	m.color_initial_ramp = ramp
	return m

func _part_mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = c
	m.emission_enabled = true; m.emission = c
	m.emission_energy_multiplier = e if emissive else e * 0.4
	return m

func _quad(s: float) -> QuadMesh:
	var q := QuadMesh.new(); q.size = Vector2(s, s)
	return q

func _gradient(colors: Array) -> GradientTexture1D:
	var g := Gradient.new()
	var cols := PackedColorArray()
	var offs := PackedFloat32Array()
	for i in range(colors.size()):
		cols.append(colors[i])
		offs.append(float(i) / float(max(colors.size() - 1, 1)))
	g.colors = cols; g.offsets = offs
	var t := GradientTexture1D.new(); t.gradient = g
	return t

func _parse_color(v: Variant, fb: Color) -> Color:
	if v is Color: return v
	if v is String:
		var p: PackedStringArray = (v as String).split(",")
		if p.size() >= 3: return Color(float(p[0]), float(p[1]), float(p[2]))
	return fb
