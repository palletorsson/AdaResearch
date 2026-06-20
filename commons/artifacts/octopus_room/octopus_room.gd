extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OctopusRoom

## @identity
## name: "Tentacle & octopus"
## tier: large
## lineage: A room-scale octopus — a soft mantle at the centre and eight curling arms reaching
##   out across the floor, each a sine-driven chain of segments. The skin shifts colour as it
##   moves, the way a real octopus runs chromatophore waves across itself.
## truth: "NO SKELETON, NOT A PUDDLE — THE QUEER BODY PAR EXCELLENCE"
## applications: soft robotics at scale, camouflage skins, distributed control, the octopus as a
##   model of a body that is all surface and all muscle and still holds together.

@export var room: float = 7.0
@export var arms: int = 8
@export var seg_per_arm: int = 12
@export var arm_len: float = 2.6
@export var coil_rate: float = 0.4
@export var floor_col: Color = Color(0.08, 0.10, 0.14)
@export var skin_a: Color = Color(0.75, 0.30, 0.55)
@export var skin_b: Color = Color(0.35, 0.55, 0.85)
@export var label_col: Color = Color(0.95, 0.96, 0.99)

var _t: float = 0.0
var _mantle: MeshInstance3D = null
var _mantle_mat: StandardMaterial3D = null
var _arm_mats: Array = []      # one material per arm (for colour shift)
var _arm_segs: Array = []      # Array of Array[MeshInstance3D]
var _mantle_pos := Vector3(0.0, 0.7, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("arms"):
		arms = int(clampf(float(config["arms"]), 4, 8))
	if config.has("arm_len"):
		arm_len = clampf(float(config["arm_len"]), 1.8, 3.2)
	if config.has("skin_a"):
		skin_a = _parse_color(config["skin_a"], skin_a)
	if config.has("skin_b"):
		skin_b = _parse_color(config["skin_b"], skin_b)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mantle = null
	_mantle_mat = null
	_arm_mats.clear()
	_arm_segs.clear()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room, 0.1, room), _matte_mat(floor_col, 0.9)))

	# Mantle — a big soft dome at the centre.
	_mantle_mat = _glow_mat(skin_a, 0.5)
	_mantle = _sphere(_mantle_pos, 0.75, _mantle_mat)
	add_child(_mantle)
	# Two eyes so the body reads as a creature, not a blob.
	add_child(_sphere(_mantle_pos + Vector3(0.3, 0.25, 0.6), 0.12, _glow_mat(Color(0.95, 0.95, 0.85), 0.8)))
	add_child(_sphere(_mantle_pos + Vector3(-0.3, 0.25, 0.6), 0.12, _glow_mat(Color(0.95, 0.95, 0.85), 0.8)))
	add_child(_sphere(_mantle_pos + Vector3(0.3, 0.25, 0.68), 0.05, _matte_mat(Color(0.05, 0.05, 0.06), 0.3)))
	add_child(_sphere(_mantle_pos + Vector3(-0.3, 0.25, 0.68), 0.05, _matte_mat(Color(0.05, 0.05, 0.06), 0.3)))

	# Eight arms radiating out, each its own material so the skin can shift independently.
	for a in range(arms):
		var ang: float = TAU * float(a) / float(arms)
		var mat := _glow_mat(skin_a, 0.4)
		_arm_mats.append(mat)
		var segs: Array = []
		for i in range(seg_per_arm):
			var f: float = float(i) / float(seg_per_arm - 1)
			var r: float = lerpf(0.18, 0.03, f)
			var seg := _sphere(Vector3.ZERO, r, mat)
			add_child(seg)
			segs.append(seg)
		_arm_segs.append({ "segs": segs, "ang": ang })

	_update_arms(0.0)

	add_child(_billboard_label("NO SKELETON, NOT A PUDDLE —\nTHE QUEER BODY PAR EXCELLENCE", Vector3(0.0, 3.6, 0.0), 25, label_col))


func _arm_point(ang: float, f: float, tt: float) -> Vector3:
	# Arm reaches outward along (cos,sin) with a sine curl down its length.
	var reach: float = f * arm_len
	var curl: float = sin(f * PI * 1.8 - tt * TAU * coil_rate + ang) * (0.3 + f * 0.5)
	var dir := Vector3(cos(ang), 0.0, sin(ang))
	var tangent := Vector3(-sin(ang), 0.0, cos(ang))
	var lift: float = sin(f * PI) * 0.5 + 0.15 - f * 0.1
	return _mantle_pos + Vector3(0.0, -0.2, 0.0) + dir * (0.6 + reach) + tangent * curl + Vector3(0.0, lift, 0.0)


func _update_arms(tt: float) -> void:
	for a in range(_arm_segs.size()):
		var entry: Dictionary = _arm_segs[a]
		var segs: Array = entry["segs"]
		var ang: float = entry["ang"]
		for i in range(segs.size()):
			var f: float = float(i) / float(seg_per_arm - 1)
			var seg: MeshInstance3D = segs[i]
			seg.position = _arm_point(ang, f, tt)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_update_arms(_t)
	# Skin colour shift — a chromatophore wave across mantle and arms.
	if _mantle_mat != null:
		var mix: float = sin(_t * 0.6) * 0.5 + 0.5
		var c: Color = skin_a.lerp(skin_b, mix)
		_mantle_mat.albedo_color = c
		_mantle_mat.emission = c
	for a in range(_arm_mats.size()):
		var mat: StandardMaterial3D = _arm_mats[a]
		var mix2: float = sin(_t * 0.6 - float(a) * 0.5) * 0.5 + 0.5
		var ac: Color = skin_a.lerp(skin_b, mix2)
		mat.albedo_color = ac
		mat.emission = ac
	# Mantle breathes a little.
	if _mantle != null:
		_mantle.scale = Vector3.ONE * (1.0 + sin(_t * 0.9) * 0.05)
