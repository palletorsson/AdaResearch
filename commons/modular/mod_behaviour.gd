class_name ModularBehaviour
extends Node
## Module: an engine — what the grammar calls physics_engine(x), hand_movement(x),
## logic(x), sine, randomness, noise. Attached under the built thing, it reads
## the parts it needs (bodies tagged `modular_body`, sub-terms tagged `term`) and
## either changes them once (physics: statics become rigids; random / noise:
## seeded displacement; logic: the gate names) or animates them every frame
## (sine, sine_field, hand) or records what physics did (trace: a dotted path).

var kind: String = ""
var params: Dictionary = {}
var _targets: Array = []
var _homes: Array = []
var _t := 0.0
var _trace_from: Node3D = null
var _trace_last := Vector3.INF
var _trace_count := 0

const ModBody := preload("res://commons/modular/mod_body.gd")
const ModLabel := preload("res://commons/modular/mod_label.gd")


static func attach(root: Node3D, expr: Dictionary) -> Node:
	# the class name is not in the class cache on a fresh checkout: load self by path
	var b: Node = (load("res://commons/modular/mod_behaviour.gd") as GDScript).new()
	b.name = "engine"
	b.kind = str(expr.get("kind", ""))
	b.params = expr
	root.add_child(b)
	root.set_meta("engine", b.kind)
	return b


func _ready() -> void:
	var root: Node = get_parent()
	match kind:
		"physics", "trace":
			# the free bodies fall: every static sphere_collider becomes a rigid one —
			# deferred, because _ready runs while the composite is still adding children
			# and a swap of a child then fails ("parent node is busy setting up children")
			call_deferred("_free_the_bodies", root)
			if kind == "trace":
				set_process(true)
		"hand":
			for n in _terms(root, "sphere_collider"):
				_targets.append(n)
				_homes.append(n.position)
			_draw_path(_hand_path(), Color("7a4b8a"))
			set_process(true)
		"sine":
			for n in _terms(root, "sphere_collider"):
				_targets.append(n)
				_homes.append(n.position)
			set_process(true)
		"sine_field":
			for n in _terms(root, "sphere_collider"):
				_targets.append(n)
				_homes.append(n.position)
			set_process(true)
		"noise":
			var amp: float = float(params.get("amplitude", 0.2))
			var seed_v: int = int(params.get("seed", 1))
			for n in _terms(root, "sphere_collider"):
				var p: Vector3 = n.position
				n.position.y += amp * _noise2(p.x * 3.1 + seed_v, p.z * 2.7 - seed_v)
		"random":
			var rng := RandomNumberGenerator.new()
			rng.seed = int(params.get("seed", 1))
			var jitter: float = float(params.get("jitter", 0.2))
			for n in _terms(root, "cube"):
				n.position += Vector3(rng.randf_range(-jitter, jitter), rng.randf_range(0, jitter), rng.randf_range(-jitter, jitter))
				n.rotation.y = rng.randf_range(0, TAU)
				n.scale *= rng.randf_range(0.6, 1.2)
		"logic":
			var gates: Array = params.get("gates", ["not", "or", "xor", "true", "false"])
			for i in range(gates.size()):
				var l: Label3D = ModLabel.make(str(gates[i]), 0.004)
				l.position = Vector3(0.9, 0.2 + i * 0.16, 0)
				root.add_child.call_deferred(l)
		_:
			pass


func _process(delta: float) -> void:
	_t += delta
	match kind:
		"sine":
			var amp: float = float(params.get("amplitude", 0.25))
			var period: float = float(params.get("period", 2.0))
			for i in range(_targets.size()):
				var n: Node3D = _targets[i]
				if is_instance_valid(n):
					n.position = _homes[i] + Vector3(0, amp * sin(TAU * _t / period), 0)
		"sine_field":
			var amp: float = float(params.get("amplitude", 0.15))
			var period: float = float(params.get("period", 2.0))
			for i in range(_targets.size()):
				var n: Node3D = _targets[i]
				if is_instance_valid(n):
					var h: Vector3 = _homes[i]
					n.position = h + Vector3(0, amp * sin(h.x * 6.0 + TAU * _t / period) * cos(h.z * 6.0), 0)
		"hand":
			var path: PackedVector3Array = _hand_path()
			var f: float = fmod(_t / 4.0, 1.0)
			var idx: int = int(f * (path.size() - 1))
			for n in _targets:
				if is_instance_valid(n):
					n.position = path[idx]
		"trace":
			if _trace_from != null and is_instance_valid(_trace_from) and _trace_count < 80:
				var p: Vector3 = _trace_from.global_position
				if _trace_last == Vector3.INF or p.distance_to(_trace_last) > 0.04:
					_trace_last = p
					_trace_count += 1
					var dot := MeshInstance3D.new()
					var m := SphereMesh.new()
					m.radius = 0.012
					m.height = 0.024
					m.radial_segments = 6
					m.rings = 3
					dot.mesh = m
					var mat := StandardMaterial3D.new()
					mat.albedo_color = Color("3d7a3f")
					dot.material_override = mat
					dot.set_meta("construction_mark", true)
					dot.top_level = true
					add_child(dot)
					dot.global_position = p
		_:
			set_process(false)


func _free_the_bodies(root: Node) -> void:
	for body in _bodies(root):
		if body is StaticBody3D and str(body.get_meta("term", "")) == "sphere_collider":
			var r: RigidBody3D = ModBody.make_rigid(body)
			if _trace_from == null:
				_trace_from = r
	_tie_joints(root)


## The joint behind the tie (handover 24 Oct: "connect … instantiate an actual relation").
## Every node the builder marked "connect" carries its ties [a, b, kind] by index among its
## parts; under the physics engine each tie becomes a joint between the two parts' bodies:
##   rope   — a taut rope: a pin at the near end, the far end swings at the rope's length
##            (a pendulum, a hanging thing; slack is not modelled — Godot has no distance joint)
##   rod    — a rigid link: a 6-DOF joint with linear and angular play locked
##   spring — a 6-DOF joint with a linear spring on each axis, at rest where the parts stood
## A part without a body gets a static anchor at its place, so a rope can hang from a plank.
func _tie_joints(root: Node) -> void:
	for node in _connects(root):
		var kids: Array = []
		for c in node.get_children():
			if c is Node3D and not (c is Label3D) and not c.has_meta("tie") and not (c is Joint3D):
				kids.append(c)
		for t in node.get_meta("connect", []):
			if not (t is Array) or (t as Array).size() < 2:
				continue
			var ia: int = int(t[0])
			var ib: int = int(t[1])
			var kind: String = str(t[2]) if (t as Array).size() > 2 else "rope"
			if ia < 0 or ib < 0 or ia >= kids.size() or ib >= kids.size():
				continue
			var a: PhysicsBody3D = _body_for(kids[ia])
			var b: PhysicsBody3D = _body_for(kids[ib])
			if a == null or b == null or a == b:
				continue
			var pa: Vector3 = a.global_position
			var pb: Vector3 = b.global_position
			var length: float = pa.distance_to(pb)
			var joint: Joint3D
			match kind:
				"rod":
					# a rigid link: the far end keeps its place in the near end's frame
					var g := Generic6DOFJoint3D.new()
					g.global_position = pa
					for ax in ["x", "y", "z"]:
						g.call("set_flag_" + ax, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
						g.call("set_flag_" + ax, Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -0.1)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.1)
					joint = g
				"spring":
					# a linear spring on each axis, at rest where the parts stand now
					var g := Generic6DOFJoint3D.new()
					g.global_position = pa
					var rest: Vector3 = pb - pa
					var comps := {"x": rest.x, "y": rest.y, "z": rest.z}
					for ax in ["x", "y", "z"]:
						g.call("set_flag_" + ax, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
						g.call("set_flag_" + ax, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 40.0)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 2.0)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, float(comps[ax]))
					joint = g
				_:
					# rope: a taut rope — the far end swings about the near end at the rope's length
					# (slack is not modelled: Godot has no distance joint; the pin sits at the near end)
					var pin := PinJoint3D.new()
					pin.global_position = pa
					joint = pin
			joint.name = "joint_%s_%d_%d" % [kind, ia, ib]
			node.add_child(joint)
			joint.node_a = joint.get_path_to(a)
			joint.node_b = joint.get_path_to(b)
			joint.set_meta("tie_joint", {"a": ia, "b": ib, "kind": kind, "length": length})


func _connects(n: Node) -> Array:
	var out: Array = []
	if n.has_meta("connect"):
		out.append(n)
	for c in n.get_children():
		out.append_array(_connects(c))
	return out


## The body a tie attaches to: the part itself, its first body inside, or a static anchor
## made at its place when it has none (a plain mesh can still hold a rope).
func _body_for(part: Node3D) -> PhysicsBody3D:
	if part is PhysicsBody3D:
		return part
	var stack: Array = [part]
	while not stack.is_empty():
		var c: Node = stack.pop_front()
		if c is PhysicsBody3D:
			return c
		for k in c.get_children():
			stack.append(k)
	var anchor := StaticBody3D.new()
	anchor.name = "anchor"
	part.add_child(anchor)
	anchor.set_meta("tie_anchor", true)
	return anchor


func _hand_path() -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in range(41):
		var u: float = i / 40.0
		pts.append(Vector3(-0.6 + 1.2 * u, 0.25 * sin(u * 6.3) + 0.3, 0.15 * cos(u * 4.0)))
	return pts


func _draw_path(path: PackedVector3Array, color: Color) -> void:
	for i in range(0, path.size(), 2):
		var dot := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = 0.012
		m.height = 0.024
		m.radial_segments = 6
		m.rings = 3
		dot.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		dot.material_override = mat
		dot.set_meta("construction_mark", true)
		dot.position = path[i]
		get_parent().add_child.call_deferred(dot)


func _bodies(n: Node) -> Array:
	var out: Array = []
	if n.has_meta("modular_body"):
		out.append(n)
	for c in n.get_children():
		out.append_array(_bodies(c))
	return out


func _terms(n: Node, term: String) -> Array:
	var out: Array = []
	if n is Node3D and str(n.get_meta("term", "")) == term:
		out.append(n)
		return out   # do not descend into a found term
	for c in n.get_children():
		out.append_array(_terms(c, term))
	return out


static func _noise2(x: float, y: float) -> float:
	# a cheap deterministic value noise, enough for a displaced grid
	var ix := floorf(x)
	var iy := floorf(y)
	var fx := x - ix
	var fy := y - iy
	var a := _hash(ix, iy)
	var b := _hash(ix + 1, iy)
	var c := _hash(ix, iy + 1)
	var d := _hash(ix + 1, iy + 1)
	var ux := fx * fx * (3.0 - 2.0 * fx)
	var uy := fy * fy * (3.0 - 2.0 * fy)
	return lerpf(lerpf(a, b, ux), lerpf(c, d, ux), uy) * 2.0 - 1.0


static func _hash(x: float, y: float) -> float:
	var h: float = sin(x * 127.1 + y * 311.7) * 43758.5453
	return h - floorf(h)
