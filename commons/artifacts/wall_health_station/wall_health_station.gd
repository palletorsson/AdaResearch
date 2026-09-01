extends Node3D

## THE KIT ON THE WALL.
##
## 2026-09-01, Palle: "a med kit station for health boost like in Half-Life that
## can boost your health ... a kit station on the wall to regain health."
##
## The citation is exact and worth keeping exact. Half-Life's wall charger is not
## a pickup — you stand at it, you hold the button, and it drains while it fills
## you. That is a different object from a floor medkit: it makes the room decide
## what your body is worth, at a fixed place, with a supply that runs out. It is
## the reason the corridor is a corridor and not a scoreboard.
##
## So this one has a CHARGE, and it does not come back. `anamorphic_cross` takes
## 15 for walking into a shape that was never there; this station holds 75, which
## is five arrivals. After that the corridor still charges and there is nothing on
## the wall, which is the only honest ending for a machine that dispenses relief.
##
## HEALTH IS REACHED BY CAPABILITY, NOT BY NAME — /root/GameManager first, then
## any node in the "health_provider" group, then nothing. GameManager is an
## autoload and every probe here is `extends SceneTree`, which cannot see one, so
## an artifact that names it fails to COMPILE under test rather than failing a
## check. That is how info_board.gd became untestable.

const TextScreenScript = preload("res://commons/ui/text_screen.gd")
const HealthGroup := "health_provider"

@export var charge: float = 75.0
## Health per second while someone is standing at it.
@export var rate_per_sec: float = 22.0
@export var reach_m: float = 0.85
@export var body_color: Color = Color(0.83, 0.82, 0.78)
@export var trim_color: Color = Color(0.72, 0.16, 0.14)

signal drew(amount: float, charge_left: float)
signal emptied()

var _readout
var _area: Area3D
var _occupants: int = 0
var _spent := false


func _ready() -> void:
	_build()
	set_process(true)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("charge"):
		charge = float(config_data["charge"])
	if config_data.has("rate_per_sec"):
		rate_per_sec = float(config_data["rate_per_sec"])
	if _readout:
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	_spent = charge <= 0.0

	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.44, 0.14)
	box.mesh = bm
	box.position = Vector3(0, 1.25, 0)
	box.material_override = _mat(body_color, 0.55)
	add_child(box)

	var cross_v := MeshInstance3D.new()
	var cv := BoxMesh.new()
	cv.size = Vector3(0.07, 0.22, 0.02)
	cross_v.mesh = cv
	cross_v.position = Vector3(0, 1.30, 0.08)
	cross_v.material_override = _mat(trim_color, 0.4)
	add_child(cross_v)

	var cross_h := MeshInstance3D.new()
	var ch := BoxMesh.new()
	ch.size = Vector3(0.22, 0.07, 0.02)
	cross_h.mesh = ch
	cross_h.position = Vector3(0, 1.30, 0.08)
	cross_h.material_override = _mat(trim_color, 0.4)
	add_child(cross_h)

	_readout = TextScreenScript.new()
	_readout.mode = 0
	_readout.width_m = 0.3
	_readout.title = ""
	_readout.body = _face()
	_readout.position = Vector3(0, 1.02, 0.09)
	add_child(_readout)

	_area = Area3D.new()
	_area.name = "Reach"
	_area.collision_mask = 0xFFFFF
	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = reach_m
	col.shape = sph
	_area.position = Vector3(0, 1.2, reach_m * 0.5)
	_area.add_child(col)
	_area.body_entered.connect(func(_b): _occupants += 1)
	_area.body_exited.connect(func(_b): _occupants = maxi(0, _occupants - 1))
	add_child(_area)


var _face_t := 0.0

func _process(delta: float) -> void:
	if _occupants > 0:
		draw_from(rate_per_sec * delta)
	# The face is a readout, so it has to be right when nothing is happening too:
	# your health falls in the danger X across the room and this must already say
	# so by the time you walk over. Four times a second is plenty and costs
	# nothing — a station is not a per-frame instrument.
	_face_t -= delta
	if _face_t <= 0.0:
		_face_t = 0.25
		if _readout != null and is_instance_valid(_readout):
			_readout.body = _face()


## Take health out of the wall and put it in whoever is standing here.
##
## Public, so a probe or a controller can call it without pretending to be a
## body. Returns what was actually delivered — which is less than asked for when
## the wall is nearly empty, and zero when it is empty or when the person is
## already whole. A station that reports giving what it did not give is worse
## than one that gives nothing.
func draw_from(want: float) -> float:
	if _spent or want <= 0.0 or charge <= 0.0:
		return 0.0
	var hp := _health_node()
	if hp == null or not (hp.has_method("get_health") and hp.has_method("set_health")):
		return 0.0
	var before: float = float(hp.call("get_health"))
	var give: float = minf(want, charge)
	hp.call("set_health", before + give)
	# set_health CLAMPS to max_player_health, so what left the wall is what
	# actually arrived, not what was offered. Asking the provider back is the
	# only way to know, and it is why the wall does not drain into a full body.
	var delivered: float = float(hp.call("get_health")) - before
	charge = maxf(0.0, charge - delivered)
	if _readout != null and is_instance_valid(_readout):
		_readout.body = _face()
	if delivered > 0.0:
		drew.emit(delivered, charge)
	if charge <= 0.0 and not _spent:
		_spent = true
		emptied.emit()
		print("wall_health_station: empty")
	return delivered


func charge_left() -> float:
	return charge


func is_empty() -> bool:
	return _spent


## THE FACE ANSWERS BOTH QUESTIONS AT ONCE.
##
## 2026-09-01, Palle: "can we see how much health we have in VR, when we are
## close to wall_health_station how do we activate the health if needed?"
##
## YOUR HEALTH IS THE BIG NUMBER, because that is what you came to find out, and
## because a station that shows only its own supply tells you about itself rather
## than about you. The station's remaining charge sits under it, small.
##
## AND THERE IS NOTHING TO ACTIVATE. Standing within reach_m is the whole gesture
## — no button, no trigger, no held USE. Half-Life needed a keypress because it
## had a keyboard; in VR the body IS the input, and walking up to a thing is the
## least ambiguous instruction a room can give. So the face says which of the
## four states it is in, and the state names are the instructions:
##
##     STEP CLOSER   nobody within reach — this is the only one that asks
##     CHARGING      it is happening, right now, without you doing anything
##     FULL          you do not need it; the wall is not spending on you
##     EMPTY         it is finished, and it does not come back
func _face() -> String:
	var hp := _health_node()
	var mine: String = "--"
	var full := false
	if hp != null and hp.has_method("get_health"):
		var now: float = float(hp.call("get_health"))
		mine = "%d" % int(round(now))
		var cap: float = 100.0
		if "max_player_health" in hp:
			cap = float(hp.get("max_player_health"))
		full = now >= cap - 0.01
	var state := "STEP CLOSER"
	if charge <= 0.0:
		state = "EMPTY"
	elif _occupants > 0 and full:
		state = "FULL"
	elif _occupants > 0:
		state = "CHARGING"
	return "%s\n%s\nwall %d" % [mine, state, int(round(charge))]


func _health_node() -> Node:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		return gm
	var group := get_tree().get_nodes_in_group(HealthGroup) if get_tree() else []
	return group[0] if group.size() > 0 else null


func _mat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m
