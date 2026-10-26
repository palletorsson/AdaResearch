class_name ModularBehaviour
extends Node
## Module: an engine — what the grammar calls physics_engine(x), hand_movement(x),
## logic(x), sine, randomness, noise. Attached under the built thing, it reads
## the parts it needs (bodies tagged `modular_body`, sub-terms tagged `term`) and
## either changes them once (physics: statics become rigids; random / noise:
## seeded displacement; logic: the gate names) or animates them every frame
## (sine, sine_field, hand, tween) or records what physics did (trace: a dotted path).
## tween is the transform's time domain: what a transform states once (at, rot, scale) it plays
## over a period, from where the thing was made to where it is put, and back.

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


static func _vec3(v: Variant, fill: float) -> Vector3:
	if v is Array and (v as Array).size() >= 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3(fill, fill, fill)


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
			if kind == "trace" or not _connects(root).is_empty():
				set_process(true)   # a trace draws; ties must follow the bodies they join
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
		"tween":
			for c in root.get_children():
				if c != self and c is Node3D:
					_targets.append(c)
					_homes.append((c as Node3D).transform)
			set_process(true)
		"sine_field":
			for n in _terms(root, "sphere_collider"):
				_targets.append(n)
				_homes.append(n.position)
			set_process(true)
		"noise":
			var amp: float = float(params.get("amplitude", 0.2))
			var seed_v: int = int(params.get("seed", 1))
			var fr: float = float(params.get("frequency", 1.0))   # an octave: the same noise, read finer or coarser
			for n in _terms(root, "sphere_collider"):
				var p: Vector3 = n.position
				n.position.y += amp * _noise2(p.x * 3.1 * fr + seed_v, p.z * 2.7 * fr - seed_v)
		"random":
			var rng := RandomNumberGenerator.new()
			rng.seed = int(params.get("seed", 1))
			var jitter: float = float(params.get("jitter", 0.2))
			var lift: float = float(params.get("lift", jitter))
			var turn: bool = bool(params.get("turn", true))
			var vary: bool = bool(params.get("vary_scale", true))
			# which term is jittered: cube by default (random_cubes), any term by name (a field of cones)
			for n in _terms(root, str(params.get("term", "cube"))):
				n.position += Vector3(rng.randf_range(-jitter, jitter), rng.randf_range(0, lift), rng.randf_range(-jitter, jitter))
				var angles: Array = params.get("angles", [])
				if not angles.is_empty():
					n.rotation.y = deg_to_rad(float(angles[rng.randi() % angles.size()]))   # one of a few turns, not any turn
				elif turn:
					n.rotation.y = rng.randf_range(0, TAU)
				if vary:
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
	if kind == "physics" or kind == "trace":
		_follow_ties()
	if kind == "physics":
		return   # nothing else per frame; the default branch below would switch processing off
	match kind:
		"tween":
			var ph: float = 0.5 - 0.5 * cos(TAU * _t / float(params.get("period", 4.0)))
			var at_v: Vector3 = _vec3(params.get("at", null), 0.0)
			var rot_v: Vector3 = _vec3(params.get("rot", null), 0.0) * (PI / 180.0)
			var sc: Variant = params.get("scale", 1.0)
			var s_v: Vector3 = _vec3(sc, 1.0) if sc is Array else Vector3.ONE * float(sc)
			var b := Basis.from_euler(rot_v * ph).scaled(Vector3.ONE.lerp(s_v, ph))
			for i in range(_targets.size()):
				var n: Node3D = _targets[i]
				if is_instance_valid(n):
					n.transform = Transform3D(b, at_v * ph) * (_homes[i] as Transform3D)
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
	# which terms fall: sphere_collider by default; a machine names its own movers
	# ("free": ["ball", "brick", "domino"]) so a domino or a brick can fall too
	var free: Array = params.get("free", ["sphere_collider"])
	for body in _bodies(root):
		if body is StaticBody3D and free.has(str(body.get_meta("term", ""))):
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
##   spring — a 6-DOF joint with a linear spring on each axis, at rest where the parts stood;
##            for a PAIR — a mesh of sixty springs between free bodies blew a net to ten metres
##            (2026-10-25), so a net is tied with ropes, which cannot stretch and cannot explode
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
					node.add_child(g)
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
					node.add_child(g)
					g.global_position = pa
					# the equilibrium is measured from where the joint starts, so 0 is "as they stand now"; giving it
					# pb - pa counted the offset twice and swung the ball through the floor (spring_oscillator, 26 Oct)
					for ax in ["x", "y", "z"]:
						g.call("set_flag_" + ax, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
						g.call("set_flag_" + ax, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, float(t[3]) if (t as Array).size() > 3 else 40.0)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, float(t[4]) if (t as Array).size() > 4 else 4.0)
						g.call("set_param_" + ax, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_EQUILIBRIUM_POINT, 0.0)
					joint = g
				_:
					# rope: a taut rope — the far end swings about the near end at the rope's length
					# (slack is not modelled: Godot has no distance joint; the pin sits at the near end)
					var pin := PinJoint3D.new()
					node.add_child(pin)
					pin.global_position = pa   # set AFTER add_child: a parent's offset would move it otherwise (the net fell through its block, 2026-10-25)
					joint = pin
			joint.name = "joint_%s_%d_%d" % [kind, ia, ib]
			joint.node_a = joint.get_path_to(a)
			joint.node_b = joint.get_path_to(b)
			joint.set_meta("tie_joint", {"a": ia, "b": ib, "kind": kind, "length": length})


## The drawn ties follow the bodies they join, so a net under physics looks like a net.
func _follow_ties() -> void:
	for node in _connects(get_parent()):
		var kids: Array = []
		var ties: Array = []
		for c in node.get_children():
			if c.has_meta("tie"):
				ties.append(c)
			elif c is Node3D and not (c is Label3D) and not (c is Joint3D):
				kids.append(c)
		for tie in ties:
			var t: Dictionary = tie.get_meta("tie")
			var ia: int = int(t.get("a", 0))
			var ib: int = int(t.get("b", 1))
			if ia >= kids.size() or ib >= kids.size():
				continue
			var a: Node3D = _body_in(kids[ia])
			var b: Node3D = _body_in(kids[ib])
			var pa: Vector3 = a.global_position
			var pb: Vector3 = b.global_position
			var d: Vector3 = pb - pa
			var length: float = d.length()
			if length < 0.0001:
				continue
			var m: MeshInstance3D = tie as MeshInstance3D
			if m != null and m.mesh is CylinderMesh:
				(m.mesh as CylinderMesh).height = length
			m.global_position = (pa + pb) * 0.5
			var up: Vector3 = Vector3.UP
			var dir: Vector3 = d / length
			if abs(up.dot(dir)) < 0.999:
				var axis: Vector3 = up.cross(dir).normalized()
				m.global_rotation = Quaternion(axis, acos(clamp(up.dot(dir), -1.0, 1.0))).get_euler()
			else:
				m.global_rotation = Vector3(PI if up.dot(dir) < 0 else 0.0, 0, 0)


## The body inside a part, without making one (for following): the part, or its first body.
func _body_in(part: Node3D) -> Node3D:
	if part is PhysicsBody3D:
		return part
	var stack: Array = [part]
	while not stack.is_empty():
		var c: Node = stack.pop_front()
		if c is PhysicsBody3D:
			return c
		for k in c.get_children():
			stack.append(k)
	return part


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
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 0.01
	cs.shape = sp
	cs.disabled = true   # a pin, not an obstacle
	anchor.add_child(cs)
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
