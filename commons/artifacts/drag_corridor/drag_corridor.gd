extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DragCorridor

## @identity
## lineage: the walk-in twin of drag_lane — a corridor of three media (air, water, honey).
##   Walk it and your own pace slows; a probe in each section glides and dies under F = −b·v,
##   the velocity decaying e^(−bt), so you feel the medium charge rent on speed.
## essence: drag is proportional to velocity and against it; the denser the medium the bigger
##   b, so the same launch goes far in air, less in water, barely a lunge in honey. The probes
##   freeze the decay stroboscopically — their velocity arrows shrink as they bunch up.
## truth: drag is the world charging you rent on speed — pay in honey, glide free in air.
##
## The large half of the drag_lane pair. Probes decay live in _process; while the player_body
## is in a section its velocity is damped by that medium's b (the slow you feel walking through).

const PLAYER_MASK := 524288
@export var length: float = 3.0                 # per-zone length (3 zones)
@export var floor_color: Color = Color(0.16, 0.17, 0.2)
## SWIMMER - WHAT THE MEDIA ARE CHARGING RENT. `dart` is the shipped glow sphere;
## `extinguisher` sends the museum's own body gliding through air, water and honey.
## (Casting pass, 2026-08-27.)
@export_enum("dart", "extinguisher") var swimmer: String = "dart"
# [name, drag b, tint]
const MEDIA := [
	["AIR",   0.4, Color(0.70, 0.85, 1.0)],
	["WATER", 1.3, Color(0.28, 0.58, 0.92)],
	["HONEY", 3.2, Color(0.96, 0.72, 0.22)],
]

var _probes: Array = []                         # [{node, vmat, b, x0, phase}]
var _areas: Array = []                          # [{area, b}]
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_physics_process(not Engine.is_editor_hint())
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("length"): length = float(config["length"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_probes.clear(); _areas.clear()
	_build()


func _build() -> void:
	var total := length * MEDIA.size()
	add_child(_box(Vector3(total * 0.5, -0.02, 0), Vector3(total + 0.4, 0.06, 2.4), _matte_mat(floor_color, 0.8)))
	for i in range(MEDIA.size()):
		var nm: String = MEDIA[i][0]
		var b: float = MEDIA[i][1]
		var tint: Color = MEDIA[i][2]
		var x0: float = i * length
		var cx: float = x0 + length * 0.5
		# the medium volume (translucent, denser = more opaque)
		add_child(_box(Vector3(cx, 1.1, 0), Vector3(length - 0.1, 2.2, 2.2), _medium(tint, 0.04 + b * 0.05)))
		add_child(_billboard_label("%s\nb = %.1f" % [nm, b], Vector3(cx, 2.6, 0), 24, tint.lerp(Color.WHITE, 0.3)))
		# a probe that glides + decays in this medium
		var probe := Node3D.new(); add_child(probe)
		var pm := _glow_mat(tint.lerp(Color.WHITE, 0.3), 1.4)
		if swimmer == "extinguisher":
			probe.add_child(_cast_prop("fire_extinguisher", 0.45))
		else:
			probe.add_child(_sphere(Vector3.ZERO, 0.14, pm))
		var vmat := _glow_mat(tint, 1.6)
		_probes.append({"node": probe, "vmat": vmat, "b": b, "x0": x0, "phase": 0.0})
		# a drag Area3D for the player
		var area := Area3D.new()
		area.collision_layer = 0; area.collision_mask = PLAYER_MASK
		area.position = Vector3(cx, 1.1, 0)
		var cs := CollisionShape3D.new(); var bx := BoxShape3D.new(); bx.size = Vector3(length, 2.2, 2.2); cs.shape = bx
		area.add_child(cs); add_child(area)
		_areas.append({"area": area, "b": b})

	add_child(_billboard_label("DRAG\nF = −b·v\nv ∝ e^(−bt)\nair → water → honey", Vector3(total * 0.5, 0.3, 1.4), 28, Color(0.7, 0.85, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for p in _probes:
		p["phase"] += delta
		var b: float = p["b"]
		if p["phase"] > 4.0:                          # relaunch
			p["phase"] = 0.0
		var ph: float = p["phase"]
		var v0 := 4.0
		var travel: float = (v0 / b) * (1.0 - exp(-b * ph))   # ∫ v0 e^(−bt) dt — asymptotes
		var x: float = p["x0"] + 0.25 + minf(travel, length - 0.5)
		var node: Node3D = p["node"]
		node.position = Vector3(x, 0.6, 0)
		# redraw the shrinking velocity arrow
		for c in node.get_children():
			if c is Node3D and c.name == "vel":
				node.remove_child(c); c.queue_free()
		var v: float = v0 * exp(-b * ph)
		if v > 0.1:
			var arr := _arrow(Vector3.ZERO, Vector3(v * 0.18, 0, 0), 0.03, p["vmat"])
			arr.name = "vel"
			node.add_child(arr)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for z in _areas:
		var area: Area3D = z["area"]
		for body in area.get_overlapping_bodies():
			if body is CharacterBody3D and "velocity" in body:
				body.set("velocity", body.get("velocity") * (1.0 - clampf(z["b"] * _delta, 0.0, 0.6)))   # the medium drags you


func _medium(tint: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = tint
	m.emission_energy_multiplier = 0.2 if emissive else 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## The casting pass (2026-08-27): load a museum prop, bead-normalised, internal
## rigids frozen. Returned UNPARENTED - the graft site positions it. Temporarily
## enters the tree so the prop's _ready builds before it is measured.
func _cast_prop(token: String, bead: float) -> Node3D:
	var wrapper := Node3D.new()
	add_child(wrapper)
	var packed: PackedScene = load("res://commons/artifacts/%s/%s.tscn" % [token, token])
	if packed == null:
		push_warning("%s: cast prop %s missing, bead substituted" % [name, token])
		var box := MeshInstance3D.new()
		box.mesh = BoxMesh.new()
		box.scale = Vector3.ONE * bead * 0.7
		wrapper.add_child(box)
		remove_child(wrapper)
		return wrapper
	var inst: Node3D = packed.instantiate()
	wrapper.add_child(inst)
	var pstack: Array = [inst]
	while not pstack.is_empty():
		var pn: Node = pstack.pop_back()
		if pn is RigidBody3D:
			(pn as RigidBody3D).freeze = true
		for pc in pn.get_children():
			pstack.append(pc)
	var to_local := inst.global_transform.affine_inverse()
	var merged := AABB()
	var first := true
	var mstack: Array = [inst]
	while not mstack.is_empty():
		var mn: Node = mstack.pop_back()
		if mn is MeshInstance3D:
			var mi := mn as MeshInstance3D
			var mbox: AABB = (to_local * mi.global_transform) * mi.get_aabb()
			merged = mbox if first else merged.merge(mbox)
			first = false
		for mc in mn.get_children():
			mstack.append(mc)
	var longest: float = maxf(merged.size.x, maxf(merged.size.y, merged.size.z))
	if longest > 0.001:
		var s: float = bead / longest
		inst.scale = Vector3.ONE * s
		inst.position = -(merged.get_center() * s)
	remove_child(wrapper)
	return wrapper
