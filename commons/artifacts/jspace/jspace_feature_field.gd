extends Node3D
class_name JSpaceFeatureField

# @identity
# essence: the raw activation field before the zoom — a sparse grid of tiles where most stay dark (sparsity is the honest majority), a few glow blue, and the dense cells STACK (superposition drawn as height). Tiles near the walker brighten: attention as proximity.
# desire: to show what an interior looks like before it is labeled — quiet, mostly dark, alive in patches.
# critical_parameter: density — fraction of tiles lit; near tiles brighten by presence.
# triggers: _process brightens tiles within reach of the camera; the field breathes on TIME.
# emerges: the walk itself reads as the prompt moving through the layers — where you stand, the field wakes.
# needs: nothing external; seeded RNG so the field is the same field every visit.
# relationships: the approach to [[jspace_zoom_chamber]]; the sparse prelude to its named pillars.
# truth: most of a mind is dark at any moment. The dark tiles are not empty; they are waiting.

@export var cols: int = 8
@export var rows: int = 6
@export var spacing: float = 1.25

var _near_mats: Array = []   # {mat, pos, base}

func _ready() -> void:
	_read_meta_overrides()
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_meta_overrides()

func _read_meta_overrides() -> void:
	if has_meta("config_cols"):
		cols = int(str(get_meta("config_cols")))
	if has_meta("config_rows"):
		rows = int(str(get_meta("config_rows")))

func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 461   # the same field every visit
	for cx in cols:
		for cz in rows:
			var pos := Vector3(
				(float(cx) - float(cols - 1) * 0.5) * spacing, 0,
				(float(cz) - float(rows - 1) * 0.5) * spacing)
			var roll := rng.randf()
			if roll < 0.58:
				_tile(pos, 0.0, 1, rng)          # dark — the honest majority
			elif roll < 0.86:
				_tile(pos, rng.randf_range(0.3, 1.0), 1, rng)
			else:
				_tile(pos, rng.randf_range(0.6, 1.0), rng.randi_range(2, 3), rng)

func _tile(pos: Vector3, act: float, stack: int, rng: RandomNumberGenerator) -> void:
	for level in stack:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var h := 0.09 if level == 0 else 0.12
		bm.size = Vector3(0.92 - level * 0.06, h, 0.92 - level * 0.06)
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		if act <= 0.0:
			m.albedo_color = Color(0.10, 0.11, 0.14)
			m.roughness = 0.85
		else:
			var deep := float(level) / 2.0
			m.albedo_color = Color(0.08, 0.12, 0.2)
			m.emission_enabled = true
			m.emission = Color(0.16, 0.42, 0.8).lerp(Color(0.05, 0.24, 0.52), deep)
			m.emission_energy_multiplier = 0.3 + act * 1.2
			_near_mats.append({"mat": m, "pos": pos, "base": 0.3 + act * 1.2,
				"phase": rng.randf() * TAU})
		mi.material_override = m
		mi.position = pos + Vector3(0, 0.045 + float(level) * 0.115, 0)
		add_child(mi)

func _process(_delta: float) -> void:
	if _near_mats.is_empty():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var local_cam := to_local(cam.global_position)
	var t := Time.get_ticks_msec() / 1000.0
	for e in _near_mats:
		var d: float = Vector2(local_cam.x - e["pos"].x, local_cam.z - e["pos"].z).length()
		var near := clampf(1.0 - d / 3.2, 0.0, 1.0)
		var breathe := 0.12 * sin(t * 1.3 + float(e["phase"]))
		e["mat"].emission_energy_multiplier = float(e["base"]) * (1.0 + breathe) + near * 1.6
