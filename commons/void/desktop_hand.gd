extends "res://commons/scenes/em/em_desktop_pointer.gd"
## Mouse hand for the same museum objects and earned catalyst used by the XR rig.
const Rules := preload("player_rules.gd")
const Pull := preload("force_pull.gd")
var world: Node3D
var ability: Node3D
var enabled := true
var hands_together := false
var grip: Node3D
var shared_grab := false
var _reenable_on_enter := false
var _restore_ability_source := false

class MouseGrip extends Node3D:
	# XRTools also supports non-controller grabbers (for example snap zones).
	var picked_up_ranged := false

func _ready() -> void:
	distance = Rules.POINTER_DISTANCE
	collision_mask_value = Rules.POINTER_MASK
	super()
	grip = MouseGrip.new()
	grip.name = "MouseGrip"
	cam.add_child(grip)

func _find_grabbable() -> Node3D:
	# A pointer's longer reach does not increase the pickup range.
	distance = Rules.GRAB_DISTANCE
	var point := super()
	distance = Rules.POINTER_DISTANCE
	return point if point!=null and Pull.reachable(cam,point) else null

func _physics_process(_delta: float) -> void:
	if shared_grab:
		if not is_instance_valid(_held) or not _held.is_picked_up():
			_held = null
			shared_grab = false
		else:
			grip.position = Vector3(0, 0, -_hold_distance)

func _grab_held(point: Node3D) -> void:
	if not Pull.reachable(cam,point):return
	if not (point is XRToolsPickable):
		super(point)
		return
	if not point.can_pick_up(grip) or point.get_meta("force_constraint_body", false): return
	var ranged := cam.global_position.distance_to(point.global_position)>1.05
	if ranged and not point.can_ranged_grab:return
	_hold_distance = 1.0
	grip.global_transform = point.global_transform
	grip.picked_up_ranged = ranged
	var method: int = point.ranged_grab_method;var speed: float = point.ranged_grab_speed
	if ranged:
		grip.global_position = cam.to_global(Vector3(0,0,-_hold_distance))
		point.ranged_grab_method = XRToolsPickable.RangedMethod.LERP;point.ranged_grab_speed = Rules.PULL_SPEED
	point.pick_up(grip)
	if not is_instance_valid(point) or point.is_queued_for_deletion():return
	point.ranged_grab_method = method;point.ranged_grab_speed = speed
	if point.is_picked_up():
		_held = point
		shared_grab = true
		if ranged:Pull.begin(grip,point)
		# These original museum thrusters resolve their receiver through the
		# desktop pointer or an XR controller. MouseGrip is not a controller.
		if point.is_in_group("ada_thrust_points"): point.on_desktop_grab(self)

func _drop_held() -> void:
	if not shared_grab:
		super()
		return
	_try_held_action(false)
	if is_instance_valid(_held) and _held.is_in_group("ada_thrust_points"):
		_held.on_desktop_drop(self)
	if is_instance_valid(_held): _held.let_go(grip, Vector3.ZERO, Vector3.ZERO)
	_held = null
	shared_grab = false

func _active() -> bool:
	return enabled and is_instance_valid(world) and world.ready_for_play \
		and not world.recovering and not world.returning and cam.current \
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if not enabled: return
	if event is InputEventKey:
		if event.keycode == KEY_C or event.physical_keycode == KEY_C:
			if is_instance_valid(world) and world.throwable_tools: return
			hands_together = event.pressed and _active()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE: hands_together = false
	if not _active(): return
	if event is InputEventKey and event.pressed and not event.echo and shared_grab and is_instance_valid(_held) and _held.get_meta("desktop_preserve_orientation",false):
		var axis := Vector3.ZERO
		match event.physical_keycode:
			KEY_Q:axis = Vector3.FORWARD
			KEY_E:axis = Vector3.BACK
			KEY_R:axis = Vector3.RIGHT
			KEY_F:axis = Vector3.LEFT
		if axis!=Vector3.ZERO:
			grip.rotate_object_local(axis,PI/12);get_viewport().set_input_as_handled();return
	super(event)

func _process(delta: float) -> void:
	if not enabled: return
	# XRTools' grab driver owns carried transforms; the inherited pointer still
	# owns hover, click and drag delivery. Never run two position drivers.
	var carried: Node3D = _held if is_instance_valid(_held) else null
	if shared_grab: _held = null
	super(delta)
	if shared_grab: _held = carried

func _unhandled_input(event: InputEvent) -> void:
	# Buttons, drags and held tools receive their trigger before empty-hand fire.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if try_fire() != null: get_viewport().set_input_as_handled()

func update_ability(source: Node3D, delta: float) -> void:
	var pose := cam.global_transform
	var spread := 0.08 if hands_together else 0.3
	var left := Transform3D(pose.basis, pose * Vector3(-spread, -0.16, -0.48))
	var right := Transform3D(pose.basis, pose * Vector3(spread, -0.16, -0.48))
	source.update_hands(left, right, _active(), not is_instance_valid(_held), delta)

func try_fire() -> RigidBody3D:
	if not _active() or not hands_together or not is_instance_valid(ability): return null
	if is_instance_valid(_held) or has_hover_target() or is_dragging() or not ability.formed: return null
	var start := cam.global_position
	var target := start - cam.global_basis.z * 50.0
	var query := PhysicsRayQueryParameters3D.create(start, target, 1 | 2)
	query.exclude = [world.body.get_rid()]
	var space := cam.get_world_3d().direct_space_state
	var hit := space.intersect_ray(query)
	if not hit.is_empty(): target = hit.position
	var direction: Vector3 = ability.sphere.global_position.direction_to(target)
	# The offset hand may not place the muzzle through a nearby wall.
	query.to = ability.sphere.global_position + direction * 0.18
	query.collision_mask = 1
	if not space.intersect_ray(query).is_empty(): return null
	return ability.send_form(direction)

func set_enabled(value: bool) -> void:
	if not value:
		hands_together = false
		_try_held_action(false)
		if is_instance_valid(_locked_target):
			XRToolsPointerEvent.released(self, _locked_target, _last_position)
		_locked_target = null
		_is_pressed = false
		if is_instance_valid(_last_target):
			XRToolsPointerEvent.exited(self, _last_target, _last_position)
		_last_target = null
		# Release every carried tool before disabling the hand during recovery.
		while is_instance_valid(_held): _drop_held()
	enabled = value

# Scale portals transiently reparent this hand. Preserve its enabled state,
# while an explicitly disabled recovery hand remains disabled on re-entry.
func _enter_tree() -> void:
	if _reenable_on_enter:
		_reenable_on_enter = false
		set_enabled(true)
	if _restore_ability_source and is_instance_valid(ability):
		ability.desktop_source = self
	_restore_ability_source = false

func _exit_tree() -> void:
	_reenable_on_enter = enabled
	_restore_ability_source = is_instance_valid(ability) and ability.desktop_source == self
	set_enabled(false)
	if is_instance_valid(ability) and ability.desktop_source == self:
		ability.desktop_source = null
		ability._hide_all()
