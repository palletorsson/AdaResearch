extends "res://commons/void/growing_crossing.gd"
## Scale is also a ride: keep the material point beneath B through each change.
## The source growing crossing stays unchanged unless descent is explicitly enabled.
enum Phase { GROW_UPPER, UPPER_WAIT, BOARDING, SHRINK_UPPER, DESCEND, GROW_LOWER, LOWER_WAIT, SHRINK_LOWER, RETURN }
var descent_enabled := false
var phase := Phase.GROW_UPPER
var travel_metres := 9.0
var travel_speed := 1.0
var travel_scale := 1.8
var motion_y := 0.0
var carried_player: Node3D
var game: Node3D
var field: Node3D
var upper_floor := -1
var lower_floor := -1
var timer := 0.0
var preview := false
signal boarded
signal lower_docked
signal upper_restored

func enable_descent(owner_game: Node3D, cover: Node3D, settings: Dictionary) -> void:
	game=owner_game;field=cover
	travel_metres=clampf(float(settings.get("travel_metres",9)),.5,18)
	travel_speed=clampf(float(settings.get("speed",1)),.2,2)
	travel_scale=clampf(float(settings.get("travel_scale",1.8)),1.2,max_scale)
	var ancestor: Node=get_parent()
	while ancestor!=null:
		if ancestor.has_meta("void_content_floor"):
			upper_floor=int(ancestor.get_meta("void_content_floor"));break
		ancestor=ancestor.get_parent()
	lower_floor=upper_floor+1
	descent_enabled=true;phase=Phase.GROW_UPPER;timer=0;motion_y=0
	current_scale=min_scale;center_offset=Vector3.ZERO;apply_scale()
	process_physics_priority=-120
	add_to_group("void_controlled_carry")
	add_to_group("void_floor_extension")
	static_body.set_meta("void_floor_index",upper_floor)
	if is_instance_valid(field):field.set_enabled(true)

func _physics_process(delta: float) -> void:
	if not descent_enabled:
		super._physics_process(delta);return
	if preview:return
	if is_instance_valid(carried_player) and not supports_rider(carried_player):
		carried_player=null
	if not is_instance_valid(carried_player) and game!=null and phase in [Phase.SHRINK_UPPER,Phase.DESCEND,Phase.GROW_LOWER,Phase.LOWER_WAIT] and supports_rider(game.body):
		carried_player=game.body
		if phase==Phase.LOWER_WAIT:timer=2.0
	var old_scale: float=current_scale
	var old_y: float=motion_y
	match phase:
		Phase.GROW_UPPER:
			current_scale=move_toward(current_scale,max_scale,scale_speed*delta)
			if is_equal_approx(current_scale,max_scale):
				phase=Phase.UPPER_WAIT
				if is_instance_valid(field):field.set_enabled(true)
				upper_restored.emit()
		Phase.UPPER_WAIT:
			if game!=null and supports_rider(game.body):
				carried_player=game.body;phase=Phase.BOARDING;timer=1.0
				if is_instance_valid(field):field.set_enabled(false)
				boarded.emit()
		Phase.BOARDING:
			if not is_instance_valid(carried_player):
				phase=Phase.UPPER_WAIT
				if is_instance_valid(field):field.set_enabled(true)
			else:
				timer-=delta
				if timer<=0:phase=Phase.SHRINK_UPPER
		Phase.SHRINK_UPPER:
			current_scale=move_toward(current_scale,travel_scale,scale_speed*delta)
			if is_equal_approx(current_scale,travel_scale):phase=Phase.DESCEND
		Phase.DESCEND:
			motion_y=move_toward(motion_y,-travel_metres,travel_speed*delta)
			if is_equal_approx(motion_y,-travel_metres):phase=Phase.GROW_LOWER
		Phase.GROW_LOWER:
			current_scale=move_toward(current_scale,max_scale,scale_speed*delta)
			if is_equal_approx(current_scale,max_scale):
				phase=Phase.LOWER_WAIT;timer=2
				static_body.set_meta("void_floor_index",lower_floor)
				lower_docked.emit()
		Phase.LOWER_WAIT:
			if not is_instance_valid(carried_player):
				timer-=delta
				if timer<=0:phase=Phase.SHRINK_LOWER
		Phase.SHRINK_LOWER:
			current_scale=move_toward(current_scale,travel_scale,scale_speed*delta)
			if is_equal_approx(current_scale,travel_scale):phase=Phase.RETURN
		Phase.RETURN:
			motion_y=move_toward(motion_y,0,travel_speed*delta)
			if is_zero_approx(motion_y):
				phase=Phase.GROW_UPPER
				static_body.set_meta("void_floor_index",upper_floor)
	center_offset=Vector3(0,motion_y,0);apply_scale();static_body.force_update_transform()
	if is_instance_valid(carried_player):_carry(old_scale,old_y)

func supports_rider(rider: Node3D) -> bool:
	if rider==null or not rider is CharacterBody3D:return false
	var feet: Vector3=to_local(rider.global_position)
	var top: float=motion_y+current_scale*.5
	var rising: float=rider.velocity.y
	if rider is XRToolsPlayerBody:rising=(rider.velocity-rider.ground_velocity).dot(rider.up_player)
	return rising<=.3 and absf(feet.y-top)<.23 and absf(feet.x)<current_scale*.5+.08 and absf(feet.z)<current_scale*.5+.08

func _carry(old_scale: float,old_y: float) -> void:
	var rider: Node3D=carried_player
	var feet: Vector3=to_local(rider.global_position)
	var ratio: float=current_scale/maxf(old_scale,.01)
	var target := Vector3(feet.x*ratio,motion_y+current_scale*.5+(feet.y-old_y-old_scale*.5),feet.z*ratio)
	var movement: Vector3=to_global(target)-rider.global_position
	# Same XRTools transform/rebase contract as the existing museum transport.
	if rider is XRToolsPlayerBody:
		var pose: Transform3D=rider.global_transform;pose.origin+=movement;rider.teleport(pose)
		var ground: Node3D=rider.get("_previous_ground_node") as Node3D
		if ground==static_body:
			rider.velocity-=rider.ground_velocity;rider.ground_velocity=Vector3.ZERO
			rider.set("_previous_ground_global",ground.to_global(rider.get("_previous_ground_local")))
	else:rider.global_position+=movement

func _point_inside(at: Vector3) -> bool:
	return descent_enabled and phase!=Phase.LOWER_WAIT and is_instance_valid(carried_player) and supports_rider(carried_player) and at.distance_to(carried_player.global_position)<.5

func contains_visitor(at: Vector3) -> bool:
	# Hold the source hall live during the below-slab expansion. Once docked,
	# ordinary height streaming and the real lower-floor contact take over.
	return phase!=Phase.LOWER_WAIT and _point_inside(at)

func prepare_editor_preview() -> void:
	preview=true;current_scale=max_scale;motion_y=0;center_offset=Vector3.ZERO;apply_scale()
	if is_instance_valid(field):field.set_enabled(true)
