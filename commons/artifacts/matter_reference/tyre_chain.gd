extends "res://commons/artifacts/matter_reference/matter_reference.gd"
## Original tyre / loose plank / solid wedge / four-box stack.
var stack_contact := false
func _init() -> void:kind = "chain";graph_path = "res://commons/artifacts/matter_reference/chain.json"
func _ready() -> void:
	super._ready();button_visibility("X",false);button_visibility("Y",false)
	for id in bodies:
		if records[id].role=="stack" and bodies[id] is RigidBody3D:bodies[id].physics_material_override.friction = 0
	set_meta("void_preview_kind","Original chain geometry, compound tyre, convex wedge, loose plank and four cardboard boxes. Native Jolt contacts; pair friction is translated to per-body material. Guide releases only at actual stack contact.")
func reset_take() -> void:stack_contact = false;super.reset_take()
func contact(other: Node3D,id: String) -> void:
	if not running:return
	var other_id := str(other.name);hit_log.append({"at":elapsed,"a":id,"b":other_id})
	if id==graph.tyre and other_id in graph.stack:stack_contact = true;release_plane(id)
func output_bit() -> int:
	var top: Node3D = bodies[graph.stack[-1]]
	return int(stack_contact and homes[graph.stack[-1]].origin.y-to_local(top.global_position).y>.6)
