extends Node
## The time a mushroom keeps in the eyes: put on the visitor's camera by the first one eaten, it holds the sight
## effect (mushroom_sight.gd) and its curve. Rises over RISE seconds, holds HOLD, fades over FADE: the fade begins
## 10 s after eating (Palle, 17 Nov 2026: 'we should also fade the effect after 10 sec') and is gone at 15 s. Another mushroom
## eaten meanwhile changes the operation to its own and starts the curve again from where the amount is; two in a
## row are stronger (up to 1). Nothing else of the visitor is changed. In a headset the amount is kept lower
## (HEADSET_SCALE): the whole view moving with the head is harder on a body than a screen is.

const Sight := preload("res://commons/artifacts/mushroom_basket/mushroom_sight.gd")
const RISE := 3.0
const HOLD := 7.0
const FADE := 5.0
const HEADSET_SCALE := 0.6
const TITLES := ["CHOP THE BANDS", "CHANNELS LOSE REGISTRATION", "EXCHANGE THE BLOCKS", "REPEAT A SCANLINE", "FEWER COLOUR VALUES", "TEAR ONE BAND"]

var camera: Camera3D
var effect: Sight
var mode := -1
var strength := 0.0
var peak := 0.0
var since := 0.0
var clock := 0.0
var eaten := 0


## The trip on this camera, made the first time it is asked for.
static func on(cam: Camera3D) -> Node:
	var found := cam.get_node_or_null("MushroomTrip")
	if found != null: return found
	var trip: Node = (load("res://commons/artifacts/mushroom_basket/mushroom_trip.gd") as GDScript).new()
	trip.name = "MushroomTrip"
	trip.set("camera", cam)
	cam.add_child(trip)
	return trip


func _ready() -> void:
	effect = Sight.new()
	if camera.compositor == null: camera.compositor = Compositor.new()
	var effects := camera.compositor.compositor_effects
	effects.append(effect)
	camera.compositor.compositor_effects = effects


## A mushroom of this kind was eaten.
func eat(kind: int) -> void:
	eaten += 1
	mode = posmod(kind, TITLES.size())
	peak = minf(1.0, maxf(strength, 0.0) + 0.75)
	since = -RISE * (strength / maxf(peak, 0.001))
	print("[mushroom] eaten: %s (amount up to %.2f)" % [TITLES[mode], peak])


func _process(delta: float) -> void:
	clock += delta
	if mode < 0: return
	since += delta
	if since < 0.0: strength = peak * (1.0 + since / RISE)
	elif since < HOLD: strength = peak
	elif since < HOLD + FADE: strength = peak * (1.0 - (since - HOLD) / FADE)
	else:
		strength = 0.0
		mode = -1
	var scale := HEADSET_SCALE if camera is XRCamera3D else 1.0
	effect.set_state(mode, clampf(strength, 0.0, 1.0) * scale, clock)


func state() -> Dictionary:
	return {"mode": mode, "title": TITLES[mode] if mode >= 0 else "", "strength": strength, "eaten": eaten, "effect_enabled": effect.enabled if effect != null else false}


func _exit_tree() -> void:
	if effect != null:
		effect.release()
		if is_instance_valid(camera) and camera.compositor != null:
			var effects := camera.compositor.compositor_effects
			effects.erase(effect)
			camera.compositor.compositor_effects = effects
