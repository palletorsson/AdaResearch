extends Node3D

## THE DANGER X — a large transparent cross you can walk into, and pay for.
##
## 2026-09-01, Palle: "add danger zone, and indicate that we are losing health,
## flash red screen, rest when we are out, large transparent X."
##
## Two long diagonals crossing at 1.6 m, 3.4 m across, at a third opacity: big
## enough to fill a corridor, faint enough that you can walk into it before you
## have decided to. Standing in it costs health on a tick; leaving stops it. That
## is the whole contract, and none of it is written here.
##
## THE HAZARD IS NOT MINE, ON PURPOSE. It composes commons/hazards/DangerZone,
## which already owns the ticking, the enter/exit bookkeeping, the route to
## /root/GameManager by capability, and the chromatic neutraliser rule that lets
## a friend in the zone mute the damage. A second hazard written here would be a
## second thing to keep correct and a second thing that rule would not know about.
##
## WHAT I HAD TO FIX TO MAKE THE FLASH POSSIBLE. DangerZone's `_flash_screen`
## was `# TODO: Add screen flash effect / pass`, and had been since the file was
## written — so every hazard in the game drained health with the screen perfectly
## still. DeathEffect owned a VR-proven red overlay but exposed it only through
## hurt(), which ALSO teleports the player to spawn: right for a laser, absurd
## four times a second. DeathEffect now has a flash-only `damage_flash()`,
## DangerZone's stub calls it, and `_deal_damage` calls the stub. Every hazard in
## the corpus gained an indicator, which is the correct blast radius — a hazard
## that takes from you invisibly is a bug in all of them, not in this one.
##
## THE ANAMORPHIC VERSION IS KEPT, NOT DELETED. At `depth_gap_m > 0` the two
## strokes sit apart along the corridor and read as an X only from the corridor's
## axis, which is what this artifact was before this instruction. Default 0 — a
## real X is what was asked for — but the standpoint version is one number away.

const DangerZoneScript = preload("res://commons/hazards/DangerZone.gd")

@export var bar_len_m: float = 3.4
@export var bar_thick_m: float = 0.16
@export var cross_height_m: float = 1.6
## Above 0, the two strokes separate along the corridor and the X becomes a fact
## about where you are standing rather than about the object.
@export var depth_gap_m: float = 0.0
@export var bar_color: Color = Color(0.92, 0.19, 0.22)
@export var bar_alpha: float = 0.34
## Health per tick while you stand in it, and how often a tick comes.
@export var damage_per_tick: float = 7.0
@export var tick_interval: float = 0.45

signal entered()
signal left()

var _strokes: Array[MeshInstance3D] = []
var _zone: Area3D = null


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("bar_len_m"):
		bar_len_m = float(config_data["bar_len_m"])
	if config_data.has("cross_height_m"):
		cross_height_m = float(config_data["cross_height_m"])
	if config_data.has("depth_gap_m"):
		depth_gap_m = float(config_data["depth_gap_m"])
	if config_data.has("damage_per_tick"):
		damage_per_tick = float(config_data["damage_per_tick"])
	if config_data.has("tick_interval"):
		tick_interval = float(config_data["tick_interval"])
	if not _strokes.is_empty():
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_strokes.clear()

	# One bar, turned twice: the two strokes are the same object at opposite
	# angles and cannot drift apart.
	_strokes.append(_stroke(45.0, -depth_gap_m * 0.5))
	_strokes.append(_stroke(-45.0, depth_gap_m * 0.5))

	var dz = DangerZoneScript.new()
	dz.name = "DangerZone"
	dz.damage_per_tick = damage_per_tick
	dz.tick_interval = tick_interval
	dz.flash_on_damage = true
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# The volume is the X's own span, not a point at its centre: you are in
	# danger where the cross IS, which is most of a corridor's width.
	box.size = Vector3(bar_len_m * 0.72, bar_len_m * 0.72,
			maxf(0.6, depth_gap_m + 0.7))
	col.shape = box
	dz.add_child(col)
	dz.position = Vector3(0, cross_height_m, 0)
	dz.body_entered.connect(func(_b): entered.emit())
	dz.body_exited.connect(func(_b): left.emit())
	add_child(dz)
	_zone = dz


func _stroke(deg: float, z: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(bar_len_m, bar_thick_m, bar_thick_m)
	m.mesh = bm
	m.position = Vector3(0, cross_height_m, z)
	m.rotation = Vector3(0, 0, deg_to_rad(deg))
	m.material_override = _mat(bar_color)
	add_child(m)
	return m


## Is anyone standing in it right now? DangerZone keeps the book.
func is_occupied() -> bool:
	if _zone == null or not is_instance_valid(_zone):
		return false
	return bool(_zone.get("player_inside"))


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, bar_alpha)
	m.roughness = 0.45
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.55
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED     # transparent: both faces
	return m
