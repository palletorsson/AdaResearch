extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TugOfWar

## @identity
## lineage: the applied face of Addition — two ropes pull one load from different angles, and the
##   load moves along their sum. Vector addition you can feel in your arms.
## essence: forces add tip-to-tail; a + b is the single resultant pull, and the load tracks exactly
##   that diagonal — not either rope alone. Change an angle and the resultant swings.
## truth: forces add by walking, not by counting — the load goes where the sum points.

@export var f1_color: Color = Color(0.45, 0.72, 0.98)
@export var f2_color: Color = Color(0.98, 0.72, 0.32)
@export var sum_color: Color = Color(0.55, 0.95, 0.58)
@export var load_color: Color = Color(0.6, 0.64, 0.76)
## CARGO - WHAT THE TWO PULLS ARE ARGUING OVER. `block` is the shipped glow box;
## `crate` puts real museum freight on the ropes - the sum does not care what it
## moves. (Casting pass, 2026-08-27.)
@export_enum("block", "crate") var cargo: String = "block"
var _load: Node3D
var _vectors: Node3D
var _t: float = 0.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, -0.05, 0), Vector3(8, 0.08, 6), _matte_mat(Color(0.16, 0.17, 0.2), 0.9)))
	_load = Node3D.new(); add_child(_load)
	if cargo == "crate":
		var freight := _cast_prop("crate", 0.65)
		_load.add_child(freight)
		freight.position = Vector3(0, 0.35, 0)
	else:
		_load.add_child(_box(Vector3(0, 0.35, 0), Vector3(0.7, 0.7, 0.7), _glow_mat(load_color, 0.6)))
	_vectors = Node3D.new(); add_child(_vectors)
	add_child(_billboard_label("TUG OF WAR\na + b = resultant\nthe load goes where the sum points",
		Vector3(0, 2.6, 0), 26, sum_color.lerp(Color.WHITE, 0.3)))
	_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _load == null:
		return
	_t += delta
	_redraw()


func _redraw() -> void:
	var a1: float = deg_to_rad(35.0 + sin(_t * 0.5) * 20.0)            # one rope's angle drifts
	var a2: float = deg_to_rad(-40.0)
	var f1 := Vector3(cos(a1), 0, sin(a1)) * 1.4
	var f2 := Vector3(cos(a2), 0, sin(a2)) * 1.2
	var s: Vector3 = f1 + f2
	var lp: Vector3 = s.normalized() * (1.2 + sin(_t * 0.5) * 0.3)      # load drifts along the resultant
	_load.position = Vector3(lp.x, 0, lp.z)
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var o := _load.position + Vector3(0, 0.35, 0)
	_vectors.add_child(_arrow(o, o + f1, 0.05, _glow_mat(f1_color, 1.5)))
	_vectors.add_child(_arrow(o, o + f2, 0.05, _glow_mat(f2_color, 1.5)))
	_vectors.add_child(_arrow(o, o + s, 0.06, _glow_mat(sum_color, 1.8)))   # the resultant


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
