extends Node3D

## Unfinishable Terrarium — a world with an hour meter and no reset.
##
## @identity
## essence: state persisted to user:// across sessions, an hour meter counting real elapsed time, and no control that returns it to the beginning
## desire: to arrive in the middle of something that did not wait for you and will not start over for you
## critical_parameter: elapsed_hours — the only number that never goes down. Everything else in this artifact can be argued with; this cannot.
## triggers: time. It runs whether or not the map is loaded, because the meter reads the wall clock and the state file remembers
## emerges: you always arrive mid-episode, and the etched log on the glass has your interventions on it with dates
## needs: user:// write access [has]; nothing else — the ecology is procedural so there is no asset to reset TO
## relationships: kin to stock_stratum (both are about deposits) and opposite to every demo in this project — those all restart, which is what makes them demos
## truth: a world you can restart is a demonstration. A world you cannot is a responsibility.
##
## Every other simulation here is a demo: it begins when you look and ends when you
## leave, so nothing you do to it costs anything. Cheng's worlds run without you, and
## the not-waiting is the whole substance — an artwork that cannot be finished is
## structurally different from one that is merely long.
##
## So the only irreversible thing in this project is a brass counter. It reads the wall
## clock, writes to user://, and has no zeroing control anywhere in the artifact or its
## config. That absence is the piece.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const STATE := "user://unfinishable_terrarium.json"

## Only for capture and study — a still cannot show accumulation, so this lets a sweep
## stand in for elapsed time. It does not reset anything; it previews a later reading.
@export var preview_hours: float = -1.0
@export var tank: Vector3 = Vector3(0.62, 0.46, 0.62)
@export var stand_height: float = 0.82
@export var finish: String = "terminal"
@export var unit_code: String = "UT-01"

var _hours: float = 0.0
var _interventions: int = 0


func _ready() -> void:
	_load_state()
	_build_stand()
	_build_tank()
	_build_meter()
	_build_log()


## Reads the deposit. If none exists this is the first firing and the meter starts at
## zero — the only time it ever will.
func _load_state() -> void:
	var now: float = float(Time.get_unix_time_from_system())
	var first: float = now
	if FileAccess.file_exists(STATE):
		var fa := FileAccess.open(STATE, FileAccess.READ)
		if fa != null:
			var j := JSON.new()
			if j.parse(fa.get_as_text()) == OK and typeof(j.data) == TYPE_DICTIONARY:
				var d: Dictionary = j.data
				first = float(d.get("first_seen", now))
				_interventions = int(d.get("interventions", 0))
	else:
		var w := FileAccess.open(STATE, FileAccess.WRITE)
		if w != null:
			w.store_string(JSON.stringify({"first_seen": now, "interventions": 0}))
			w.close()
	_hours = maxf((now - first) / 3600.0, 0.0)
	if preview_hours >= 0.0:
		_hours = preview_hours


func _build_stand() -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	add_child(cab)
	var steel: StandardMaterial3D = HangarKit.worn_metal(pal["body"].lightened(0.08))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			cab.add_child(HangarKit.box(
				Vector3(sx * (tank.x * 0.5 - 0.03), stand_height * 0.5, sz * (tank.z * 0.5 - 0.03)),
				Vector3(0.035, stand_height, 0.035), steel))
	cab.add_child(HangarKit.box(Vector3(0, stand_height + 0.012, 0),
		Vector3(tank.x + 0.06, 0.024, tank.z + 0.06), steel))
	cab.add_child(HangarKit.box(Vector3(0, stand_height - 0.02, tank.z * 0.5 + 0.03),
		Vector3(tank.x * 0.9, 0.005, 0.005), HangarKit.emissive(pal["accent"], 2.0)))


func _build_tank() -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.66, 0.74, 0.80, 0.085)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var base_y: float = stand_height + 0.024

	var soil := StandardMaterial3D.new()
	soil.albedo_color = Color(0.19, 0.15, 0.12)
	soil.roughness = 0.98
	add_child(HangarKit.box(Vector3(0, base_y + 0.045, 0),
		Vector3(tank.x - 0.02, 0.09, tank.z - 0.02), soil))

	# THE ECOLOGY, AGED BY THE METER. It is procedural precisely so there is no pristine
	# asset to restore: growth is a function of hours, and hours only increase.
	var age: float = clampf(_hours / 240.0, 0.0, 1.0)
	var n: int = 5 + int(age * 16.0)
	for i in range(n):
		var a: float = TAU * float(i) * 0.618034
		var r: float = sqrt(float(i) / float(n)) * (tank.x * 0.40)
		var h: float = lerpf(0.03, 0.20, fmod(float(i) * 0.37, 1.0)) * (0.4 + age)
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.25, 0.42, 0.20).lerp(Color(0.52, 0.46, 0.16), age)
		m.roughness = 0.9
		add_child(HangarKit.box(
			Vector3(cos(a) * r, base_y + 0.09 + h * 0.5, sin(a) * r),
			Vector3(0.022, h, 0.022), m))

	for sz in [-1.0, 1.0]:
		add_child(HangarKit.box(Vector3(0, base_y + tank.y * 0.5, sz * tank.z * 0.5),
			Vector3(tank.x, tank.y, 0.008), glass))
	for sx in [-1.0, 1.0]:
		add_child(HangarKit.box(Vector3(sx * tank.x * 0.5, base_y + tank.y * 0.5, 0),
			Vector3(0.008, tank.y, tank.z), glass))
	add_child(HangarKit.box(Vector3(0, base_y + tank.y, 0),
		Vector3(tank.x, 0.010, tank.z), glass))


## The brass hour meter, bolted to the frame the way a machine that has been running in
## a basement for years wears its counter. There is no zero on it.
func _build_meter() -> void:
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color(0.66, 0.52, 0.22)
	brass.metallic = 0.85
	brass.roughness = 0.32
	var y: float = stand_height * 0.62
	var z: float = tank.z * 0.5 + 0.04
	add_child(HangarKit.box(Vector3(0.0, y, z), Vector3(0.20, 0.075, 0.030), brass))
	var face := StandardMaterial3D.new()
	face.albedo_color = Color(0.06, 0.06, 0.05)
	add_child(HangarKit.box(Vector3(0.0, y, z + 0.017), Vector3(0.165, 0.044, 0.004), face))
	var read: MeshInstance3D = HangarKit.stencil(
		"%0*.1f h" % [6, _hours], Vector2(0.14, 0.026), Color(0.92, 0.84, 0.55))
	if read:
		read.position = Vector3(0.0, y, z + 0.021)
		add_child(read)
	var plate: MeshInstance3D = HangarKit.stencil(
		"HOURS RUN · NO RESET FITTED", Vector2(0.26, 0.017), Color(0.60, 0.50, 0.28))
	if plate:
		plate.position = Vector3(0.0, y - 0.055, z + 0.017)
		add_child(plate)


## The etched log. Interventions are recorded on the glass with the hour they happened,
## because a responsibility that leaves no trace is just a demo with extra steps.
func _build_log() -> void:
	var base_y: float = stand_height + 0.024
	var lines: int = mini(_interventions, 5)
	for i in range(lines):
		var e: MeshInstance3D = HangarKit.stencil(
			"%04.1fh  intervention" % (_hours * float(i + 1) / float(lines + 1)),
			Vector2(0.30, 0.014), Color(0.86, 0.90, 0.92, 0.75))
		if e:
			e.position = Vector3(-tank.x * 0.5 + 0.19, base_y + tank.y - 0.05 - float(i) * 0.045,
				tank.z * 0.5 + 0.006)
			add_child(e)
	var code: MeshInstance3D = HangarKit.stencil(unit_code, Vector2(0.085, 0.018),
		Color(0.70, 0.72, 0.75))
	if code:
		code.position = Vector3(tank.x * 0.5 - 0.07, base_y + 0.03, tank.z * 0.5 + 0.006)
		add_child(code)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("preview_hours"):
		preview_hours = float(config_data["preview_hours"])
