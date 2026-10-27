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
	if mode=="live": return
	_capture_and_pause(root)
	root.visible=mode=="preview"
	if mode=="preview": _preview()

func refresh_pickables() -> void:
	pickables.clear()
	for node in root.find_children("*","RigidBody3D",true,false):
		if node.has_method("is_picked_up"): pickables.append(node)

func _capture_and_pause(node: Node) -> void:
	if node == root:
		# Flush queued placement transforms before DISABLED removes their Jolt space.
		for soft in root.find_children("*", "SoftBody3D", true, false):
			if soft.can_process(): soft.force_update_transform()
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
