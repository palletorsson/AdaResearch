extends Node3D
## Local, reversible change of visitor scale. The heightfield never changes size.
## Detection uses feet, independent of the desktop/XR collision-layer convention.
const Kit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const FACTOR := 0.125
const ENTRY := Vector3(-2,1,-4.4)
const RETURN_XZ := Vector2(-2,-3.94)
const LAND_XZ := Vector2(-2,-3.55)
const FEEL_KEYS := ["walk_speed","sprint_speed","ground_accel","ground_decel","turn_accel","stop_snap_speed","step_length_walk","step_length_sprint","land_reference_speed"]
var ground: Node3D
var actor: CharacterBody3D
var active := false
var saved := {}
var _small_door: Node3D
var _pivot: Node3D
var _museum: Node
var _feel: Node
var _wait_frames := 0
var _cooldown := 0.0
var _armed := true
var transitions := 0

func build(owner_ground: Node3D) -> void:
	name = "ScalePortals"
	ground = owner_ground
	_door("EnterSmall",ENTRY,1.0,"SMALLER\nWalk through / 1:8",Color(0.3,0.9,1))
	_small_door = _door("ReturnDoor",Vector3.ZERO,FACTOR,"RETURN\nYour size",Color(1,0.55,0.75))
	refresh()
	var beacon := Node3D.new();beacon.position = Vector3(-2.32,1,-3.94);add_child(beacon)
	beacon.add_child(Kit.box(Vector3(0,0.7,0),Vector3(0.018,1.4,0.018),Kit.emissive(Color(1,0.4,0.65),0.7)))
	var sign := Label3D.new();sign.text = "RETURN";sign.font_size=32;sign.pixel_size=.0018
	sign.position=Vector3(0,1.5,0);sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;beacon.add_child(sign)

func _door(label: String, at: Vector3, size: float, words: String, colour: Color) -> Node3D:
	var door := Node3D.new();door.name=label;door.position=at;door.scale=Vector3.ONE*size;add_child(door)
	var mat := Kit.emissive(colour,0.65)
	for side in [-1,1]:
		door.add_child(Kit.box(Vector3(side*.55,1.05,0),Vector3(.09,2.1,.13),mat))
	door.add_child(Kit.box(Vector3(0,2.12,0),Vector3(1.19,.1,.13),mat))
	# Transparent threshold, no sill or invisible solid panel to trip over.
	var veil := StandardMaterial3D.new();veil.albedo_color=Color(colour,.08)
	veil.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;veil.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	veil.cull_mode=BaseMaterial3D.CULL_DISABLED
	door.add_child(Kit.box(Vector3(0,1.05,0),Vector3(1,2.1,.005),veil))
	var text := Label3D.new();text.text=words;text.font_size=40;text.pixel_size=.0016
	if size < 1.0: text.font_size=64;text.pixel_size=.004
	text.position=Vector3(0,2.43,0);text.billboard=BaseMaterial3D.BILLBOARD_ENABLED;door.add_child(text)
	return door

func refresh() -> void:
	if _small_door != null:
		_small_door.position=Vector3(RETURN_XZ.x,ground.walk_height_at(RETURN_XZ),RETURN_XZ.y)

func _visitors() -> Array:
	var bodies: Array = get_tree().get_nodes_in_group("em_walker")
	for body in get_tree().get_nodes_in_group("player_body"):
		if body not in bodies: bodies.append(body)
	return bodies

func _physics_process(delta: float) -> void:
	if ground == null: return
	_cooldown=maxf(0,_cooldown-delta)
	if active:
		if not is_instance_valid(actor):
			restore(false);return
		if _wait_frames>0:
			_wait_frames-=1
			if _wait_frames==0:
				_place(Vector3(LAND_XZ.x,ground.walk_height_at(LAND_XZ)+.006,LAND_XZ.y))
				if actor is XRToolsPlayerBody: actor.enabled=saved.enabled
			return
		var p: Vector3 = ground.to_local(actor.global_position)
		if absf(p.x)>4.12 or absf(p.z)>4.12 or p.y<-.15 or p.y>5:
			restore();return
		var q := p-_small_door.position
		if _cooldown<=0 and absf(q.x)<.09 and absf(q.z)<.09 and absf(q.y)<.15:
			restore()
		return
	var near := false
	for body in _visitors():
		if not body is CharacterBody3D: continue
		var p: Vector3 = ground.to_local(body.global_position)-ENTRY
		if absf(p.x)<.47 and absf(p.z)<.17 and absf(p.y)<.22:
			near=true
			if _armed and _cooldown<=0 and not body.has_meta("ada_scale_owner"):
				enter(body);break
	if not near: _armed=true

func enter(body: CharacterBody3D) -> bool:
	if active or body.has_meta("ada_scale_owner"): return false
	if body is XRToolsPlayerBody and (not is_instance_valid(body.camera_node) or not is_instance_valid(body.origin_node)): return false
	actor=body;active=true;_armed=false;transitions+=1
	saved={"snap":body.floor_snap_length,"margin":body.safe_margin,"children":[],"shapes":[],"feel":{}}
	body.set_meta("ada_scale_owner",get_instance_id())
	body.set_meta("ada_body_scale",FACTOR)
	body.floor_snap_length*=FACTOR;body.safe_margin*=FACTOR
	if body is XRToolsPlayerBody:
		saved.world_scale=XRServer.world_scale;saved.enabled=body.enabled
		var adapter: Node3D = load("res://commons/movement/miniature_gravity_provider.gd").new()
		adapter.name="MiniatureGravity";adapter.receiver=body;adapter.factor=FACTOR
		body.add_child(adapter);body._movement_providers.append(adapter)
		body._movement_providers.sort_custom(body.sort_by_order);saved.adapter=adapter
		saved.camera_near=body.camera_node.near
		saved.xr_capsule_height=body._collision_node.shape.height
		saved.xr_capsule_radius=body._collision_node.shape.radius
		saved.xr_capsule_position=body._collision_node.position
		body.enabled=false
		XRServer.world_scale=saved.world_scale*FACTOR
		body.camera_node.near=saved.camera_near*FACTOR
		# The tracked camera/controllers receive world_scale on their next update.
		# No rig transform scaling: XRTools sizes collision and direct speed itself.
		_wait_frames=3
	else:
		_museum=body.get_parent()
		_feel=_museum.get("_feel") if "_feel" in _museum else null
		if is_instance_valid(_feel):
			for key in FEEL_KEYS:
				saved.feel[key]=_feel.get(key);_feel.set(key,float(_feel.get(key))*FACTOR)
		_pivot=Node3D.new();_pivot.name="MiniatureView"
		var children := body.get_children();body.add_child(_pivot);_pivot.scale=Vector3.ONE*FACTOR
		for child in children:
			if child is CollisionShape3D and child.shape is CapsuleShape3D:
				saved.shapes.append({"node":child,"shape":child.shape,"position":child.position})
				child.shape=child.shape.duplicate();child.shape.radius*=FACTOR;child.shape.height*=FACTOR
				child.position*=FACTOR
			elif child is Node3D and not child is CollisionObject3D and not child is CollisionShape3D:
				saved.children.append(child);child.reparent(_pivot,false)
				if child is Camera3D:
					saved.camera=child;saved.camera_near=child.near;child.near*=FACTOR
		_place(Vector3(LAND_XZ.x,ground.walk_height_at(LAND_XZ)+.006,LAND_XZ.y))
	ground.walk_study.walked_trail.clear()
	_cooldown=.7
	return true

func _place(local_feet: Vector3) -> void:
	if not is_instance_valid(actor): return
	var pose := actor.global_transform;pose.origin=ground.to_global(local_feet)
	if actor is XRToolsPlayerBody: actor.teleport(pose)
	else: actor.global_transform=pose
	actor.velocity=Vector3.ZERO
	if is_instance_valid(_museum):
		if "_vy" in _museum: _museum.set("_vy",0.0)
		if "_last_ground" in _museum: _museum.set("_last_ground",actor.position)
	if is_instance_valid(_feel) and _feel.has_method("teleported"): _feel.teleported()

func restore(relocate: bool = true) -> void:
	if not active: return
	active=false;_wait_frames=0;_cooldown=1.0;transitions+=1
	# XRServer is global; release it even if the body was freed before the hall.
	if saved.has("world_scale"): XRServer.world_scale=saved.world_scale
	if is_instance_valid(actor):
		actor.floor_snap_length=saved.snap;actor.safe_margin=saved.margin
		actor.remove_meta("ada_body_scale");actor.remove_meta("ada_scale_owner")
		if actor is XRToolsPlayerBody:
			actor.enabled=saved.enabled
			# Grow height before radius: CapsuleShape clamps radius to half its height.
			# Waiting for XRTools' height slew would leave an undersized collider on exit.
			actor._collision_node.shape.height=saved.xr_capsule_height
			actor._collision_node.shape.radius=saved.xr_capsule_radius
			actor._collision_node.position=saved.xr_capsule_position
			if saved.has("adapter") and is_instance_valid(saved.adapter):
				actor._movement_providers.erase(saved.adapter);saved.adapter.enabled=false;saved.adapter.queue_free()
			if is_instance_valid(actor.camera_node): actor.camera_node.near=saved.camera_near
		else:
			for record in saved.shapes:
				if is_instance_valid(record.node):
					record.node.shape=record.shape;record.node.position=record.position
			for child in saved.children:
				if is_instance_valid(child): child.reparent(actor,false)
			if saved.has("camera") and is_instance_valid(saved.camera): saved.camera.near=saved.camera_near
			if is_instance_valid(_pivot): _pivot.queue_free()
		if relocate and is_inside_tree() and ground.is_inside_tree():
			# Same stable margin, clear of the entry detector and independent of relief.
			_place(Vector3(-3.25,1.015,-4.4))
		actor.velocity=Vector3.ZERO
	if is_instance_valid(_feel):
		for key in saved.feel: _feel.set(key,saved.feel[key])
		_feel.teleported()
	actor=null;_feel=null;_museum=null;saved.clear()

func _exit_tree() -> void:
	restore(false)
