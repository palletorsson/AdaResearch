extends Node3D
class_name HealthCross

# @identity
# essence: a red cross lying in the room that gives you back some health when you walk over it
# desire: the visitor learns that the hall can restore as well as cost, and learns it with their feet rather than from a panel
# critical_parameter: boost — how much of a mistake this forgives
# triggers: any player body or museum walker entering the pad; once, then it is spent until it comes back
# emerges: a room with a hazard in it becomes a room with a route through the hazard
# needs: a health provider — /root/GameManager, or any node in group "health_provider" [reported if absent]
# relationships: the pick-up twin of wall_health_station, which is a wall you stand at; this is a thing you step on
# truth: a pick-up is a promise the room makes about its own danger
#
## 2026-09-08, Palle: "Also in point close to wall_health_station add a red cross
## as pick when we walk over it to boost health."
##
## THE STATION IS A PLACE YOU GO TO. THIS IS A THING YOU FIND. wall_health_station
## has a charge that drains, a face, a readout, and asks you to stand at it; the
## cross asks nothing and is gone once taken. Both draw from the same provider, so
## a hall can hold either or both without two ideas of what health is.
##
## IT MASKS LAYER 1 AS WELL AS LAYER 20, AND THAT IS THE WHOLE TRICK.
##
## The endless museum's walker is a bare CharacterBody3D named "Walker" on
## collision layer 1, in group `em_walker` and nothing else. It is in none of the
## grid's player groups, has no XROrigin3D ancestor and is not on layer 20. So an
## Area3D masking PLAYER_MASK alone — which is what force_pad.gd:17 does — never
## overlaps it, and the artifact does nothing in the museum with no error, no
## refusal and no log line. force_pad even tests `body is CharacterBody3D` in its
## handler, which would have caught the walker, but the body never arrives for the
## test to run. This masks 1 | 524288 so the pad is tripped in both worlds.

const PLAYER_LAYER := 524288          # physics layer 20 — the grid's player body
const WALKER_LAYER := 1               # physics layer 1  — the museum's Walker
const HealthGroup := "health_provider"

## How much health one cross returns. Delivered, not promised: a body that is
## already whole takes nothing and the cross is not spent.
@export var boost: float = 34.0
## Seconds until it comes back. 0 leaves it taken for good.
@export var respawn_s: float = 25.0
@export var cross_color: Color = Color(0.86, 0.16, 0.18)
## The arm of the cross, metres. The bar is this long and a third as wide.
@export var arm_m: float = 0.30
## How high it floats, and how far it bobs.
@export var hover_m: float = 0.34
@export var bob_m: float = 0.05
@export var spin_deg_s: float = 42.0

signal taken(delivered: float)
signal respawned()
## Somebody stepped on it and there was nothing to give — already whole, or no
## provider in the scene at all. Said out loud because a silent pick-up that does
## nothing is the bug this artifact is most likely to have.
signal declined(why: String)

var _body: Node3D
var _area: Area3D
var _t := 0.0
var _spent := false
var _cool := 0.0
var _warned := false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("boost"):
		boost = float(config_data["boost"])
	if config_data.has("respawn"):
		respawn_s = float(config_data["respawn"])
	if config_data.has("arm_m"):
		arm_m = float(config_data["arm_m"])
	if config_data.has("hover_m"):
		hover_m = float(config_data["hover_m"])
	if config_data.has("color"):
		var c: Variant = config_data["color"]
		if c is Color:
			cross_color = c
		elif typeof(c) == TYPE_STRING and Color.html_is_valid(str(c)):
			cross_color = Color.html(str(c))
	if is_inside_tree():
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()

	_body = Node3D.new()
	_body.name = "Cross"
	_body.position = Vector3(0, hover_m, 0)
	add_child(_body)

	# two bars, one across the other. Emissive so it reads as an offer rather
	# than as furniture — a pick-up has to be seen from across a hall.
	var m := StandardMaterial3D.new()
	m.albedo_color = cross_color
	m.emission_enabled = true
	m.emission = cross_color
	m.emission_energy_multiplier = 1.9
	m.roughness = 0.4
	var thick: float = arm_m / 3.0
	for i in 2:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(arm_m, thick, thick) if i == 0 else Vector3(thick, arm_m, thick)
		bar.mesh = bm
		bar.material_override = m
		_body.add_child(bar)

	# THE PAD. Tall enough that a walking body crosses it rather than stepping
	# over, and masking BOTH worlds' bodies — see the header.
	_area = Area3D.new()
	_area.name = "Pad"
	_area.collision_layer = 0
	_area.collision_mask = PLAYER_LAYER | WALKER_LAYER
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.6, 0.9)
	col.shape = box
	col.position.y = 0.8
	_area.add_child(col)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if _spent:
		if respawn_s > 0.0:
			_cool -= delta
			if _cool <= 0.0:
				_respawn()
		return
	if _body != null and is_instance_valid(_body):
		_body.position.y = hover_m + sin(_t * 2.1) * bob_m
		_body.rotation_degrees.y = _t * spin_deg_s


## Anything that walks. The museum's Walker is a CharacterBody3D and so is the
## grid's desktop player; a VR rig arrives as its own body. The mask has already
## narrowed this to the two layers that matter, so the test here is about not
## firing on a dropped artifact that happens to roll across.
func _on_body_entered(body: Node3D) -> void:
	if _spent or body == null:
		return
	var is_walker: bool = body.is_in_group("em_walker") or body.is_in_group("player_body") \
		or body.is_in_group("player") or body.is_in_group("vr_player")
	if not is_walker and not (body is CharacterBody3D):
		return
	_take()


## Give what is actually there to give.
##
## Returns the delivered amount, which is what ARRIVED and not what was offered —
## set_health clamps to max_player_health, so asking the provider back is the only
## honest way to know. The same reasoning wall_health_station.gd:141 gives, and
## the same reason the cross is not spent when it delivered nothing: a pick-up
## that vanishes without helping is worse than one that waits.
func _take() -> float:
	var hp := _health_node()
	if hp == null or not (hp.has_method("get_health") and hp.has_method("set_health")):
		if not _warned:
			_warned = true
			push_warning("health_cross: no health provider — no /root/GameManager"
				+ " and nothing in group '%s'" % HealthGroup)
		declined.emit("no health provider")
		return 0.0
	var before: float = float(hp.call("get_health"))
	hp.call("set_health", before + boost)
	var delivered: float = float(hp.call("get_health")) - before
	if delivered <= 0.0:
		declined.emit("already whole")
		return 0.0
	_spent = true
	_cool = respawn_s
	if _body != null and is_instance_valid(_body):
		_body.visible = false
	taken.emit(delivered)
	print("health_cross: gave %.1f (asked %.1f)" % [delivered, boost])
	return delivered


func _respawn() -> void:
	_spent = false
	if _body != null and is_instance_valid(_body):
		_body.visible = true
	respawned.emit()


## Health is reached by CAPABILITY, not by name — the same lookup
## wall_health_station uses, so a hall with both has one idea of what health is.
func _health_node() -> Node:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null:
		return gm
	var group := get_tree().get_nodes_in_group(HealthGroup) if get_tree() else []
	return group[0] if group.size() > 0 else null


## For a probe.
func is_spent() -> bool:
	return _spent
