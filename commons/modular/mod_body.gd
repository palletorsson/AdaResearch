class_name ModularBody
extends RefCounted
## Module: bodies and colliders. A `body` part in a compose makes the composed
## thing a StaticBody3D / RigidBody3D / Area3D; a `collider` part is a
## CollisionShape3D that must be the body's direct child (the builder sees to it).
## Every body carries meta `modular_body` so an engine can turn statics into
## rigids (physics_test: the box stays, the sphere falls).


static func make(kind: String) -> Node3D:
	var n: Node3D
	match kind:
		"rigid":
			var r := RigidBody3D.new()
			r.mass = 1.0
			n = r
		"area":
			n = Area3D.new()
		_:
			n = StaticBody3D.new()
	n.set_meta("modular_body", kind)
	return n


static func collider(spec: Dictionary) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.name = "collider"
	var size: Array = spec.get("size", [0.25])
	var s0: float = float(size[0]) if size.size() > 0 else 0.25
	match str(spec.get("shape", "sphere")):
		"box":
			var b := BoxShape3D.new()
			b.size = Vector3(s0, float(size[1]) if size.size() > 1 else s0, float(size[2]) if size.size() > 2 else s0)
			cs.shape = b
		"capsule":
			var c := CapsuleShape3D.new()
			c.radius = s0
			c.height = float(size[1]) if size.size() > 1 else s0 * 3.0
			cs.shape = c
		"cylinder":
			var cy := CylinderShape3D.new()
			cy.radius = s0
			cy.height = float(size[1]) if size.size() > 1 else s0 * 2.0
			cs.shape = cy
		_:
			var sp := SphereShape3D.new()
			sp.radius = s0
			cs.shape = sp
	if bool(spec.get("show", false)):
		# the collider drawn as a wire, the way the knowledge tree draws it
		var wire := MeshInstance3D.new()
		var m := SphereMesh.new()
		m.radius = s0
		m.height = s0 * 2.0
		m.radial_segments = 10
		m.rings = 6
		wire.mesh = m
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("3d7a3f")
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		wire.material_override = mat
		wire.set_meta("construction_mark", true)
		# a wireframe needs the debug draw mode; a thin transparent shell reads the same
		mat.albedo_color.a = 0.18
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cs.add_child(wire)
	return cs


## A box collider fitted to the meshes under a node (for a grabbable with none).
static func collider_for(node: Node3D) -> CollisionShape3D:
	var box := AABB()
	var first := true
	for m in _meshes(node):
		var a: AABB = (m as MeshInstance3D).transform * (m as MeshInstance3D).get_aabb()
		box = a if first else box.merge(a)
		first = false
	var cs := CollisionShape3D.new()
	cs.name = "collider_fitted"
	var b := BoxShape3D.new()
	b.size = box.size if not first else Vector3(0.3, 0.3, 0.3)
	cs.shape = b
	cs.position = box.get_center() if not first else Vector3.ZERO
	return cs


## Turn a static body into a rigid one in place (children and transform kept).
static func make_rigid(body: StaticBody3D) -> RigidBody3D:
	var r := RigidBody3D.new()
	r.name = body.name
	r.transform = body.transform
	r.mass = 1.0
	for key in ["term", "modular_body", "primitive", "cell"]:
		if body.has_meta(key):
			r.set_meta(key, body.get_meta(key))
	r.set_meta("modular_body", "rigid")
	var parent: Node = body.get_parent()
	for c in body.get_children():
		body.remove_child(c)
		r.add_child(c)
	if parent != null:
		var idx: int = body.get_index()
		parent.remove_child(body)
		parent.add_child(r)
		parent.move_child(r, idx)
	body.queue_free()
	return r


static func _meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out
