extends RefCounted
## Pause a visited floor without discarding its ink, object identity or changed cells.
## Preview keeps frozen physical supports, but no timers, hazards or viewport rendering.
var root: Node3D
var building: Node3D
var mode := "live"
var saved: Dictionary = {}
var pickables: Array[Node3D] = []
var preview_units := 0
var needs_refresh := true

func _init(host: Node3D, frame: Node3D) -> void:
	root=host;building=frame

func set_mode(next: String) -> void:
	if next==mode and not needs_refresh: return
	needs_refresh=false
	if next!=mode:
		_restore()
		mode=next
	_watch_soft_births(mode=="preview")
	if mode=="live": return
	_capture_and_pause(root)
	root.visible=mode=="preview"
	if mode=="preview": _preview()

## One new work on this floor (floor_stream._built): its pickables, and paused / filtered for the preview like the rest,
## without walking the floor again.
func adopt(unit: Node3D) -> void:
	for node in unit.find_children("*","RigidBody3D",true,false):
		if node.has_method("is_picked_up"): pickables.append(node)
	if mode=="live": return
	# At frame end, after the work's own deferred setup: a pin takes its offset from the live points (soft_mushrooms,
	# revolving_joy_ride pin by call_deferred). A body born here is still in the solver until then (_soft_born).
	_hold_soft_bodies.call_deferred(unit)
	_capture_and_pause(unit)
	if mode!="preview": return
	var artifact := unit.get_node_or_null("Artifact")
	if artifact!=null and "part_defaults" in artifact:
		for part in artifact.get_children():
			if part is Node3D: _show_unit(part)
	else: _show_unit(unit)

func refresh_pickables() -> void:
	pickables.clear()
	for node in root.find_children("*","RigidBody3D",true,false):
		if node.has_method("is_picked_up"): pickables.append(node)

## A paused SoftBody3D leaves Jolt (DISABLE_MODE_REMOVE), and on return Jolt rebuilds it from its render mesh. A body
## never drawn comes back at the mesh's own coordinates - the world origin: rounded_softbody_test stood 876 m above
## floor 144 on every arrival from floor 143 (14 of 14), and walking down floors 139-146 left 127 of 127 soft bodies
## off their floor (2026-11-09). So each body's solver points are kept here at pause and put back after the rebuild.
## A floor without soft bodies keeps nothing.
var held_points: Dictionary = {}

## The floor below builds its works one per frame while it is paused (floor_content._process builds only the focus
## and the floor below). Each is mounted live and then set to INHERIT, which takes its soft bodies out of Jolt before
## adopt() can keep their points: a body born here stays in the solver (KEEP_ACTIVE) until _hold_soft_bodies.
func _watch_soft_births(on: bool) -> void:
	var tree := root.get_tree() if is_instance_valid(root) else null
	if tree == null: return
	if on and not tree.node_added.is_connected(_soft_born): tree.node_added.connect(_soft_born)
	elif not on and tree.node_added.is_connected(_soft_born): tree.node_added.disconnect(_soft_born)

func _soft_born(node: Node) -> void:
	if not is_instance_valid(root):
		node.get_tree().node_added.disconnect(_soft_born); return
	if node is SoftBody3D and root.is_ancestor_of(node):
		(node as SoftBody3D).disable_mode = SoftBody3D.DISABLE_MODE_KEEP_ACTIVE

func _hold_soft_bodies(host: Node) -> void:
	# A deferred hold after the floor went live keeps nothing: there is no pause for it to outlast.
	if mode=="live" or not is_instance_valid(host): return
	for found in host.find_children("*", "SoftBody3D", true, false):
		var soft := found as SoftBody3D
		# Flush queued placement transforms before DISABLED removes their Jolt space.
		if soft.can_process(): soft.force_update_transform()
		# Only a body still in the solver has points to keep; a removed one reads as zeros.
		var in_solver := soft.can_process() or soft.disable_mode == SoftBody3D.DISABLE_MODE_KEEP_ACTIVE
		var rid: RID = soft.get_physics_rid()
		if not in_solver or soft.mesh == null or soft.mesh.get_surface_count() == 0 or not PhysicsServer3D.soft_body_get_space(rid).is_valid(): continue
		if soft.get_meta("void_held_mesh", RID()) != soft.mesh.get_rid():
			# Jolt omits mesh vertices no face uses; querying them is an error (tools/probes/export_void_editor.gd).
			var arrays: Array = soft.mesh.surface_get_arrays(0)
			var used := PackedInt32Array()
			if arrays[Mesh.ARRAY_INDEX] == null:
				for i in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(): used.append(i)
			else:
				var seen := {}
				for i in (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array): seen[i] = true
				used = PackedInt32Array(seen.keys())
			soft.set_meta("void_held_indices", used); soft.set_meta("void_held_mesh", soft.mesh.get_rid())
		var indices: PackedInt32Array = soft.get_meta("void_held_indices")
		var points := PackedVector3Array(); points.resize(indices.size())
		var box := AABB()
		for k in indices.size():
			points[k] = PhysicsServer3D.soft_body_get_point_global_position(rid, indices[k])
			box = AABB(points[k], Vector3.ZERO) if k == 0 else box.expand(points[k])
		if box.size.length() > 0.001:
			held_points[soft.get_instance_id()] = {"node": weakref(soft), "mesh": soft.mesh.get_rid(), "points": points}
		# Paused, it leaves the solver as it always has: nothing simulates or draws until the floor is live.
		soft.disable_mode = SoftBody3D.DISABLE_MODE_REMOVE

func _release_soft_bodies() -> void:
	for id in held_points:
		var soft := held_points[id].node.get_ref() as SoftBody3D
		if soft == null or not soft.is_inside_tree() or soft.mesh == null or soft.mesh.get_rid() != held_points[id].mesh: continue
		var rid: RID = soft.get_physics_rid()
		if not soft.can_process() or not PhysicsServer3D.soft_body_get_space(rid).is_valid(): continue
		var indices: PackedInt32Array = soft.get_meta("void_held_indices")
		var points: PackedVector3Array = held_points[id].points
		for k in mini(indices.size(), points.size()): PhysicsServer3D.soft_body_move_point(rid, indices[k], points[k])
	held_points.clear()

func _capture_and_pause(node: Node) -> void:
	if node == root: _hold_soft_bodies(root)
	# Procedural artifacts may rebuild/free children while a floor is loading.
	# Object keys change identity when freed, which can break Dictionary iteration.
	# Stable IDs + weak references let restoration safely skip deleted children.
	var id := node.get_instance_id()
	if not saved.has(id):
		var state := {"node":weakref(node),"mode":node.process_mode}
		state.flight_group=node.is_in_group("ada_museum_flight")
		if node is Node3D: state.visible=node.visible
		if node is CollisionObject3D: state.disable=node.disable_mode
		if node is RigidBody3D:
			state.freeze=node.freeze;state.sleeping=node.sleeping
			state.velocity=node.linear_velocity;state.spin=node.angular_velocity
		if node is SubViewport: state.update=node.render_target_update_mode
		if node is GPUParticles3D or node is CPUParticles3D: state.speed=node.speed_scale
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D: state.paused=node.stream_paused
		saved[id]=state
	# Desktop and XR look up flight by group even when this floor is paused.
	# Withdraw inactive volumes and restore membership when their floor is live.
	if node.is_in_group("ada_museum_flight"): node.remove_from_group("ada_museum_flight")
	# Explicit modes also stop artifacts that opt into PROCESS_MODE_ALWAYS.
	if node is CollisionObject3D:
		node.disable_mode=CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE if mode=="preview" and node is PhysicsBody3D else CollisionObject3D.DISABLE_MODE_REMOVE
	if node is RigidBody3D: node.freeze=true
	if node is SubViewport: node.render_target_update_mode=SubViewport.UPDATE_DISABLED
	if node is GPUParticles3D or node is CPUParticles3D: node.speed_scale=0.0
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.stream_paused=true
	node.process_mode=Node.PROCESS_MODE_DISABLED
	# A visible shaft preview is scenery; its lamps must not illuminate the
	# current floor or spend shadow maps. _restore restores authored visibility.
	if node is Light3D: node.visible=false
	for child in node.get_children(): _capture_and_pause(child)

func _restore() -> void:
	for id in saved:
		var state: Dictionary=saved[id]
		var node: Node=state.node.get_ref()
		if not is_instance_valid(node): continue
		if node is Node3D: node.visible=state.visible
		if node is CollisionObject3D: node.disable_mode=state.disable
		if node is RigidBody3D:
			node.freeze=state.freeze;node.sleeping=state.sleeping
			node.linear_velocity=state.velocity;node.angular_velocity=state.spin
		if node is SubViewport: node.render_target_update_mode=state.update
		if node is GPUParticles3D or node is CPUParticles3D: node.speed_scale=state.speed
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.stream_paused=state.paused
		node.process_mode=state.mode
		if state.get("flight_group",false): node.add_to_group("ada_museum_flight")
	saved.clear()
	_release_soft_bodies()

func _preview() -> void:
	preview_units=0
	for child in root.get_children():
		if not child is Node3D: continue
		var artifact := child.get_node_or_null("Artifact")
		if artifact!=null and "part_defaults" in artifact:
			# Large work areas are filtered per authored part, including editor copies.
			for part in artifact.get_children():
				if part is Node3D: _show_unit(part)
		else: _show_unit(child)

func _show_unit(unit: Node3D) -> void:
	var bounds := _bounds(unit)
	var near := false
	if bounds.has_surface():
		var footprint := Rect2(bounds.position.x,bounds.position.z,bounds.size.x,bounds.size.z).grow(0.01)
		for shaft in building.spec.shafts:
			# 1.5m beyond the opening includes rails, beams and the landing invitation.
			var opening := Rect2(float(shaft.x)-float(building.spec.shaft_width)/2,-float(building.spec.shaft_depth)/2,float(building.spec.shaft_width),float(building.spec.shaft_depth)).grow(1.5)
			if footprint.intersects(opening): near=true;break
	unit.visible=bool(saved[unit.get_instance_id()].visible) and near
	# Only the visible shaft supports need physics in the frozen preview.
	if not unit.visible: _remove_preview_physics(unit)
	if unit.visible: preview_units+=1

func _remove_preview_physics(node: Node) -> void:
	if node is CollisionObject3D: node.disable_mode=CollisionObject3D.DISABLE_MODE_REMOVE
	for child in node.get_children(): _remove_preview_physics(child)

func _bounds(node: Node3D) -> AABB:
	var result := AABB()
	if node is VisualInstance3D:
		result=(building.global_transform.affine_inverse()*node.global_transform)*node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var b := _bounds(child)
			if b.has_surface(): result=b if not result.has_surface() else result.merge(b)
	return result
