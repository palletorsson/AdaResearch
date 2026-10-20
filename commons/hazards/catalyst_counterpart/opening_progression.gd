extends "res://commons/hazards/catalyst_counterpart/proving_ground.gd"
## A local rehearsal of the spine's beginning. Progress comes from performed actions.
## Uses the original point, trace recorder, field, hand ability and flying counterpart.
const Ability := preload("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd")
const Field := preload("res://commons/artifacts/drag_point_target/first_catalyst_field.gd")
const POINT_START := Vector3(-2.0, 1.18, 5.0)
const POINT_LATER := Vector3(-3.7, 1.18, -18.0)
var ability: Node3D
var acquisition: Node3D
var receiver: StaticBody3D
var power_unlocked := false
var joined := false
var form_studied := false
var receiver_reached := false
var completed_rounds := 0
var round_number := 1
var paused := false
var opening_status: Label3D
var form_status: Label3D
var round_lamps: Array[MeshInstance3D] = []
var original_ability: Node3D
var original_process := true
var original_visible := true

func _init() -> void:
	catalyst_script = "res://commons/hazards/catalyst_counterpart/progression_point.gd"

func _ready() -> void:
	super()
	name = "CatalystOpeningProgression"
	# Hide the persistent ability while rehearsing, without changing its unlock or save.
	var manager := get_node_or_null("/root/CatalystCapabilityManager")
	if manager != null:
		original_ability = manager.get("first_catalyst")
	if is_instance_valid(original_ability):
		original_process = original_ability.is_physics_processing()
		original_visible = original_ability.visible
		original_ability.set_physics_process(false)
		original_ability.hide()
	ability = Ability.new()
	add_child(ability)
	rod.charge_enabled = false
	field.hide()
	catalyst.add_to_group("ada_coordinate_point")
	catalyst.add_to_group("first_catalyst_seed")
	catalyst.set_meta("coordinate_id", "point_one_main")
	_set_point_home(POINT_START)
	_partition(0)
	_wall_text("01  A POINT BECOMES AN ABILITY", Vector3(-3.5, 2.8, 0.14), 29)
	_wall_text("Place the point in the hollow field.\nRelease it. Bring your empty hands together.\nA form appears; separate them to let it go.", Vector3(-3.5, 2.25, 0.14), 22)
	_plinth(Vector3(-2, 0.5, 5), Vector3(0.65, 1, 0.65))
	_label("TAKE THE POINT", Vector3(-2, 1.7, 5), 25, 0.0017)
	_make_acquisition()
	opening_status = _label("", Vector3(0, 2.25, 3.3), 27, 0.0018)
	_button("RESET WALK", Vector3(3.7, 1.1, 6.5), reset_trial)
	# The second empty podium receives the SAME body after the visitor keeps a line.
	receiver = load("res://commons/hazards/catalyst_counterpart/practice_receiver.gd").new()
	receiver.position = Vector3(-3.7, 1.65, -24.6)
	add_child(receiver)
	receiver.received.connect(_receiver_reached)
	form_status = _label("", Vector3(-3.7, 2.48, -18.6), 22, 0.0017)
	catalyst.readout = _label("", Vector3(-3.7, 1.61, -18.2), 23, 0.0015)
	_button("REST / RESUME", Vector3(2.8, 1.1, -18), toggle_rest)
	for i in range(3):
		var lamp := MeshInstance3D.new()
		var mesh := SphereMesh.new(); mesh.radius = 0.065; mesh.height = 0.13
		lamp.mesh = mesh; lamp.position = Vector3(-0.3 + i * 0.3, 2.28, -18.4)
		add_child(lamp); round_lamps.append(lamp)
	# Reword the supplied-power prototype's instructions for acquired progression.
	for label in find_children("*", "Label3D", true, false):
		if label.text == "01  GIVE A LINE TO THE AIR": label.text = "02  GIVE A LINE TO THE AIR"
		elif label.text == "02  SOMETHING IS WAITING": label.text = "03  KEEP A LINE. MEET A HEAD."
		elif label.text == "03  MAKE ROOM TO PASS": label.text = "04  A FORM LEARNS TO MOVE"
		elif label.text.begins_with("Take the point. Press BEGIN."):
			label.text = "Hold the point; watch its surface simplify.\nTrigger sends its form towards the ring.\nThen press BEGIN. One hit ends each round."
		elif label.text == "THE HEAD REMAINS. THE WAY OPENS.":
			label.text = "THE HEAD REMAINS. THE WAY OPENS.\nNext: one form becomes many."
	_refresh_status()

func _make_acquisition() -> void:
	if is_instance_valid(acquisition):
		acquisition.set_physics_process(false); acquisition.hide(); acquisition.queue_free()
	acquisition = Field.new()
	acquisition.capability_source = self
	acquisition.position = Vector3(2, 0, 5)
	add_child(acquisition)

func has_first_catalyst() -> bool:
	return power_unlocked

func unlock_first_catalyst() -> void:
	if power_unlocked: return
	power_unlocked = true
	ability.set_unlocked(true)

func _process(delta: float) -> void:
	super(delta)
	if not is_instance_valid(ability): return
	if ability.formed and not joined:
		joined = true
		rod.charge_enabled = true
		field.show()
	# The primitive lesson is encountered at its station, not during the first pickup.
	if not record.is_empty() and catalyst.is_resolution_held() and to_local(catalyst.global_position).z < -16:
		catalyst.resolution_enabled = true
	if not form_studied and catalyst.resolution_enabled and catalyst.is_resolution_held() and catalyst.sphere.rings == 1 and catalyst.sphere.radial_segments == 4:
		form_studied = true
		catalyst.emission_enabled = true
		receiver.enabled = true
	_refresh_status()

func keep_record(points: Array[Vector3]) -> void:
	if not joined or not record.is_empty() or points.size() < 2: return
	super(points)
	_set_point_home(POINT_LATER)

func _set_point_home(at: Vector3) -> void:
	catalyst.home = global_transform * Transform3D(Basis.IDENTITY, at)
	# A held point travels with its hand. A released one waits on the next plinth.
	if not catalyst.is_resolution_held():
		catalyst.return_home()
		catalyst._return_in = 0.08

func _wall_text(text: String, at: Vector3, size: int) -> void:
	# Room instructions should remain readable while approaching the plinths.
	var label := _label(text, at, roundi(size * 1.7), 0.0026)
	label.modulate = Color(0.06, 0.06, 0.06)
	label.outline_size = 0

func _receiver_reached() -> void:
	if form_studied: receiver_reached = true

func begin_encounter() -> void:
	if not receiver_reached or stage != Stage.REST or completed_rounds >= 3: return
	paused = false
	round_number = completed_rounds + 1
	skull.set_power(round_number)
	if round_number == 1:
		super()
	else:
		skull.position = Vector3(0, 1.65, -3.5)
		skull.set_active(true); skull.set_physics_process(true)
		stage = Stage.DEFEND

func _interrupted() -> void:
	if stage != Stage.DEFEND or paused: return
	completed_rounds += 1
	skull.active = false
	skull.set_physics_process(false)
	_clear_shots.call_deferred()
	if completed_rounds < 3:
		stage = Stage.REST
	else:
		super()
	_refresh_status()

func toggle_rest() -> void:
	if stage != Stage.DEFEND: return
	paused = not paused
	catalyst.emission_enabled = not paused
	skull.set_active(not paused)
	skull.set_physics_process(not paused)
	_clear_shots()
	_refresh_status()

func _clear_shots() -> void:
	for projectile in catalyst.projectiles:
		if is_instance_valid(projectile): projectile.queue_free()
	catalyst.projectiles.clear()

func reset_trial() -> void:
	super()
	power_unlocked = false; joined = false; form_studied = false; receiver_reached = false
	completed_rounds = 0; round_number = 1; paused = false
	ability.set_unlocked(false)
	rod.charge_enabled = false; field.hide()
	catalyst.resolution_enabled = false; catalyst.emission_enabled = false
	catalyst.reset_resolution()
	_set_point_home(POINT_START)
	receiver.reset_receiver()
	skull.set_power(1); skull.phase = 0; skull.visual.scale = Vector3.ONE; skull.boundary.radius = skull.RADIUS
	_make_acquisition()
	_refresh_status()

func _refresh_status() -> void:
	if not is_instance_valid(opening_status): return
	opening_status.text = "Place the point in the field." if not power_unlocked else ("Release the point. Join your empty hands." if not joined else "The ability follows you. Take the rod ahead.")
	form_status.text = "Keep a drawing first." if record.is_empty() else ("Hold: 16 rings / 32 segments\nbecome 1 ring / 4 segments." if not form_studied else ("Aim at the ring. Trigger sends a form." if not receiver_reached else "The receiver answered. Press BEGIN."))
	var text := "Acquire the hand ability in the first room."
	if joined: text = "Charge the rod; draw and release."
	if not record.is_empty(): text = "Your drawing is kept. Take the SAME point ahead."
	if form_studied: text = "Send a form to the quiet receiver first."
	if receiver_reached: text = "Press BEGIN for " + ["TRANSLATION", "+ ROTATION", "+ SCALE"][mini(completed_rounds, 2)]
	if stage == Stage.ARRIVING: text = "The waiting head becomes a moving body."
	if stage == Stage.DEFEND: text = ("RESTING — press REST / RESUME" if paused else ["TRANSLATION", "+ ROTATION", "+ SCALE"][round_number - 1] + " — sidestep its line or interrupt.")
	if stage == Stage.OPEN: text = "Three operations met. Walk through."
	if stage == Stage.COMPLETE: text = "An ability carried from making to defending. Next: arrays."
	readout.text = "%s\n%d kept positions  /  %d of 3 rounds  /  %d touches" % [text, record.size(), completed_rounds, skull.tags]
	for i in range(round_lamps.size()):
		var value := 0.9 if i < completed_rounds else 0.14
		var lamp := round_lamps[i]
		if lamp.material_override == null: lamp.material_override = _material(Color(value, value, value), 0.3)
		else: lamp.material_override.albedo_color = Color(value, value, value)

func _exit_tree() -> void:
	if is_instance_valid(original_ability):
		original_ability.set_physics_process(original_process)
		original_ability.visible = original_visible

static func mount_progression(hall: Node3D) -> Node3D:
	var walk := load("res://commons/hazards/catalyst_counterpart/opening_progression.gd").new() as Node3D
	# Add an 8 m acquisition room before the existing three-room route.
	var at := hall.to_global(Vector3(6.5, 0, 15.5))
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3, at + Vector3.DOWN * 5, 1)
	var hit := hall.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		walk.free(); push_error("Catalyst progression needs the museum floor"); return null
	at.y = hit.position.y
	walk.position = hall.to_local(at); walk.rotation.y = PI
	hall.add_child(walk)
	return walk
