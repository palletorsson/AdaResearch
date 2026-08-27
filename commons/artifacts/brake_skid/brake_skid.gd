extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BrakeSkid

## @identity
## lineage: the applied face of Friction — a sled flung across the ground that skids to a stop, the
##   friction force dragging against its motion and laying down skid marks as it dies.
## essence: friction opposes velocity and is roughly constant, so the sled decelerates evenly and
##   travels v²/(2·µg) before stopping. The braking arrow always points back along the track.
## truth: friction is the world's brake — it spends a moving thing's speed against its direction.

@export var skid_color: Color = Color(0.45, 0.46, 0.52)
@export var vel_color: Color = Color(0.55, 0.92, 1.0)
@export var fric_color: Color = Color(0.98, 0.45, 0.42)
@export var sled_color: Color = Color(0.7, 0.74, 0.85)
## SLED - WHAT FRICTION IS STOPPING. `block` is the shipped glow box; `crate` and
## `vitrine` skid the museum's own cargo, because friction does not care what it
## stops - the same deceleration spends the same speed. (Casting pass, 2026-08-27.)
@export_enum("block", "crate", "vitrine") var sled: String = "block"
const STOP_DIST := 4.0
var _sled: Node3D
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
	add_child(_box(Vector3(STOP_DIST * 0.5, -0.05, 0), Vector3(STOP_DIST + 2.0, 0.1, 1.2), _matte_mat(Color(0.16, 0.17, 0.2), 0.95)))
	for i in range(int(STOP_DIST) + 1):                                    # distance ticks
		add_child(_box(Vector3(float(i), 0.01, 0), Vector3(0.03, 0.04, 1.0), _glow_mat(Color(0.38, 0.4, 0.48), 0.4)))
	_sled = Node3D.new(); add_child(_sled)
	match sled:
		"crate":
			var cargo := _cast_prop("crate", 0.55)
			_sled.add_child(cargo)
			cargo.position = Vector3(0, 0.28, 0)
		"vitrine":
			var showcase := _cast_prop("exhibit_vitrine", 0.62)
			_sled.add_child(showcase)
			showcase.position = Vector3(0, 0.33, 0)
		_:
			_sled.add_child(_box(Vector3(0, 0.25, 0), Vector3(0.6, 0.4, 0.7), _glow_mat(sled_color, 0.6)))
	_vectors = Node3D.new(); add_child(_vectors)
	add_child(_billboard_label("BRAKING\nfriction opposes motion\ndistance = v² / (2 µg)", Vector3(STOP_DIST * 0.5, 1.8, 0), 25, vel_color.lerp(Color.WHITE, 0.3)))
	_redraw(0.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _sled == null:
		return
	_t += delta * 0.35
	_redraw(fmod(_t, 1.3))                                                 # 1.0 of skid + 0.3 pause


func _redraw(p: float) -> void:
	var frac: float = clampf(p, 0.0, 1.0)
	var x: float = STOP_DIST * (2.0 * frac - frac * frac)                  # constant deceleration: fast, then easing to stop
	var v: float = 1.0 - frac                                              # speed bleeds to zero
	_sled.position = Vector3(x, 0, 0)
	# skid marks already laid (from 0 to current x)
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var marks := int(x / 0.35)
	for i in range(marks):                                                 # the skid trail behind the sled
		var mx: float = i * 0.35
		_vectors.add_child(_box(Vector3(mx, 0.015, 0.12), Vector3(0.18, 0.02, 0.06), _glow_mat(skid_color, 0.5)))
		_vectors.add_child(_box(Vector3(mx, 0.015, -0.12), Vector3(0.18, 0.02, 0.06), _glow_mat(skid_color, 0.5)))
	var o := Vector3(x, 0.45, 0)
	if v > 0.04:
		_vectors.add_child(_arrow(o, o + Vector3(v * 1.2, 0, 0), 0.05, _glow_mat(vel_color, 1.6)))        # velocity (shrinks)
		_vectors.add_child(_arrow(o + Vector3(0, 0.25, 0), o + Vector3(-0.7, 0.25, 0), 0.045, _glow_mat(fric_color, 1.5)))  # friction (opposes)


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
