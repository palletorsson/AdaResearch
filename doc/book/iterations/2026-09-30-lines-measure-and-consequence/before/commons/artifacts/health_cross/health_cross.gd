extends Node3D
class_name HealthCross

# @identity
# essence: a red cross lying in the room that gives you back some health when you walk over it
# desire: the visitor learns that the hall can restore as well as cost, and learns it with their feet rather than from a panel
# critical_parameter: boost — how much of a mistake this forgives — and take_below, how big a mistake has to be before the room forgives it
# triggers: a VISITOR entering the pad while health is below take_below of maximum; once, then it is spent until it comes back
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

## 2026-09-09, Palle: "like the pick_up_cube when we walk in health_cross we
## should pick it up if our heath is low."
##
## THE PICK-UP WORKED. THE CONDITION WAS MISSING. Three probes measured the pad
## firing for the museum Walker, the desktop player and the VR rig, so the ask is
## not "make it fire" — it is the word LOW. Until now the gate was `delivered >
## 0.0`, which is a threshold of zero: a body at 99.9 of 100 took the whole cross,
## received 0.1, and left the cell empty for 25 seconds. take_below is the
## condition that sentence was asking for.
##
## AND "WE" TURNED OUT TO EXCLUDE SOMETHING. The old acceptance test fell back to
## `body is CharacterBody3D` with no group check, and hazard_creature_base extends
## CharacterBody3D and never assigns a collision layer, so every creature in the
## corpus sits on layer 1 — which this pad's mask admits. Measured: a body in
## group "enemy" alone walked the pad and took the cross, healing the player from
## somewhere else in the hall and leaving nothing for the visitor. A head crab
## eating the medkit is not what "when we walk in" means.

## How much health one cross returns. Delivered, not promised: a body that is
## already whole takes nothing and the cross is not spent.
@export var boost: float = 34.0
## Only picked up when health has fallen BELOW this fraction of maximum. 1.0 is the old behaviour, taken for any scratch at all; 0.0 means never taken.
@export var take_below: float = 0.75
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

## How long a refusal shows for, and how bright the cross sits when at rest.
const PULSE_S := 0.55
const BASE_EMISSION := 1.9
## How often an unspent cross re-checks whoever is already standing on it.
const SCAN_S := 0.5

var _body: Node3D
var _area: Area3D
var _mat: StandardMaterial3D
var _t := 0.0
var _spent := false
var _cool := 0.0
var _warned := false
var _pulse := 0.0
var _scan := 0.0


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("boost"):
		boost = float(config_data["boost"])
	if config_data.has("respawn"):
		respawn_s = float(config_data["respawn"])
	# Config values arrive from the grid as STRINGS, so a non-numeric value
	# silently becomes 0.0 — which for this key would mean a cross that never
	# takes. The clamp bounds that to "never" rather than to nonsense.
	if config_data.has("take_below"):
		take_below = clampf(float(config_data["take_below"]), 0.0, 1.0)
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
	m.emission_energy_multiplier = BASE_EMISSION
	m.roughness = 0.4
	# held, because a refusal dims it — see _refuse()
	_mat = m
	_pulse = 0.0
	_scan = 0.0
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

	# the refusal, dimming and recovering, landing exactly back on rest
	if _pulse > 0.0 and _mat != null:
		_pulse = maxf(0.0, _pulse - delta)
		var k: float = _pulse / PULSE_S              # 1 at the refusal, 0 at rest
		_mat.emission_energy_multiplier = lerpf(BASE_EMISSION, BASE_EMISSION * 0.25,
				sin(k * PI))

	# WHOEVER IS ALREADY STANDING HERE. Only body_entered is connected, and
	# _respawn() does no re-scan, so without this a visitor who steps on at 80
	# (refused), is then bitten down to 47 without moving, never gets the heal —
	# the entry event has already fired. It also closes the older hole where a
	# body standing on a spent cross got nothing when the cooldown ended. Silent,
	# so a visitor loitering on the pad does not strobe it.
	_scan -= delta
	if _scan <= 0.0:
		_scan = SCAN_S
		if _area != null and is_instance_valid(_area):
			for b in _area.get_overlapping_bodies():
				if _is_visitor(b):
					_take(false)
					break


func _on_body_entered(body: Node3D) -> void:
	if _spent:
		return
	if _is_visitor(body):
		_take()


## A VISITOR, not merely a body. The desktop player is in `player_body`, the
## museum Walker in `em_walker`, and the VR XRToolsPlayerBody is in no group
## whatever, so that one is recognised by the XROrigin3D above it.
##
## Shared verbatim with approach_wall, approach_scale and carve_grid, which makes
## four. It replaces an `or body is CharacterBody3D` fallback that admitted every
## creature in the corpus: hazard_creature_base extends CharacterBody3D and never
## assigns a collision layer, so a head crab sits on layer 1, which this pad's
## mask lets in. That was measured, not suspected — an "enemy" body walked the pad
## and took the cross.
func _is_visitor(b: Node) -> bool:
	if b == null or is_ancestor_of(b):
		return false
	if b.is_in_group("em_walker") or b.is_in_group("player_body") \
		or b.is_in_group("player") or b.is_in_group("vr_player"):
		return true
	var n: Node = b.get_parent()
	while n != null:
		if n is XROrigin3D:
			return true
		n = n.get_parent()
	return false


## Give what is actually there to give.
##
## Returns the delivered amount, which is what ARRIVED and not what was offered —
## set_health clamps to max_player_health, so asking the provider back is the only
## honest way to know. The same reasoning wall_health_station.gd:141 gives, and
## the same reason the cross is not spent when it delivered nothing: a pick-up
## that vanishes without helping is worse than one that waits.
## THE GATE SITS BEFORE THE WRITE, and that is not a stylistic preference.
## GameManager.set_health emits player_damaged and calls _play_damage_beep() on
## any DECREASE, so writing the boost and rolling it back on a failed test would
## fire a damage beep and a HUD flash for a heal that never happened. Test first,
## write once.
##
## WHY 0.75, from the corpus's own damage numbers against a cap of 100:
##   a crab bite is max/3 = 33.3, so ONE bite leaves 66.7 and the cross fires at
##   the moment the hall actually becomes dangerous. At 0.5 one bite would not
##   qualify and in a hall with a single crab the cross would never pay out and
##   would read as dead. anamorphic_cross takes 15: one hit leaves 85 and is
##   refused, two leave 70 and are answered, which is the right shape — a scratch
##   is not an emergency, a pattern of them is. Three bites kill, so 0.75 keeps
##   the cross a route through the hazard rather than a last rite.
##
## The change only ever makes the cross DECLINE where it used to take. No
## placement starts giving health where it did not, and no cross vanishes in a
## case where it previously stayed: it is available MORE often, not less.
func _take(announce: bool = true) -> float:
	var hp := _health_node()
	if hp == null or not (hp.has_method("get_health") and hp.has_method("set_health")):
		if not _warned:
			_warned = true
			push_warning("health_cross: no health provider — no /root/GameManager"
				+ " and nothing in group '%s'" % HealthGroup)
		declined.emit("no health provider")
		return 0.0
	var before: float = float(hp.call("get_health"))
	# The cap by wall_health_station's own idiom, so a hall with both has one
	# idea of what full means. Degrade toward TAKING if it cannot be read.
	var cap: float = 100.0
	if "max_player_health" in hp:
		cap = float(hp.get("max_player_health"))
	if cap > 0.0 and before >= cap * take_below:
		if announce:
			_refuse("not low enough", before, cap)
		else:
			declined.emit("not low enough")
		return 0.0
	hp.call("set_health", before + boost)
	var delivered: float = float(hp.call("get_health")) - before
	if delivered <= 0.0:
		if announce:
			_refuse("already whole", before, cap)
		else:
			declined.emit("already whole")
		return 0.0
	_spent = true
	_cool = respawn_s
	if _body != null and is_instance_valid(_body):
		_body.visible = false
	taken.emit(delivered)
	print("health_cross: gave %.1f (asked %.1f)" % [delivered, boost])
	return delivered


## A DECLINE HAS TO BE VISIBLE, or the threshold turns a design change into a bug
## report. The header above this file has claimed since 2026-09-08 that the
## refusal is "said out loud"; it was not. `declined` had no listeners anywhere in
## the repo, there was no audio node, no flash and no print, so the cross went on
## bobbing and spinning pixel-identical to an untaken one. Raising the threshold
## multiplies the number of times a visitor steps on it and gets nothing, so the
## promise in the header has to become true before the gate ships.
##
## Both bars share one material, so one property dims the whole cross.
func _refuse(why: String, health: float, cap: float) -> void:
	_pulse = PULSE_S
	declined.emit(why)
	print("health_cross: declined — %s (health %.0f of %.0f, takes below %.0f)"
		% [why, health, cap, cap * take_below])


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
