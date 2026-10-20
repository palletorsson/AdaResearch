extends Node
## Desktop practice input for both the biome ladder and the mature head arena.
## The shared ability still owns formation, cooldown, projectiles and damage.

var world: Node3D
var ability: Node3D
var camera: Camera3D
var pointer: Node
var readout: Label

func _ready() -> void:
	name = "DesktopCatalyst"
	camera = world.walker.camera
	pointer = world.walker.desktop_pointer
	ability = get_node("/root/CatalystCapabilityManager").first_catalyst
	ability.desktop_source = self
	var hud := CanvasLayer.new()
	hud.name = "DesktopControls"
	add_child(hud)
	world.walker.crosshair.reparent(hud)
	world.walker.crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.walker.crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	world.walker.crosshair.size = Vector2(4, 4)
	world.walker.crosshair.position -= Vector2(2, 2)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(20, -104)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.02, 0.8)
	style.content_margin_left = 14; style.content_margin_right = 14
	style.content_margin_top = 10; style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	hud.add_child(panel)
	readout = Label.new()
	readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	readout.add_theme_font_size_override("font_size", 16)
	panel.add_child(readout)

func _active() -> bool:
	return is_instance_valid(world.arena) and world._ready_for_play \
		and not world._returning and world.is_visible_in_tree() \
		and camera.current and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
		and not world.arena.player_dead and not world.walker._typing_elsewhere()

func _empty() -> bool:
	return not is_instance_valid(pointer.get("_held")) and not world.walker.voxel_edit_mode

func update_ability(source: Node3D, delta: float) -> void:
	# Keep the familiar point in the lower right of the view, clear of the reticle.
	var pose := camera.global_transform
	var left := Transform3D(pose.basis, pose * Vector3(0.07, -0.16, -0.48))
	var right := Transform3D(pose.basis, pose * Vector3(0.25, -0.16, -0.48))
	source.update_hands(left, right, _active(), _empty(), delta)

func _process(_delta: float) -> void:
	if not is_instance_valid(world.arena): return
	var state := "LIVE" if world.arena.running else "RESTING"
	var action := "Left click: shoot"
	if not _empty(): action = "Right click: release held object"
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: action = "Esc: return to aiming"
	if world.arena.player_dead: action = "Encounter ended"
	readout.text = "%s  ·  %s\nT: start / rest   ·   R: reset\nArrow keys: move   ·   Mouse: aim   ·   Esc: cursor" % [state, action]

func _unhandled_input(event: InputEvent) -> void:
	if not _active(): return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_T or event.keycode == KEY_T:
			if world.arena.running: world.arena.rest()
			else: world.arena.start_round()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_R or event.keycode == KEY_R:
			world.arena.reset_round()
			ability.clear_shots()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# The existing pointer gets first use of a click: buttons, handles and held
		# tools keep their own actions. Empty-hand firing is the remaining action.
		if not _empty() or pointer.has_hover_target() or pointer.is_dragging(): return
		if is_instance_valid(world.walker.current_interactable): return
		if not ability.formed: return
		var start := camera.global_position
		var target := start - camera.global_basis.z * 50.0
		var query := PhysicsRayQueryParameters3D.create(start, target, 1 | 2)
		query.exclude = [world.walker.get_rid()]
		var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty(): target = hit.position
		var direction: Vector3 = ability.sphere.global_position.direction_to(target)
		# A muzzle offset must not put a shot through nearby cover.
		query.to = ability.sphere.global_position + direction * 0.18
		query.collision_mask = 1
		if camera.get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			ability.send_form(direction)
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if is_instance_valid(ability) and ability.desktop_source == self:
		ability.desktop_source = null
		ability._hide_all()
