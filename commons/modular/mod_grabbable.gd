class_name ModularGrabbable
extends RefCounted
## Module: grabbable — the thing becomes an XR Tools pickable (a RigidBody3D the
## hands can take), the same object grab_sphere_point and the pick-up cube use.
## Without XR Tools (a stripped export) it degrades to a plain RigidBody3D.

const PICKABLE := "res://addons/godot-xr-tools/objects/pickable.tscn"


static func make() -> Node3D:
	var n: Node3D
	if ResourceLoader.exists(PICKABLE):
		var packed: PackedScene = load(PICKABLE)
		n = packed.instantiate()
		# the scene's own empty collider is replaced by the composition's
		for c in n.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape == null:
				c.free()
	else:
		var r := RigidBody3D.new()
		r.mass = 0.5
		n = r
	# It sits where it is put until a hand first takes it (XR Tools unfreezes a pickable on
	# drop): a grabbable at rest on a shelf, a bench or a capture stage must not fall through
	# the floor that is not there yet — the capture of mod_grab_sphere was 566 pixels of a
	# body that had left the frame before the shot (2026-10-24).
	if n is RigidBody3D:
		(n as RigidBody3D).freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		(n as RigidBody3D).freeze = true
	n.set_meta("modular_body", "grabbable")
	n.set_meta("grabbable", true)
	return n
